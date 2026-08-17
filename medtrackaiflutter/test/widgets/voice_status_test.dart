import 'package:flutter_test/flutter_test.dart';
import 'package:medai/screens/scan/scanner_hub_screen.dart';

/// Voice search had no `onStatus` handler at all.
///
/// speech_to_text stops listening by itself once the speaker pauses. With
/// nothing wired to that, the mic closed but `_isListening` stayed true: the
/// screen kept showing its listening state, the transcript was never submitted,
/// and the user had to guess that a second tap was needed. Voice looked broken
/// even when recognition had worked perfectly.
///
/// There was no `onError` either, so a denied mic or a failed init fell off the
/// end of an `if (ok)` and the button did nothing at all — the same silent-catch
/// shape as the caregiver invite bug.
void main() {
  group('isSpeechFinished', () {
    test('done ends the session', () {
      // Emitted on Android when recognition completes normally.
      expect(ScannerHubScreen.isSpeechFinished('done'), isTrue);
    });

    test('notListening ends the session', () {
      // Emitted when the plugin times out on silence — the common real-world
      // case, and the one that left the UI stuck.
      expect(ScannerHubScreen.isSpeechFinished('notListening'), isTrue);
    });

    test('listening does not end the session', () {
      // Submitting here would cut the user off mid-sentence.
      expect(ScannerHubScreen.isSpeechFinished('listening'), isFalse);
    });

    test('an unknown status does not end the session', () {
      // Better to leave the mic open and let the user tap stop than to fire a
      // search on a status this code does not understand.
      expect(ScannerHubScreen.isSpeechFinished('someFutureStatus'), isFalse);
      expect(ScannerHubScreen.isSpeechFinished(''), isFalse);
    });

    test('the two terminal statuses are both handled', () {
      // Handling only 'done' still leaves the silence timeout stuck, which was
      // the actual failure. Guarding against a partial fix.
      final terminal = ['done', 'notListening']
          .where(ScannerHubScreen.isSpeechFinished)
          .length;

      expect(terminal, 2);
    });
  });
}
