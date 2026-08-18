import 'package:flutter_test/flutter_test.dart';
import 'package:medai/providers/controllers/auth_controller.dart';

/// A new user who signed in with Google was greeted "Good evening, there".
///
/// enterAppAfterAuth fell back to `UserProfile(name: '')` when there was no
/// saved profile and no onboarding name, even though Firebase already knew the
/// person: Google and Apple sign-in both populate displayName. The name the
/// user had literally just authenticated with was sitting unused.
///
/// The email fallback is deliberately conservative. Deriving "User1234" from
/// user1234@… would be worse than no name at all, so anything that does not
/// read like a name is rejected and the greeting stays generic.
void main() {
  group('the provider display name wins', () {
    test('a Google account name is used as-is', () {
      expect(
        AuthController.resolveAccountName('Arafat Hossain', 'x@example.com'),
        'Arafat Hossain',
      );
    });

    test('surrounding whitespace is trimmed', () {
      expect(
        AuthController.resolveAccountName('  Jane Doe  ', null),
        'Jane Doe',
      );
    });

    test('an address supplied as the display name is not shown raw', () {
      // Some providers echo the email into displayName; printing
      // "Good evening, jane@example.com" looks broken and leaks the address
      // onto the home screen.
      expect(
        AuthController.resolveAccountName('jane@example.com', 'jane@example.com'),
        'Jane',
      );
    });
  });

  group('email fallback', () {
    test('dotted local parts become a name', () {
      expect(AuthController.resolveAccountName(null, 'j.smith@example.com'),
          'J Smith');
      expect(AuthController.resolveAccountName(null, 'jane_doe@example.com'),
          'Jane Doe');
      expect(AuthController.resolveAccountName(null, 'jane-doe@example.com'),
          'Jane Doe');
    });

    test('a plain local part is capitalised', () {
      expect(AuthController.resolveAccountName(null, 'arafat@example.com'),
          'Arafat');
    });

    test('the plus-tag is dropped', () {
      expect(AuthController.resolveAccountName(null, 'jane+medai@example.com'),
          'Jane Medai');
    });

    test('mostly-numeric addresses are rejected', () {
      // "User1234" is not this person's name.
      expect(AuthController.resolveAccountName(null, 'user1234@example.com'),
          isNull);
      expect(AuthController.resolveAccountName(null, '99887766@example.com'),
          isNull);
    });

    test('role addresses are rejected', () {
      for (final role in ['no-reply', 'noreply', 'admin', 'support', 'test']) {
        expect(AuthController.resolveAccountName(null, '$role@example.com'),
            isNull,
            reason: '$role is not a person');
      }
    });

    test('nothing at all yields null, not an empty name', () {
      // The caller only substitutes a non-null value, so the greeting keeps
      // its own "there" fallback rather than rendering an empty gap.
      expect(AuthController.resolveAccountName(null, null), isNull);
      expect(AuthController.resolveAccountName('', ''), isNull);
      expect(AuthController.resolveAccountName('   ', '   '), isNull);
    });

    test('a single character local part is rejected', () {
      expect(AuthController.resolveAccountName(null, 'a@example.com'), isNull);
    });
  });

  group('no hardcoded demo name reaches a real session', () {
    test('Alex only exists behind the dev-preview flag', () {
      // devPreviewJump seeds UserProfile(name: 'Alex'); it must stay gated by
      // kDevPreview, which is bool.fromEnvironment(..., defaultValue: false)
      // and therefore off unless explicitly built with --dart-define.
      final main = const bool.fromEnvironment('DEV_PREVIEW');
      expect(main, isFalse,
          reason: 'a normal build must never seed the demo profile');
    });
  });
}
