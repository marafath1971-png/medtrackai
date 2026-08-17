import 'package:flutter_test/flutter_test.dart';
import 'package:medai/screens/auth/auth_screen.dart';

/// Sign-in error copy.
///
/// Anything unmapped falls through to "Something went wrong. Please try
/// again.", so a code where retrying cannot help — a disabled account, or
/// being rate limited — has to be named explicitly or the app gives advice
/// that will never work. That is the same failure the caregiver join screen
/// had: telling someone to check their connection when they needed to sign in.
void main() {
  group('friendlyAuthError', () {
    test('invalid-credential is treated as a wrong password', () {
      // Modern Firebase returns this instead of wrong-password, so without it
      // the single most common sign-in failure showed the generic message.
      final msg = AuthScreen.friendlyAuthError('invalid-credential');

      expect(msg.toLowerCase(), contains('incorrect'));
      expect(msg.toLowerCase(), isNot(contains('something went wrong')));
    });

    test('too-many-requests advises waiting, not retrying', () {
      final msg = AuthScreen.friendlyAuthError('too-many-requests');

      expect(msg.toLowerCase(), contains('wait'),
          reason: 'retrying immediately makes rate limiting worse');
    });

    test('user-disabled does not tell the user to try again', () {
      final msg = AuthScreen.friendlyAuthError('user-disabled');

      expect(msg.toLowerCase(), contains('support'));
      expect(msg.toLowerCase(), isNot(contains('try again')),
          reason: 'retrying can never succeed for a disabled account');
    });

    test('the established codes still map', () {
      expect(AuthScreen.friendlyAuthError('user-not-found').toLowerCase(),
          contains('no account'));
      expect(AuthScreen.friendlyAuthError('weak-password').toLowerCase(),
          contains('6 characters'));
      expect(AuthScreen.friendlyAuthError('invalid-email').toLowerCase(),
          contains('valid email'));
      expect(
          AuthScreen.friendlyAuthError('network-request-failed').toLowerCase(),
          contains('internet'));
      expect(AuthScreen.friendlyAuthError('email-already-in-use').toLowerCase(),
          contains('already exists'));
    });

    test('an unknown code still produces actionable text', () {
      final msg = AuthScreen.friendlyAuthError('some-future-code');

      expect(msg, isNotEmpty);
      expect(msg.toLowerCase(), contains('try again'));
    });

    test('codes with different remedies get different messages', () {
      final messages = {
        AuthScreen.friendlyAuthError('user-not-found'),
        AuthScreen.friendlyAuthError('invalid-credential'),
        AuthScreen.friendlyAuthError('too-many-requests'),
        AuthScreen.friendlyAuthError('user-disabled'),
        AuthScreen.friendlyAuthError('network-request-failed'),
      };

      expect(messages, hasLength(5),
          reason: 'collapsing distinct failures into one message is what sent '
              'users to fix the wrong thing');
    });
  });
}
