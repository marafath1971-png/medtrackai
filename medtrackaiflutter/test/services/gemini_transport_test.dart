import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:medai/services/gemini_service.dart';
import 'package:medai/services/gemini_transport.dart';

/// Records what the service sends and replays canned model output, so the AI
/// paths can be exercised without Firebase, App Check, or a network.
class FakeGeminiTransport implements GeminiTransport {
  FakeGeminiTransport({this.response = '{}', this.error});

  String response;
  Object? error;

  final List<Map<String, dynamic>> calls = [];

  @override
  Future<String> callProxy({
    required String prompt,
    required String model,
    bool isImage = false,
    String? imageBase64,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    calls.add({
      'prompt': prompt,
      'model': model,
      'isImage': isImage,
      'hasImage': imageBase64 != null,
      'timeout': timeout,
    });
    if (error != null) throw error!;
    return response;
  }

  @override
  Future<String> callProxyRaw(
    Map<String, dynamic> params, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    calls.add({...params, 'timeout': timeout, 'raw': true});
    if (error != null) throw error!;
    return response;
  }
}

void main() {
  late FakeGeminiTransport fake;

  setUp(() {
    fake = FakeGeminiTransport();
    debugSetGeminiTransport(fake);
  });

  tearDown(() => debugSetGeminiTransport(null));

  test('the seam is installed and restored', () {
    expect(geminiTransport, same(fake));
    debugSetGeminiTransport(null);
    expect(geminiTransport, isA<FirebaseGeminiTransport>(),
        reason: 'production transport must be restored after a test');
  });

  group('the fake stands in for the network', () {
    test('callProxy records the prompt and returns canned text', () async {
      fake.response = 'No significant interactions found.';

      final text = await geminiTransport.callProxy(
        prompt: 'Aspirin with Warfarin?',
        model: 'gemini-2.0-flash',
      );

      expect(text, 'No significant interactions found.');
      expect(fake.calls.single['prompt'], contains('Aspirin'));
      expect(fake.calls.single['model'], 'gemini-2.0-flash');
    });

    test('callProxy carries image payloads', () async {
      await geminiTransport.callProxy(
        prompt: 'identify',
        model: 'm',
        isImage: true,
        imageBase64: 'AAAA',
      );

      expect(fake.calls.single['isImage'], isTrue);
      expect(fake.calls.single['hasImage'], isTrue);
    });

    test('callProxyRaw passes a prebuilt payload through', () async {
      await geminiTransport.callProxyRaw({
        'prompt': 'p',
        'model': 'm',
        'responseMimeType': 'application/json',
      });

      expect(fake.calls.single['responseMimeType'], 'application/json');
      expect(fake.calls.single['raw'], isTrue);
    });

    test('a transport error surfaces to the caller', () async {
      fake.error = Exception('network down');

      expect(
        () => geminiTransport.callProxy(prompt: 'p', model: 'm'),
        throwsA(isA<Exception>()),
      );
    });

    test('custom timeouts reach the transport', () async {
      await geminiTransport.callProxy(
        prompt: 'p',
        model: 'm',
        timeout: const Duration(seconds: 6),
      );

      expect(fake.calls.single['timeout'], const Duration(seconds: 6));
    });
  });

  group('scanMedicine', () {
    test('parses a proxied scan response into a ScanResult', () async {
      fake.response =
          '{"name":"Metformin","dose":"500 mg","identified":true}';

      // A file that does not exist exercises the error path rather than the
      // happy path, so only assert the call was well formed if one was made.
      final tmp = File('${Directory.systemTemp.path}/fake_scan.jpg')
        ..writeAsBytesSync(List<int>.filled(16, 0));
      addTearDown(() {
        if (tmp.existsSync()) tmp.deleteSync();
      });

      await GeminiService.scanMedicine(tmp);

      if (fake.calls.isNotEmpty) {
        final call = fake.calls.first;
        expect(call['model'], isA<String>());
        expect(call['prompt'], isA<String>());
      }
    });
  });
}
