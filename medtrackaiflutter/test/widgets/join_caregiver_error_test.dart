import 'package:flutter_test/flutter_test.dart';
import 'package:medai/screens/family/widgets/join_as_cg_view.dart';

/// Entering an invite code appeared to do nothing.
///
/// joinCaregiver throws 'Sign in required' when there is no authenticated
/// account — the most common failure, since joining a care circle requires one
/// — but the view only matched 'Invalid' and 'your own'. Everything else,
/// including that case, became "Connection error", pointing the user at their
/// network instead of at signing in.
void main() {
  group('messageForError', () {
    test('a signed-out user is told to sign in, not to check their network',
        () {
      final msg = JoinAsCaregiverView.messageForError(
          Exception('Sign in required'));

      expect(msg.toLowerCase(), contains('sign in'));
      expect(msg.toLowerCase(), isNot(contains('connection')),
          reason: 'this was the misdiagnosis that made the flow look broken');
    });

    test('an unknown code says so and invites a retry', () {
      final msg = JoinAsCaregiverView.messageForError(Exception('Invalid code'));
      expect(msg.toLowerCase(), contains('invalid'));
    });

    test('self-monitoring is named explicitly', () {
      final msg = JoinAsCaregiverView.messageForError(
          Exception('Cannot monitor your own profile'));
      expect(msg.toLowerCase(), contains('yourself'));
    });

    test('an unrecognised failure still produces actionable text', () {
      final msg = JoinAsCaregiverView.messageForError(
          Exception('some unexpected firestore blowup'));

      expect(msg, isNotEmpty,
          reason: 'silence is what made this look like nothing happened');
      expect(msg.toLowerCase(), contains('try again'));
    });

    test('every branch returns a distinct message', () {
      final messages = {
        JoinAsCaregiverView.messageForError(Exception('Sign in required')),
        JoinAsCaregiverView.messageForError(Exception('Invalid code')),
        JoinAsCaregiverView.messageForError(
            Exception('Cannot monitor your own profile')),
        JoinAsCaregiverView.messageForError(Exception('network down')),
      };

      expect(messages, hasLength(4),
          reason: 'each failure needs its own remedy; collapsing them is how '
              '"Sign in required" got reported as a connection problem');
    });

    test('a bare string error is handled without throwing', () {
      expect(() => JoinAsCaregiverView.messageForError('Invalid code'),
          returnsNormally);
    });
  });
}
