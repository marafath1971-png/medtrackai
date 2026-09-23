import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/l10n/app_localizations.dart';
import 'package:medai/screens/onboarding/widgets/ob_unique_widgets.dart';
import 'package:medai/theme/app_theme.dart';

/// The first screen of the app.
///
/// It used to be a photo, a headline and a subtitle, then roughly a third of a
/// screen of empty cream above "Get started" — the app asked for a tap before
/// offering a reason for one. The capability lines now fill that space.
///
/// Two things here only a rendered layout can catch, and both were real:
///
///  * The value props were first placed *inside* the hero, which put them
///    above the headline — the screen listed features before saying what the
///    app was. Source greps and the claims tests all passed.
///  * Sizing the photo down to make room left the gap merely moved rather
///    than closed.
///
/// A Pixel 7a is 1080x2400 at 2.625x — roughly 411x914 logical px.
Widget _host(Widget child, {Size size = const Size(411, 914)}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.light(),
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: child,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('the hero leaves room for the value props', (tester) async {
    await tester.pumpWidget(_host(const ObLaurelWelcome()));
    await tester.pump(const Duration(seconds: 1));

    final hero = tester.getSize(find.byType(ObLaurelWelcome));

    // Tall enough to carry the opening image, but not so tall that the props
    // below it get pushed off a 914px-high screen once the headline and
    // subtitle are stacked between them.
    expect(hero.height, greaterThanOrEqualTo(280));
    expect(hero.height, lessThanOrEqualTo(320));
  });

  testWidgets('every capability line renders', (tester) async {
    await tester.pumpWidget(_host(const ObWelcomeValueProps()));
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('Scan any pill'), findsOneWidget);
    expect(find.textContaining('risky interactions'), findsOneWidget);
    expect(find.textContaining('a dose is missed'), findsOneWidget);
  });

  testWidgets('the capability lines fit without overflowing', (tester) async {
    // The longest line ("Catches risky interactions before you take them")
    // sits beside a 26px icon and an 11px gap. If it wraps past two lines the
    // block grows enough to push the CTA off screen.
    await tester.pumpWidget(_host(const ObWelcomeValueProps()));
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);

    final block = tester.getSize(find.byType(ObWelcomeValueProps));
    expect(block.height, lessThan(180),
        reason: 'three single- or double-line rows, not a wall of text');
  });

  testWidgets('the lines read in order, top to bottom', (tester) async {
    // Scanning comes first because it is the thing someone downloads this app
    // to do; the caregiver alert last because it matters most once they stay.
    await tester.pumpWidget(_host(const ObWelcomeValueProps()));
    await tester.pump(const Duration(seconds: 1));

    final scan = tester.getTopLeft(find.textContaining('Scan any pill')).dy;
    final interactions =
        tester.getTopLeft(find.textContaining('risky interactions')).dy;
    final alert =
        tester.getTopLeft(find.textContaining('a dose is missed')).dy;

    expect(scan, lessThan(interactions));
    expect(interactions, lessThan(alert));
  });

  testWidgets('nothing overflows at a large text scale', (tester) async {
    // Accessibility text sizes are where a fixed-height row breaks first, and
    // this screen's audience skews older.
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(411, 914),
            textScaler: TextScaler.linear(1.6),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const ObWelcomeValueProps(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
  });
}
