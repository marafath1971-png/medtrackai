import 'package:flutter_test/flutter_test.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:medai/domain/entities/entities.dart';
import 'package:medai/services/gemini_service.dart';
import 'package:medai/services/gemini_transport.dart';

/// Which path an AI request takes — the Cloud Function proxy or the Gemini SDK
/// directly — was decided by FirebaseAuth state and a dotenv key, so it could
/// never be exercised in a test. Sending a scan image down the wrong path means
/// either a rejected request or an API key used where the proxy was intended.
class RecordingTransport implements GeminiTransport {
  RecordingTransport({this.response = '{"name":"Proxy result"}'});
  String response;
  int proxyCalls = 0;

  @override
  Future<String> callProxy({
    required String prompt,
    required String model,
    bool isImage = false,
    String? imageBase64,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    proxyCalls++;
    return response;
  }

  @override
  Future<String> callProxyRaw(
    Map<String, dynamic> params, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    proxyCalls++;
    return response;
  }
}

class RecordingModel implements GeminiModel {
  RecordingModel({this.text = '{"name":"Direct result"}'});
  String text;
  int generateCalls = 0;

  @override
  Future<GeminiModelResponse> generateContent(Iterable<Content> parts) async {
    generateCalls++;
    return GeminiModelResponse(text);
  }
}

void main() {
  late RecordingTransport transport;
  late RecordingModel model;

  setUp(() {
    transport = RecordingTransport();
    model = RecordingModel();
    debugSetGeminiTransport(transport);
    debugSetGeminiModelFactory((n,
            {String apiVersion = 'v1',
            GenerationConfig? generationConfig,
            String apiKey = ''}) =>
        model);
  });

  tearDown(() {
    debugSetGeminiTransport(null);
    debugSetGeminiModelFactory(null);
    debugSetGeminiEnvironment(null);
  });

  group('environment seam', () {
    test('a fake environment replaces the live sources', () {
      debugSetGeminiEnvironment(
          const FakeGeminiEnvironment(isLoggedIn: true, apiKey: 'k'));

      expect(geminiEnvironment!.isLoggedIn, isTrue);
      expect(geminiEnvironment!.apiKey, 'k');
    });

    test('clearing it lets the live environment be rebuilt', () {
      debugSetGeminiEnvironment(
          const FakeGeminiEnvironment(isLoggedIn: true, apiKey: 'k'));
      debugSetGeminiEnvironment(null);

      expect(geminiEnvironment, isNull,
          reason: 'the service rebuilds the live one lazily on next use');
    });

    test('defaults are the safe ones: logged out, no key', () {
      const env = FakeGeminiEnvironment();
      expect(env.isLoggedIn, isFalse);
      expect(env.apiKey, isEmpty);
    });
  });

  group('branch selection', () {
    test('logged in with no key routes through the proxy', () async {
      debugSetGeminiEnvironment(
          const FakeGeminiEnvironment(isLoggedIn: true, apiKey: ''));

      await GeminiService.analyzeProductInsight('vitamin d');

      expect(transport.proxyCalls, greaterThan(0),
          reason: 'no local key means the request must go via the proxy');
      expect(model.generateCalls, 0,
          reason: 'the SDK must not be called without a key');
    });

    test('a key present routes directly to the SDK', () async {
      debugSetGeminiEnvironment(
          const FakeGeminiEnvironment(isLoggedIn: true, apiKey: 'test-key'));

      await GeminiService.analyzeProductInsight('vitamin d');

      expect(model.generateCalls, greaterThan(0),
          reason: 'a local key means the direct SDK path');
      expect(transport.proxyCalls, 0,
          reason: 'the proxy is for keyless clients');
    });

    test('logged out with no key uses neither path', () async {
      debugSetGeminiEnvironment(
          const FakeGeminiEnvironment(isLoggedIn: false, apiKey: ''));

      await GeminiService.analyzeProductInsight('vitamin d');

      expect(transport.proxyCalls, 0);
      expect(model.generateCalls, 0,
          reason: 'with no auth and no key there is nothing to call');
    });
  });

  group('checkInteractions reaches the SDK once a key exists', () {
    Medicine med(String name) => Medicine(
          id: name.hashCode,
          name: name,
          courseStartDate: '2026-08-16T09:00:00.000',
        );

    test('was previously unreachable without a real key', () async {
      debugSetGeminiEnvironment(
          const FakeGeminiEnvironment(isLoggedIn: true, apiKey: 'test-key'));
      model.text = 'Avoid taking these together.';

      final result = await GeminiService.checkInteractions(
        newMed: med('Aspirin'),
        existingMeds: [med('Warfarin')],
      );

      expect(model.generateCalls, greaterThan(0));
      expect(result, 'Avoid taking these together.');
    });

    test('a SAFE verdict is normalised to null', () async {
      debugSetGeminiEnvironment(
          const FakeGeminiEnvironment(isLoggedIn: true, apiKey: 'test-key'));
      model.text = 'SAFE';

      final result = await GeminiService.checkInteractions(
        newMed: med('Aspirin'),
        existingMeds: [med('Paracetamol')],
      );

      expect(result, isNull,
          reason: 'callers treat null as "nothing to warn about"');
    });

    test('an empty medicine list short-circuits before any call', () async {
      debugSetGeminiEnvironment(
          const FakeGeminiEnvironment(isLoggedIn: true, apiKey: 'test-key'));

      final result = await GeminiService.checkInteractions(
        newMed: med('Aspirin'),
        existingMeds: const [],
      );

      expect(result, isNull);
      expect(model.generateCalls, 0);
    });
  });
}
