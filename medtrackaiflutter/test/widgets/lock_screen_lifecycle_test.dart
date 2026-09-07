import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// A call arriving during the unlock left the app stuck behind its own lock
/// screen for 25 seconds:
///
///   App backgrounded
///   BiometricPromptCompat: Unable to start authentication.
///     Called after onSaveInstanceState()
///   Biometric authentication timed out after 25s
///   Unable to cancel authentication. BiometricFragment not found
///
/// Android refuses to show the system prompt once the Activity is stopping,
/// so the request was never displayed — and the app then waited out the full
/// timeout for an answer to a dialog nobody saw.
void main() {
  late String lock;
  late String svc;

  setUpAll(() {
    lock = File('lib/screens/security/lock_screen.dart').readAsStringSync();
    svc = File('lib/services/biometric_service.dart').readAsStringSync();
  });

  group('the lock screen follows the app lifecycle', () {
    test('it observes lifecycle changes at all', () {
      expect(lock.contains('WidgetsBindingObserver'), isTrue);
      expect(lock.contains('didChangeAppLifecycleState'), isTrue);
      expect(lock.contains('WidgetsBinding.instance.addObserver(this)'), isTrue);
    });

    test('the observer is removed again', () {
      // A leaked observer keeps firing against a disposed State.
      expect(lock.contains('removeObserver(this)'), isTrue);
      expect(lock.contains('void dispose()'), isTrue);
    });

    test('backgrounding cancels the outstanding prompt', () {
      final i = lock.indexOf('didChangeAppLifecycleState');
      final body = lock.substring(i, lock.length.clamp(0, i + 1400));
      expect(body.contains('AppLifecycleState.paused'), isTrue);
      expect(body.contains('cancelAuthentication'), isTrue,
          reason: 'a prompt left in flight is what caused the 25s hang');
    });

    test('a late result cannot unlock after switching away', () {
      // _attempt is the generation counter the callback checks; bumping it on
      // background invalidates a result that arrives after the user left.
      final i = lock.indexOf('didChangeAppLifecycleState');
      final body = lock.substring(i, lock.length.clamp(0, i + 1400));
      expect(body.contains('_attempt++'), isTrue,
          reason: 'a stale success must not unlock the app later');
    });

    test('returning to the foreground re-offers the prompt', () {
      // Otherwise the user is left on a lock screen with no way forward.
      final i = lock.indexOf('didChangeAppLifecycleState');
      final body = lock.substring(i, lock.length.clamp(0, i + 1400));
      expect(body.contains('AppLifecycleState.resumed'), isTrue);
      expect(body.contains('_authenticate('), isTrue);
    });
  });

  group('the service refuses to double-prompt', () {
    test('a second request while one is showing is rejected', () {
      // The plugin answers auth_in_progress, and the lifecycle handler can now
      // re-request on resume, so the two can race.
      expect(svc.contains('_inFlight'), isTrue);
      final i = svc.indexOf('if (_inFlight)');
      expect(i, greaterThan(-1),
          reason: 'the guard must run before authenticate() is called');
      expect(svc.indexOf('_auth\n            .authenticate') > i ||
          svc.indexOf('.authenticate(') > i, isTrue);
    });

    test('the flag is always cleared', () {
      // A timeout or throw that leaks _inFlight would lock the user out
      // permanently — worse than the bug being fixed.
      expect(svc.contains('} finally {'), isTrue);
      final i = svc.indexOf('} finally {');
      expect(svc.substring(i, i + 80).contains('_inFlight = false'), isTrue);
    });
  });
}
