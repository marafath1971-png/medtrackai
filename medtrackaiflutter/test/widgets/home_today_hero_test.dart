import 'dart:io';
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

  group('the streak folded in from the removed hero', () {
    testWidgets('it shows when there is one', (tester) async {
      await tester.pumpWidget(_host(HomeTodayHero(
        taken: 2,
        total: 4,
        streak: 5,
        onStreakTap: () {},
      )));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('5 day streak'), findsOneWidget);
    });

    testWidgets('one day is not pluralised', (tester) async {
      await tester.pumpWidget(_host(HomeTodayHero(
        taken: 1,
        total: 2,
        streak: 1,
        onStreakTap: () {},
      )));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('1 day streak'), findsOneWidget);
    });

    testWidgets('a zero streak is not shown at all', (tester) async {
      // A new user does not need to be told their streak is nothing.
      await tester.pumpWidget(_host(HomeTodayHero(
        taken: 0,
        total: 3,
        streak: 0,
        onStreakTap: () {},
      )));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('streak'), findsNothing);
    });

    testWidgets('tapping it opens the streak detail', (tester) async {
      // LimeProgressHero carried this tap target; removing that widget must
      // not remove the route into the streak modal.
      var taps = 0;
      await tester.pumpWidget(_host(HomeTodayHero(
        taken: 2,
        total: 4,
        streak: 9,
        onStreakTap: () => taps++,
      )));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('9 day streak'));
      await tester.pump();

      expect(taps, 1);
    });
  });

  group('Home shows one dose summary, not three', () {
    test('the duplicate heroes are gone from the tab', () {
      // HomeTodayHero, LimeProgressHero and two RefBentoTiles all rendered
      // taken/total and the next dose, stacked consecutively, which pushed the
      // schedule itself below the fold.
      final src = File('lib/screens/home/home_tab.dart').readAsStringSync();

      expect(src.contains('LimeProgressHero('), isFalse);
      expect(src.contains('RefBentoTile('), isFalse);
      expect(src.contains('HomeTodayHero('), isTrue,
          reason: 'the surviving summary must still be there');
    });

    test('the invite prompt is no longer unconditional', () {
      // It rendered on every visit forever, competing with the schedule.
      final src = File('lib/screens/home/home_tab.dart').readAsStringSync();
      final i = src.indexOf('RecommendHopeCta(');
      expect(i, greaterThan(-1));

      final before = src.substring((i - 500).clamp(0, src.length), i);
      expect(before.contains('if (streak >='), isTrue,
          reason: 'a user with no streak has nothing to recommend yet');
    });

    test('the orphaned widget files are gone, not just unreferenced', () {
      // Removing the call sites left 400 lines compiling but unreachable.
      // Dead widgets get re-imported by whoever greps for "hero" next.
      expect(
        File('lib/screens/dashboard/widgets/lime_progress_hero.dart')
            .existsSync(),
        isFalse,
      );
      expect(
        File('lib/screens/dashboard/widgets/ref_bento_tile.dart').existsSync(),
        isFalse,
      );
    });
  });
}
