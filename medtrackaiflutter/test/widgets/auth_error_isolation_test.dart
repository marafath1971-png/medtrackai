import 'package:flutter_test/flutter_test.dart';
import 'package:medai/screens/auth/auth_screen.dart';

/// On a real Pixel, a fresh install could not get into the app at all:
/// Google sign-in failed with `clientConfigurationError, serverClientId must
/// be provided on Android` (google_sign_in 7.x needs it passed to
/// initialize(); it does not read google-services.json), and Email/Password
/// was disabled in the Firebase console. Both paths dead-ended.
///
/// The messages shown made that worse, and those are what this file pins.
void main() {
  group('google sign-in failures', () {
    // These strings are the real ones logged on a Pixel 7a, not invented.
    const cancelled =
        'GoogleSignInException(code GoogleSignInExceptionCode.canceled, '
        '[16] Cancelled by user., null)';
    const noServerClientId =
        'GoogleSignInException(code GoogleSignInExceptionCode.'
        'clientConfigurationError, serverClientId must be provided on '
        'Android, null)';
    const badCertificate =
        'GoogleSignInException(code GoogleSignInExceptionCode.unknownError, '
        '[28444] Developer console is not set up correctly., null)';

    test('backing out of the account picker says nothing at all', () {
      // Dismissing the picker is a decision, not an error. Reporting it as a
      // failure told the user something had gone wrong when nothing had.
      expect(AuthScreen.friendlyGoogleError(cancelled), isNull);
    });

    test('an unregistered signing certificate does not say "try again"', () {
      // 28444 means the app's SHA-1 is not registered in the Firebase project.
      // It fires *after* the user picks an account, so "try again" reads as
      // "your account was rejected" — and no retry can ever succeed.
      final message = AuthScreen.friendlyGoogleError(badCertificate);

      expect(message, isNotNull);
      expect(message!.toLowerCase(), isNot(contains('try again')));
      expect(message.toLowerCase(), contains('email'),
          reason: 'it should point at the method that does work');
    });

    test('a missing serverClientId is reported the same way', () {
      // Different cause, same user-facing truth: sign-in is not available and
      // retrying is pointless.
      expect(AuthScreen.friendlyGoogleError(noServerClientId),
          AuthScreen.friendlyGoogleError(badCertificate));
    });

    test('a network failure is distinguished from a broken setup', () {
      // This one genuinely is worth retrying, so it must not be folded in
      // with the configuration faults.
      final message = AuthScreen.friendlyGoogleError(
          'PlatformException(network_error, ...)');

      expect(message, isNotNull);
      expect(message!.toLowerCase(), contains('internet'));
    });

    test('an unrecognised failure still offers a retry', () {
      final message =
          AuthScreen.friendlyGoogleError('some unexpected plugin failure');

      expect(message, 'Google sign-in failed. Please try again.');
    });

    test('no message leaks a raw error code or exception text', () {
      for (final error in [noServerClientId, badCertificate]) {
        final message = AuthScreen.friendlyGoogleError(error)!;
        expect(message, isNot(contains('GoogleSignInException')));
        expect(message, isNot(contains('28444')));
        expect(message, isNot(contains('serverClientId')));
      }
    });
  });

  group('auth error copy tells the user what to do', () {
    test('a server misconfiguration does not blame the user or say "retry"',
        () {
      // Observed on device as "This sign-in method is not enabled." — which
      // describes a console setting the user cannot see, let alone change,
      // and offers them nothing to do next.
      final message = AuthScreen.friendlyAuthError('operation-not-allowed');

      expect(message, isNot(contains('not enabled')));
      expect(message.toLowerCase(), contains('try another method'));
    });

    test('a rate limit tells the user to wait rather than retry', () {
      // Retrying immediately makes this one strictly worse.
      final message = AuthScreen.friendlyAuthError('too-many-requests');

      expect(message.toLowerCase(), contains('wait'));
    });

    test('a disabled account points at support, since retrying cannot work',
        () {
      final message = AuthScreen.friendlyAuthError('user-disabled');

      expect(message.toLowerCase(), contains('support'));
      expect(message.toLowerCase(), isNot(contains('try again')));
    });

    test('a bad password is named, not reported as "something went wrong"', () {
      // Modern Firebase returns invalid-credential for a wrong password, so
      // this is the most common sign-in failure there is.
      for (final code in ['wrong-password', 'invalid-credential']) {
        expect(
            AuthScreen.friendlyAuthError(code), 'Incorrect email or password',
            reason: '$code is a wrong password');
      }
    });

    test('an unknown code still produces something actionable', () {
      final message = AuthScreen.friendlyAuthError('some-future-code');

      expect(message, isNotEmpty);
      expect(message.toLowerCase(), contains('try again'));
    });

    test('no message leaks a Firebase error code to the user', () {
      const codes = [
        'user-not-found',
        'wrong-password',
        'invalid-credential',
        'email-already-in-use',
        'weak-password',
        'invalid-email',
        'network-request-failed',
        'too-many-requests',
        'user-disabled',
        'operation-not-allowed',
        'requires-recent-login',
        'unmapped-code',
      ];

      // Prose may contain hyphens ("Sign-up", "sign-in"); a raw code is the
      // lowercase-hyphenated run Firebase uses, like `operation-not-allowed`.
      final looksLikeCode = RegExp(r'\b[a-z]+(-[a-z]+){2,}\b');

      for (final code in codes) {
        final message = AuthScreen.friendlyAuthError(code);
        expect(looksLikeCode.hasMatch(message), isFalse,
            reason: '"$message" for $code leaks a raw error code');
        expect(message, isNot(contains('_')));
      }
    });
  });
}
