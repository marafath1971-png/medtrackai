import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

/// The network boundary for [GeminiService].
///
/// Every AI request in the app ends up as "send a prompt, get text back", but
/// the calls were written inline against `FirebaseFunctions.instance`, so
/// nothing above them could be tested without a live backend. This is a seam,
/// not a rewrite: the service keeps its static API and its 16 call sites are
/// untouched, while tests can swap the transport for a fake.
abstract class GeminiTransport {
  /// Send [prompt] to the `geminiProxy` Cloud Function and return the model's
  /// raw text. [imageBase64] is set for scan requests.
  Future<String> callProxy({
    required String prompt,
    required String model,
    bool isImage = false,
    String? imageBase64,
    Duration timeout = const Duration(seconds: 30),
  });

  /// Escape hatch for the two callers that build their own payload — one
  /// assembles multipart image parts, the other sets responseMimeType.
  Future<String> callProxyRaw(
    Map<String, dynamic> params, {
    Duration timeout = const Duration(seconds: 30),
  });
}

class FirebaseGeminiTransport implements GeminiTransport {
  const FirebaseGeminiTransport();

  @override
  Future<String> callProxy({
    required String prompt,
    required String model,
    bool isImage = false,
    String? imageBase64,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final result =
        await FirebaseFunctions.instance.httpsCallable('geminiProxy').call({
      'prompt': prompt,
      'model': model,
      'isImage': isImage,
      if (imageBase64 != null) 'imageBase64': imageBase64,
    }).timeout(timeout);

    return result.data['text'] ?? '';
  }

  @override
  Future<String> callProxyRaw(
    Map<String, dynamic> params, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final result = await FirebaseFunctions.instance
        .httpsCallable('geminiProxy')
        .call(params)
        .timeout(timeout);
    return result.data['text'] ?? '';
  }
}

/// What [GeminiService] needs from a model: generate content, read the text.
///
/// The service's fourteen direct-SDK call sites all do
/// `_getModel(...).generateContent(parts)` then `response.text`, so this
/// mirrors that shape exactly. _getModel returns one of these instead of a
/// raw GenerativeModel, which leaves every call site untouched.
abstract class GeminiModel {
  Future<GeminiModelResponse> generateContent(Iterable<Content> parts);
}

class GeminiModelResponse {
  const GeminiModelResponse(this.text);
  final String? text;
}

class SdkGeminiModel implements GeminiModel {
  SdkGeminiModel(this._model);
  final GenerativeModel _model;

  @override
  Future<GeminiModelResponse> generateContent(Iterable<Content> parts) async {
    final r = await _model.generateContent(parts);
    return GeminiModelResponse(r.text);
  }
}

/// Builds the model for a given name. Swapped in tests so the direct-SDK
/// branch can be exercised without an API key or a network.
typedef GeminiModelFactory = GeminiModel Function(
  String modelName, {
  String apiVersion,
  GenerationConfig? generationConfig,
  String apiKey,
});

GeminiModel _defaultModelFactory(
  String modelName, {
  String apiVersion = 'v1',
  GenerationConfig? generationConfig,
  String apiKey = '',
}) =>
    SdkGeminiModel(GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      requestOptions: RequestOptions(apiVersion: apiVersion),
      generationConfig: generationConfig,
    ));

GeminiModelFactory geminiModelFactory = _defaultModelFactory;

@visibleForTesting
void debugSetGeminiModelFactory(GeminiModelFactory? f) {
  geminiModelFactory = f ?? _defaultModelFactory;
}

/// Swappable so tests can drive [GeminiService] without a backend.
///
/// Production never reassigns this; [debugSetGeminiTransport] is the only
/// writer and exists for tests.
GeminiTransport geminiTransport = const FirebaseGeminiTransport();

@visibleForTesting
void debugSetGeminiTransport(GeminiTransport? t) {
  geminiTransport = t ?? const FirebaseGeminiTransport();
}
