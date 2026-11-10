import 'package:flutter_test/flutter_test.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:medai/domain/entities/entities.dart';
import 'package:medai/services/gemini_service.dart';
import 'package:medai/services/gemini_transport.dart';

/// Three clinical helpers — the drug-interaction check, missed-dose advice and
/// the AI coach — called the Gemini SDK directly and never the proxy. Release
/// builds carry no API key, so in production those calls could only throw.
///
/// The interaction check then caught that throw and returned null, which is
/// also what it returns for "no interaction found". A drug-interaction warning
/// that cannot run looked exactly like one that ran clean.
class FailingTransport implements GeminiTransport {
  int calls = 0;

  @override
  Future<String> callProxy({
    required String prompt,
    required String model,
    bool isImage = false,
    String? imageBase64,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    calls++;
    throw Exception('proxy unreachable');
  }

  @override
  Future<String> callProxyRaw(Map<String, dynamic> params,
      {Duration timeout = const Duration(seconds: 30)}) async {
    calls++;
    throw Exception('proxy unreachable');
  }
}

class StubTransport implements GeminiTransport {
  StubTransport(this.response);
  final String response;
  int calls = 0;
  String? lastModel;

  @override
  Future<String> callProxy({
    required String prompt,
    required String model,
    bool isImage = false,
    String? imageBase64,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    calls++;
    lastModel = model;
    return response;
  }

  @override
  Future<String> callProxyRaw(Map<String, dynamic> params,
      {Duration timeout = const Duration(seconds: 30)}) async {
    calls++;
    lastModel = params['model'] as String?;
    return response;
  }
}

/// A model that must never be reached when the user is signed in.
class ExplodingModel implements GeminiModel {
  int calls = 0;

  @override
  Future<GeminiModelResponse> generateContent(Iterable<Content> parts) async {
    calls++;
    throw StateError('direct SDK must not be used when signed in');
  }
}

Medicine _med(String name) => Medicine(
      id: name.hashCode,
      name: name,
      dose: '10mg',
      courseStartDate: DateTime.now().toIso8601String(),
    );

void main() {
  late ExplodingModel model;

  setUp(() {
    model = ExplodingModel();
    debugSetGeminiModelFactory((n,
            {String apiVersion = 'v1',
            GenerationConfig? generationConfig,
            String apiKey = ''}) =>
        model);
    // Signed in, no API key — exactly what a release build looks like.
    debugSetGeminiEnvironment(
        const FakeGeminiEnvironment(isLoggedIn: true, apiKey: ''));
  });

  tearDown(() {
    debugSetGeminiTransport(null);
    debugSetGeminiModelFactory(null);
    debugSetGeminiEnvironment(null);
  });

  group('checkInteractions', () {
    test('goes through the proxy rather than the direct SDK', () async {
      final transport = StubTransport('SAFE');
      debugSetGeminiTransport(transport);

      await GeminiService.checkInteractions(
        newMed: _med('Warfarin'),
        existingMeds: [_med('Aspirin')],
      );

      expect(transport.calls, 1,
          reason: 'the check must use the proxy; the direct SDK has no key in '
              'release, so it could only ever throw');
      expect(model.calls, 0);
    });

    test('asks for the model the rest of the app uses', () async {
      final transport = StubTransport('SAFE');
      debugSetGeminiTransport(transport);

      await GeminiService.checkInteractions(
        newMed: _med('Warfarin'),
        existingMeds: [_med('Aspirin')],
      );

      expect(transport.lastModel, 'gemini-2.5-flash',
          reason: 'this called gemini-1.5-flash, two generations behind');
    });

    test('a clean check returns null', () async {
      debugSetGeminiTransport(StubTransport('SAFE'));

      expect(
          await GeminiService.checkInteractions(
            newMed: _med('Paracetamol'),
            existingMeds: [_med('Vitamin C')],
          ),
          isNull);
    });

    test('a real interaction comes back as a warning', () async {
      debugSetGeminiTransport(StubTransport(
          '⚠️ Warfarin + Aspirin: bleeding risk. Consult your doctor.'));

      final result = await GeminiService.checkInteractions(
        newMed: _med('Warfarin'),
        existingMeds: [_med('Aspirin')],
      );

      expect(result, contains('Warfarin'));
      expect(result, contains('bleeding'));
    });

    test('a check that could not run throws instead of reporting safe',
        () async {
      debugSetGeminiTransport(FailingTransport());

      // The regression: this used to return null, indistinguishable from
      // "no interaction found" on a safety warning.
      expect(
          () => GeminiService.checkInteractions(
                newMed: _med('Warfarin'),
                existingMeds: [_med('Aspirin')],
              ),
          throwsA(isA<Object>()),
          reason: 'silence must not be presented to the user as safety');
    });

    test('no existing medicines is answered without a network call', () async {
      final transport = StubTransport('SAFE');
      debugSetGeminiTransport(transport);

      expect(
          await GeminiService.checkInteractions(
            newMed: _med('Warfarin'),
            existingMeds: const [],
          ),
          isNull);
      expect(transport.calls, 0);
    });
  });

  group('getMissedDoseAdvice', () {
    test('uses the proxy and reports advice as AI-generated', () async {
      final transport =
          StubTransport('Take it now, you are only an hour late.');
      debugSetGeminiTransport(transport);

      final advice = await GeminiService.getMissedDoseAdvice(
        med: _med('Amoxicillin'),
        minutesMissedBy: 60,
        nextDoseInMinutes: 300,
      );

      expect(transport.calls, 1);
      expect(advice.isAiGenerated, isTrue);
      expect(advice.text, contains('Take it now'));
    });

    test('falls back to static rules, and says so', () async {
      debugSetGeminiTransport(FailingTransport());

      final advice = await GeminiService.getMissedDoseAdvice(
        med: _med('Amoxicillin'),
        minutesMissedBy: 60,
        nextDoseInMinutes: 300,
      );

      // Degrading is fine here — the static text is sound advice. Claiming the
      // AI wrote it is not.
      expect(advice.text, isNotEmpty);
      expect(advice.isAiGenerated, isFalse,
          reason: 'the card labels this "AI ADVICE"; generic rules must not '
              'render under that label');
    });
  });

  group('askFollowUp', () {
    test('uses the proxy', () async {
      final transport = StubTransport('Take it with food.');
      debugSetGeminiTransport(transport);

      await GeminiService.askFollowUp('Can I take this with milk?', const []);

      expect(transport.calls, 1);
      expect(model.calls, 0);
    });

    test('surfaces a failure as an error result', () async {
      debugSetGeminiTransport(FailingTransport());

      final result = await GeminiService.askFollowUp(
          'Can I take this with milk?', const []);

      expect(result.isFailure, isTrue,
          reason: 'the coach must say it failed rather than showing nothing');
    });
  });

  group('analyzeMedicineSafety', () {
    test('uses the proxy and parses safety profile JSON', () async {
      final jsonResponse = '''
{
  "warnings": ["Avoid in pregnancy"],
  "interactions": ["Interacts with NSAIDs"],
  "foodRules": ["Take with food"],
  "ahaMoments": ["Reduces cardiovascular events by 25%"],
  "mechanismOfAction": "ACE inhibitor",
  "onsetMinutes": 30,
  "peakHours": 2.0,
  "durationHours": 24.0,
  "bodySystems": ["cardiovascular"],
  "timelineEffects": [{"time": "2h", "effect": "Peak absorption"}],
  "ahaFacts": ["Discovered in 1975"]
}
''';
      final transport = StubTransport(jsonResponse);
      debugSetGeminiTransport(transport);

      final result =
          await GeminiService.analyzeMedicineSafety(_med('Lisinopril'));

      expect(transport.calls, 1);
      expect(model.calls, 0);
      expect(result.isSuccess, isTrue);
      expect(result.data.warnings, contains('Avoid in pregnancy'));
      expect(result.data.mechanismOfAction, 'ACE inhibitor');
    });

    test('surfaces a failure when proxy fails', () async {
      debugSetGeminiTransport(FailingTransport());

      final result =
          await GeminiService.analyzeMedicineSafety(_med('Lisinopril'));

      expect(result.isFailure, isTrue);
      expect(model.calls, 0);
    });
  });

  group('analyzeSymptom', () {
    test('uses the proxy and parses symptom analysis JSON', () async {
      final jsonResponse = '''
{
  "description": "Mild headache reported. Stay hydrated and monitor.",
  "steps": ["Drink water", "Rest in a quiet room"],
  "warning": "Consult a doctor if pain worsens."
}
''';
      final transport = StubTransport(jsonResponse);
      debugSetGeminiTransport(transport);

      final symptom = Symptom(
        id: 's1',
        name: 'Headache',
        severity: 4,
        timestamp: DateTime.now(),
      );

      final result = await GeminiService.analyzeSymptom(
        symptom,
        [_med('Aspirin')],
      );

      expect(transport.calls, 1);
      expect(model.calls, 0);
      expect(result.isSuccess, isTrue);
      expect(result.data.steps, contains('Drink water'));
    });

    test('gracefully degrades to safe guidance on failure', () async {
      debugSetGeminiTransport(FailingTransport());

      final symptom = Symptom(
        id: 's2',
        name: 'Fatigue',
        severity: 3,
        timestamp: DateTime.now(),
      );

      final result = await GeminiService.analyzeSymptom(
        symptom,
        [_med('Lisinopril')],
      );

      expect(result.isSuccess, isTrue);
      expect(result.data.description, contains('Logged successfully'));
      expect(model.calls, 0);
    });
  });

  group('parseVoiceCommand', () {
    test('uses the proxy and parses command JSON', () async {
      final jsonResponse = '''
{
  "identified": true,
  "action": "take",
  "medId": 123,
  "confirmationText": "Logged your Advil!"
}
''';
      final transport = StubTransport(jsonResponse);
      debugSetGeminiTransport(transport);

      final result = await GeminiService.parseVoiceCommand(
        transcript: 'I took my Advil',
        meds: [_med('Advil')],
      );

      expect(transport.calls, 1);
      expect(model.calls, 0);
      expect(result.isSuccess, isTrue);
      expect(result.data['action'], 'take');
    });

    test('returns failure when proxy is unreachable', () async {
      debugSetGeminiTransport(FailingTransport());

      final result = await GeminiService.parseVoiceCommand(
        transcript: 'Take pill',
        meds: [_med('Advil')],
      );

      expect(result.isFailure, isTrue);
      expect(model.calls, 0);
    });
  });

  group('chatWithProduct', () {
    test('uses the proxy', () async {
      final transport =
          StubTransport('Lisinopril is safe with moderate coffee intake.');
      debugSetGeminiTransport(transport);

      final result = await GeminiService.chatWithProduct(
        productName: 'Lisinopril',
        productDetails: 'Blood pressure medication',
        query: 'Can I drink coffee with this?',
        chatHistory: const [],
      );

      expect(transport.calls, 1);
      expect(model.calls, 0);
      expect(result.isSuccess, isTrue);
      expect(result.data, contains('safe with moderate coffee'));
    });

    test(
        'returns error and does not return fake canned advice when proxy fails',
        () async {
      debugSetGeminiTransport(FailingTransport());

      final result = await GeminiService.chatWithProduct(
        productName: 'Warfarin',
        productDetails: 'Blood thinner',
        query: 'Can I take aspirin?',
        chatHistory: const [],
      );

      expect(result.isFailure, isTrue);
      expect(model.calls, 0);
    });
  });
}
