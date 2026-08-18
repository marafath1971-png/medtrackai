import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/screens/home/widgets/home_today_hero.dart';
import 'package:medai/theme/med_ai_ui.dart';
import 'package:medai/widgets/common/ghost_mascot.dart';

/// Home opened on a 168px stock photograph of a salad, captioned
/// "MADE FOR YOU · Your #1 plan for medication success".
///
/// Nothing in the app tracks meals, so the picture promised a feature that does
/// not exist; "MADE FOR YOU" sat above a line identical for every user; and it
/// pushed the actual schedule below the fold. HomeTodayHero replaces it with
/// the day's real state in less vertical space.
Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  group('states', () {
    testWidgets('no medicines yet invites the first scan', (tester) async {
      await tester.pumpWidget(_host(const HomeTodayHero(taken: 0, total: 0)));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Add your first medicine'), findsOneWidget);
      expect(find.textContaining('Scan a box'), findsOneWidget);
    });

    testWidgets('a fresh day names the number of doses', (tester) async {
      await tester.pumpWidget(_host(const HomeTodayHero(taken: 0, total: 3)));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('3 doses scheduled'), findsOneWidget);
    });

    testWidgets('one dose is not pluralised', (tester) async {
      await tester.pumpWidget(_host(const HomeTodayHero(taken: 0, total: 1)));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('1 dose scheduled'), findsOneWidget);
    });

    testWidgets('mid-day shows progress', (tester) async {
      await tester.pumpWidget(_host(const HomeTodayHero(taken: 2, total: 4)));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('2 of 4 taken'), findsOneWidget);
    });

    testWidgets('a finished day says so, and uses the name', (tester) async {
      await tester.pumpWidget(
          _host(const HomeTodayHero(taken: 3, total: 3, name: 'Alex')));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Every dose taken, Alex'), findsOneWidget);
    });

    testWidgets('completion does not require a name', (tester) async {
      await tester.pumpWidget(_host(const HomeTodayHero(taken: 2, total: 2)));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Every dose taken'), findsOneWidget);
    });
  });

  group('the next dose is surfaced', () {
    testWidgets('it replaces the generic line when known', (tester) async {
      await tester.pumpWidget(_host(const HomeTodayHero(
        taken: 1,
        total: 3,
        nextDose: 'Next dose · 2h Metformin',
      )));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Next dose · 2h Metformin'), findsOneWidget);
      expect(find.textContaining('Keep going'), findsNothing);
    });
  });

  group('robustness', () {
    testWidgets('more taken than scheduled still reads as complete',
        (tester) async {
      // Taking a dose late can push the count past the schedule; the hero must
      // not render "5 of 4 taken" or divide past 100%.
      await tester.pumpWidget(_host(const HomeTodayHero(taken: 5, total: 4)));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.text('Every dose taken'), findsOneWidget);
    });

    testWidgets('a long dose label does not overflow', (tester) async {
      await tester.pumpWidget(_host(const HomeTodayHero(
        taken: 0,
        total: 2,
        nextDose: 'Next dose · 30m Hydrochlorothiazide 25mg extended release',
      )));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });

    testWidgets('a large schedule renders without a segment per dose',
        (tester) async {
      // Above eight, segments get too thin to read and fall back to a bar.
      await tester.pumpWidget(_host(const HomeTodayHero(taken: 4, total: 12)));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });

  testWidgets('the mascot reflects the state rather than decorating it',
      (tester) async {
    await tester.pumpWidget(_host(const HomeTodayHero(taken: 2, total: 2)));
    await tester.pump(const Duration(milliseconds: 300));
    final done = tester.widget<GhostMascot>(find.byType(GhostMascot)).asset;

    await tester.pumpWidget(_host(const HomeTodayHero(taken: 0, total: 0)));
    await tester.pump(const Duration(milliseconds: 300));
    final empty = tester.widget<GhostMascot>(find.byType(GhostMascot)).asset;

    expect(done, isNot(empty),
        reason: 'a finished day and an empty app should not look the same');
  });
}
