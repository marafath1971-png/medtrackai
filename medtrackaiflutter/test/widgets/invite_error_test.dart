import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:medai/providers/controllers/social_controller.dart';

/// Creating a caregiver invite showed "Could not create invite. Check your
/// connection and try again." for every failure, including the common one:
/// being signed out. `createInvite` returns an empty string both when
/// `AuthService.uid` is null and when the write throws, so the screen could not
/// tell a signed-out user from a network problem and sent them to debug their
/// wifi over an account issue.
///
/// This is the same defect already fixed on the join side of the same feature
/// (see join_caregiver_error_test.dart) — it survived on the invite side
/// because that sweep only covered catch blocks, not early returns.
void main() {
  group('inviteErrorMessage', () {
    test('signed out asks the user to sign in', () {
      final msg = SocialController.inviteErrorMessage('signed_out');

      expect(msg.toLowerCase(), contains('sign in'));
      expect(msg.toLowerCase(), isNot(contains('connection')),
          reason: 'checking the network can never fix a missing account');
    });

    test('a genuine failure suggests retrying', () {
      final msg = SocialController.inviteErrorMessage('failed');

      expect(msg.toLowerCase(), contains('try again'));
    });

    test('an unknown reason still produces actionable text', () {
      final msg = SocialController.inviteErrorMessage(null);

      expect(msg, isNotEmpty);
      expect(msg.toLowerCase(), contains('try again'));
    });

    test('the two causes do not share a message', () {
      // Collapsing them is what made the invite look like a network bug.
      expect(
        SocialController.inviteErrorMessage('signed_out'),
        isNot(SocialController.inviteErrorMessage('failed')),
      );
    });
  });

  group('no unverifiable claims remain in shipped copy', () {
    // These were removed from the onboarding strings earlier, but survived in
    // the paywall, a theme constant and two widget defaults — including five
    // hardcoded stars and a "4.9" rating directly above the purchase button,
    // which is the highest-risk placement for a fabricated claim.
    test('no fabricated rating or install count in lib/', () {
      final offenders = <String>[];

      void walk(Directory dir) {
        for (final e in dir.listSync()) {
          if (e is Directory) {
            walk(e);
          } else if (e.path.endsWith('.dart')) {
            final src = File(e.path).readAsStringSync();
            for (final line in src.split('\n')) {
              // Skip comments: several files explain the removed claim.
              final t = line.trimLeft();
              if (t.startsWith('//') || t.startsWith('///')) continue;
              if (line.contains('500K+') ||
                  line.contains('500,000+') ||
                  line.contains('4.9 ·')) {
                offenders.add('${e.path}: ${line.trim()}');
              }
            }
          }
        }
      }

      walk(Directory('lib'));

      expect(offenders, isEmpty,
          reason: 'a fabricated user count or star rating is a Play policy '
              'violation, and next to a buy button it is the worst placement');
    });
  });
}
