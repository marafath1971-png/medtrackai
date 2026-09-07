import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Three faults visible in one flow:
///
/// 1. Focusing the name field raised the keyboard over the pinned CTA, so the
///    button the form exists to reach was unreachable without dismissing it.
/// 2. The scroll body reserved no room for the keyboard, so the field being
///    typed into sat behind it.
/// 3. "Sign in to create an invite" was a dead end — the Circle tab has no
///    other route to the auth screen, and skipping onboarding leaves the app
///    usable with no Firebase account, so the branch is reachable normally.
void main() {
  late String form;
  late String tab;

  setUpAll(() {
    form = File('lib/screens/family/widgets/add_cg_flow.dart').readAsStringSync();
    tab = File('lib/screens/family/family_tab.dart').readAsStringSync();
  });

  group('the form survives the keyboard', () {
    test('the CTA rides above the IME', () {
      expect(form.contains('MediaQuery.viewInsetsOf(context).bottom'), isTrue,
          reason: 'a fixed offset leaves the button behind the keyboard');
      final i = form.indexOf('bottom: MediaQuery.viewInsetsOf');
      expect(i, greaterThan(-1),
          reason: 'the pinned CTA must track the inset');
    });

    test('the scroll body does not double count the keyboard', () {
      // Adding the inset to the scroll padding as well as riding the CTA on
      // it came to ~560px of bottom padding: the auto-scroll that reveals the
      // focused field then overshot far enough to push the form off the top
      // of the screen, which is what the second screenshot showed.
      final i = form.indexOf('bottom: AppSpacing.bottomBuffer + 56');
      expect(i, greaterThan(-1),
          reason: 'the scroll body clears the CTA only');

      // The CTA still tracks the inset; only the scroll padding must not.
      final cta = form.indexOf('bottom: MediaQuery.viewInsetsOf');
      expect(cta, greaterThan(-1));
    });

    test('the padding is not const', () {
      // A const EdgeInsets cannot read MediaQuery; this compiled only after
      // the const was dropped.
      expect(form.contains('padding: const EdgeInsets.only(\n'
          '                        left: AppSpacing.p24'), isFalse);
    });
  });

  group('a signed-out user is given a way in', () {
    test('the invite failure routes to auth instead of toasting', () {
      final i = tab.indexOf("lastInviteError == 'signed_out'");
      expect(i, greaterThan(-1),
          reason: 'the signed-out case needs its own branch');
      expect(tab.substring(i, i + 220).contains('AppRoutes.auth'), isTrue,
          reason: 'telling someone to sign in with no route there is a dead end');
    });

    test('other failures still show their message', () {
      // Only the signed-out case navigates; a denial or a transient error
      // still needs to say what happened.
      final i = tab.indexOf("lastInviteError == 'signed_out'");
      final after = tab.substring(i, i + 600);
      expect(after.contains('showToast'), isTrue);
      expect(after.contains('inviteErrorMessage'), isTrue);
    });
  });
}
