import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../core/utils/logger.dart';

class VoiceService {
  static final SpeechToText _speech = SpeechToText();
  static final FlutterTts _tts = FlutterTts();

  static Future<void> init() async {
    await _speech.initialize(
      onError: (val) => appLogger.e('[VoiceService] Error: $val'),
      onStatus: (val) => appLogger.d('[VoiceService] Status: $val'),
    );
    await _tts.setLanguage('en-US');
    await _tts.setPitch(1.0);
  }

  static Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  static Future<bool> listen({
    required Function(String) onResult,
    required Function(bool) onListeningChanged,
  }) async {
    try {
      bool available = await _speech.initialize(
        onError: (e) {
          appLogger.e('[VoiceService] Listen Error: $e');
          onListeningChanged(false);
        },
      );

      if (available) {
        onListeningChanged(true);
        _speech.listen(
          onResult: (val) {
            if (val.finalResult) {
              onResult(val.recognizedWords);
              onListeningChanged(false);
            }
          },
        );
        return true;
      } else {
        appLogger.w('[VoiceService] Speech recognition not available');
        onListeningChanged(false);
        return false;
      }
    } catch (e) {
      appLogger.e('[VoiceService] Critical failure during listen: $e');
      onListeningChanged(false);
      return false;
    }
  }

  static Future<void> stop() async {
    await _speech.stop();
  }

  /// Handles intents launched from Siri Shortcuts or Google Assistant deep links
  static Future<void> handleVoiceIntent(String intent, {required Function(String) onCommandReceived}) async {
    appLogger.i('[VoiceService] Received OS voice intent: $intent');
    
    // Simulate natural language parsing of the intent
    if (intent.toLowerCase().contains("log") || intent.toLowerCase().contains("take")) {
      onCommandReceived("Log my medication");
    } else if (intent.toLowerCase().contains("schedule") || intent.toLowerCase().contains("what")) {
      onCommandReceived("What is my schedule today?");
    } else {
      onCommandReceived(intent); // Pass raw for Gemini processing
    }
  }
}
