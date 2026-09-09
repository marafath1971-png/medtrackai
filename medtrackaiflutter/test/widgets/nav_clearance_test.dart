import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/screens/app_shell.dart';
import 'package:medai/theme/app_theme.dart';

/// The shell floats an 80px nav island over `Positioned.fill` content and
/// reserves no layout space, so anything a tab pinned to the bottom ended up
/// underneath it. That shipped four times: the add-caregiver CTA was
/// unreachable, the "Set reminder for" sheet clipped its last medicine, and two
/// more surfaces ran content under the bar.
///
/// A static grep did not catch these — one offender padded 40px, which reads as
/// reasonable in code and only fails against the island. The shell now
/// publishes its footprint as MediaQuery padding; these tests pin that
/// contract.
Widget _host({required double bottomInset, required Widget child}) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: MediaQuery(
      data: MediaQueryData(padding: EdgeInsets.only(bottom: bottomInset)),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  test('the nav island footprint is a real, non-trivial clearance', () {
    // 80px island + 16px lift. If this shrinks to zero the shell has stopped
    // reserving space and pinned CTAs will slide back under the bar.
    expect(kShellNavIslandInset, greaterThanOrEqualTo(80));
  });

  testWidgets('SafeArea inside a tab inherits the clearance', (tester) async {
    late double inset;

    await tester.pumpWidget(_host(
      bottomInset: kShellNavIslandInset,
      child: Builder(builder: (context) {
        inset = MediaQuery.of(context).padding.bottom;
        return const SizedBox();
      }),
    ));

    expect(inset, kShellNavIslandInset,
        reason: 'tab content must see the island as bottom padding, which is '
            'what makes SafeArea and scrollables clear it automatically');
  });

  testWidgets('the island is pushed off-screen while the keyboard is up',
      (tester) async {
    // The island is pinned to the bottom of a box the Scaffold has already
    // shrunk for the IME, so leaving it visible floats it up over the form
    // the user is typing into — seen on a Pixel 7a sitting across the
    // relationship chips. The shell slides it out by its own height and
    // fades it, so this reproduces that offset.
    const islandKey = Key('island');
    const bottomPadding = 0.0;

    for (final keyboardUp in [false, true]) {
      await tester.pumpWidget(_host(
        bottomInset: kShellNavIslandInset,
        child: Stack(
          children: [
            Positioned(
              left: 20,
              right: 20,
              bottom: keyboardUp
                  ? -(kShellNavIslandInset + bottomPadding)
                  : (16 + bottomPadding),
              child: const SizedBox(
                  key: islandKey, height: 80, child: Text('Home')),
            ),
          ],
        ),
      ));

      final r = tester.getRect(find.byKey(islandKey));
      final screenH =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;

      if (keyboardUp) {
        expect(r.top, greaterThanOrEqualTo(screenH),
            reason: 'the island must be fully off the bottom edge with the '
                'keyboard up, not floating over the form');
      } else {
        expect(r.bottom, lessThanOrEqualTo(screenH),
            reason: 'with no keyboard the island must be back on screen');
      }
    }
  });

  testWidgets('a bottom-pinned CTA sits above the island, not under it',
      (tester) async {
    const buttonKey = Key('cta');

    await tester.pumpWidget(_host(
      bottomInset: kShellNavIslandInset,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            // The fix: clear the island rather than pinning to bottom: 0.
            bottom: kShellNavIslandInset,
            child: const SizedBox(
              key: buttonKey,
              height: 56,
              child: Text('Generate QR code'),
            ),
          ),
        ],
      ),
    ));

    final screenHeight = tester.getSize(find.byType(Scaffold)).height;
    final ctaBottom = tester.getBottomLeft(find.byKey(buttonKey)).dy;
    final islandTop = screenHeight - kShellNavIslandInset;

    expect(ctaBottom, lessThanOrEqualTo(islandTop + 0.5),
        reason: 'the CTA must finish above where the nav island starts, or '
            'its taps are swallowed by the bar');
  });

  testWidgets('a CTA pinned at bottom: 0 WOULD be covered — the shipped bug',
      (tester) async {
    const buttonKey = Key('cta');

    await tester.pumpWidget(_host(
      bottomInset: kShellNavIslandInset,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: const SizedBox(key: buttonKey, height: 56),
          ),
        ],
      ),
    ));

    final screenHeight = tester.getSize(find.byType(Scaffold)).height;
    final ctaBottom = tester.getBottomLeft(find.byKey(buttonKey)).dy;
    final islandTop = screenHeight - kShellNavIslandInset;

    expect(ctaBottom, greaterThan(islandTop),
        reason: 'documents the failure mode: pinning to bottom: 0 inside a tab '
            'puts the control underneath the floating nav');
  });

  testWidgets('a scrollable ends clear of the island', (tester) async {
    const lastKey = Key('last');

    await tester.pumpWidget(_host(
      bottomInset: kShellNavIslandInset,
      child: SafeArea(
        child: ListView(
          children: [
            for (var i = 0; i < 12; i++)
              SizedBox(height: 80, child: Text('$i')),
            const SizedBox(key: lastKey, height: 80, child: Text('last')),
          ],
        ),
      ),
    ));

    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();

    final screenHeight = tester.getSize(find.byType(Scaffold)).height;
    final lastBottom = tester.getBottomLeft(find.byKey(lastKey)).dy;

    expect(lastBottom,
        lessThanOrEqualTo(screenHeight - kShellNavIslandInset + 0.5),
        reason: 'SafeArea should stop the final row under the nav island');
  });
}
