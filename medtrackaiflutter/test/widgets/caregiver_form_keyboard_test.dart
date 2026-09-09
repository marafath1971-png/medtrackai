import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/screens/family/widgets/add_cg_flow.dart';
import 'package:medai/screens/app_shell.dart' show kShellNavIslandInset;
import 'package:medai/theme/med_ai_ui.dart';

/// Three faults visible in one flow:
///
/// 1. Focusing the name field raised the keyboard over the pinned CTA, so the
///    button the form exists to reach was unreachable without dismissing it.
/// 2. The scroll body reserved no room for the keyboard, so the field being
///    typed into sat behind it.
/// 3. "Sign in to create an invite" was a dead end — the Circle tab has no
///    other route to the auth screen, and skipping onboarding leaves the app
///    usable with no Firebase account, so the branch is reachable normally.
///
/// The first two were "fixed" twice against source greps and shipped broken
/// both times. The reason: the shell Scaffold already sets
/// resizeToAvoidBottomInset, so this screen's box is ALREADY shrunk to the
/// space above the keyboard by the time it lays out. Adding viewInsets here as
/// well counted the keyboard twice and threw the CTA ~356px off the TOP of the
/// screen. Only a laid-out screen catches that, so these render one.

/// The Circle tab as the device actually reports it.
///
/// This harness used to wrap the child in a Padding(bottom: keyboard) to
/// emulate a body the shell had already shrunk, AND pass the full inset
/// through MediaQuery. That double count is what made every assertion here
/// agree with a screen that was visibly broken on a Pixel 7a: the CTA
/// measured at y=24 in the test, pinned to the top of the screen, exactly as
/// the device rendered it.
///
/// The shell's Scaffold sets resizeToAvoidBottomInset, so it hands this screen
/// a body ALREADY shrunk to the space above the IME while MediaQuery still
/// reports the full inset — both halves are modelled below.
///
/// The screen then sets resizeToAvoidBottomInset: false on its own
/// AppScaffold so it is not shrunk a SECOND time; that pairing is what makes
/// `bottom: 12` land the CTA just above the keyboard. Verified against a
/// Pixel 7a: drop either half and the CTA jumps to the top of the screen with
/// the name field hidden behind it.
Widget _shell(Widget child, {double keyboard = 0}) => MaterialApp(
      theme: AppTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(392, 850),
          viewInsets: EdgeInsets.only(bottom: keyboard),
          padding: const EdgeInsets.only(bottom: kShellNavIslandInset),
          viewPadding: const EdgeInsets.only(bottom: kShellNavIslandInset),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: keyboard),
          child: child,
        ),
      ),
    );

void main() {
  late String tab;
  setUpAll(() {
    tab = File('lib/screens/family/family_tab.dart').readAsStringSync();
  });

  group('the form survives the keyboard', () {
    late TextEditingController name;
    late TextEditingController contact;

    setUp(() {
      name = TextEditingController(text: 'Sarah Johnson');
      contact = TextEditingController();
    });
    tearDown(() {
      name.dispose();
      contact.dispose();
    });

    Future<void> pump(WidgetTester tester, {required double keyboard}) async {
      tester.view.physicalSize = const Size(392, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_shell(
        Builder(
            builder: (c) => AddCgStep1(
                  nameCtrl: name,
                  contactCtrl: contact,
                  relation: 'Spouse',
                  avatar: '\u{1F469}',
                  alertDelay: 30,
                  onRelChange: (_) {},
                  onAvatarChange: (_) {},
                  onDelayChange: (_) {},
                  L: c.L,
                  onBack: () {},
                  onNext: () async {},
                )),
        keyboard: keyboard,
      ));
      await tester.pump();
    }

    // 850 tall minus a 380px keyboard.
    const visibleBottom = 470.0;

    testWidgets('the CTA stays on screen with the keyboard up', (tester) async {
      await pump(tester, keyboard: 380);

      final cta = tester.getRect(find.text('Generate QR code'));

      expect(cta.top, greaterThanOrEqualTo(0.0),
          reason: 'double counting the inset put the CTA 356px above the top '
              'of the screen — the blank screenshot');
      expect(cta.bottom, lessThanOrEqualTo(visibleBottom),
          reason: 'the CTA must sit above the keyboard, not behind it');
    });

    testWidgets('the CTA is still clear of the nav island with no keyboard',
        (tester) async {
      await pump(tester, keyboard: 0);

      final cta = tester.getRect(find.text('Generate QR code'));

      expect(cta.bottom, lessThan(850.0 - kShellNavIslandInset),
          reason: 'with the keyboard down the floating nav island covers the '
              'bottom 166px and swallows taps');
    });

    testWidgets('the last field scrolls clear of the pinned CTA',
        (tester) async {
      await pump(tester, keyboard: 380);

      final pos =
          Scrollable.of(tester.element(find.text('Full name'))).position;
      pos.jumpTo(pos.maxScrollExtent);
      await tester.pump();

      final cta = tester.getRect(find.text('Generate QR code'));
      final last = tester.getRect(find.text('Alert after missed dose'));

      expect(last.bottom, lessThan(cta.top),
          reason: 'the final field must come to rest above the button, not '
              'underneath it');
    });

    testWidgets('the form does not scroll off the top', (tester) async {
      await pump(tester, keyboard: 380);

      final pos =
          Scrollable.of(tester.element(find.text('Full name'))).position;
      pos.jumpTo(pos.maxScrollExtent);
      await tester.pump();

      // Overshoot past the end is dead space the user must scroll back
      // through. Measure the genuinely last control — the delay options wrap
      // onto two lines, so the section label is no longer the bottom of the
      // form.
      final last = tester.getRect(find.text('1 hr'));
      final cta = tester.getRect(find.text('Generate QR code'));

      expect(last.bottom, lessThan(cta.top),
          reason: 'the last control must clear the pinned CTA');
      expect(cta.top - last.bottom, lessThan(150.0),
          reason: 'reserving nav clearance on top of an already-shrunk '
              'viewport left a screenful of empty space below the form');
    });
  });

  /// A large text scale is the same stress as a longer translation: the app
  /// ships in 7 locales, and "Generate QR code" is short in English.
  group('the form holds up when the text grows', () {
    for (final scale in [1.0, 1.6]) {
      for (final dark in [false, true]) {
        testWidgets('nothing overflows at ${scale}x, dark=$dark',
            (tester) async {
          tester.view.physicalSize = const Size(392, 850);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          final name = TextEditingController(text: 'Sarah Johnson');
          final contact = TextEditingController();
          addTearDown(name.dispose);
          addTearDown(contact.dispose);

          await tester.pumpWidget(MaterialApp(
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            home: MediaQuery(
              data: MediaQueryData(
                size: const Size(392, 850),
                textScaler: TextScaler.linear(scale),
                viewInsets: const EdgeInsets.only(bottom: 380),
                padding: const EdgeInsets.only(bottom: kShellNavIslandInset),
                viewPadding:
                    const EdgeInsets.only(bottom: kShellNavIslandInset),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 380),
                child: Builder(
                    builder: (c) => AddCgStep1(
                          nameCtrl: name,
                          contactCtrl: contact,
                          relation: 'Spouse',
                          avatar: '\u{1F469}',
                          alertDelay: 30,
                          onRelChange: (_) {},
                          onAvatarChange: (_) {},
                          onDelayChange: (_) {},
                          L: c.L,
                          onBack: () {},
                          onNext: () async {},
                        )),
              ),
            ),
          ));
          await tester.pump();

          expect(tester.takeException(), isNull,
              reason: 'the CTA label and the delay buttons both overflowed '
                  'their rows once the text was scaled up');
        });
      }
    }
  });

  group('a signed-out user is given a way in', () {
    test('the invite failure routes to auth instead of toasting', () {
      final i = tab.indexOf("lastInviteError == 'signed_out'");
      expect(i, greaterThan(-1),
          reason: 'the signed-out case needs its own branch');
      expect(tab.substring(i, i + 220).contains('AppRoutes.auth'), isTrue,
          reason:
              'telling someone to sign in with no route there is a dead end');
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
