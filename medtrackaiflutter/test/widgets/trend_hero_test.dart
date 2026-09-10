import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/screens/stats/widgets/trend_hero.dart';
import 'package:medai/theme/med_ai_ui.dart';
import 'package:medai/l10n/app_localizations.dart';

/// The Trends tab opened on "Adherence 0% / All time" and "Symptoms 0 / Total
/// logs" — two flat tiles above a list of navigation cards. Nothing on it
/// trended. An all-time average cannot answer "is this week better than last",
/// which is the only question the tab exists for, and a 30-day series was
/// already being computed by getTrendData() and left unused.
Widget _host(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

List<double> _series({required double older, required double recent}) =>
    [...List.filled(7, older), ...List.filled(7, recent)];

void main() {
  group('week-over-week maths', () {
    test('improvement is reported in points', () {
      const hero = TrendHero(series: []);
      expect(hero.deltaPoints, 0, reason: 'an empty series must not divide');

      final better = TrendHero(series: _series(older: 0.6, recent: 0.9));
      expect(better.thisWeek, closeTo(0.9, 0.001));
      expect(better.lastWeek, closeTo(0.6, 0.001));
      expect(better.deltaPoints, 30);
    });

    test('decline is negative, not an absolute value', () {
      final worse = TrendHero(series: _series(older: 0.9, recent: 0.5));

      expect(worse.deltaPoints, -40,
          reason: 'the sign is what tells the user which way they are going');
    });

    test('a steady fortnight reads as no change', () {
      final flat = TrendHero(series: _series(older: 0.8, recent: 0.8));

      expect(flat.deltaPoints, 0);
    });
  });

  group('not enough history', () {
    test('under eight days offers no comparison', () {
      // With one week of data there is no previous week to compare against;
      // showing "+80 pts" against an implicit zero would be a lie.
      final young = TrendHero(series: List.filled(5, 0.8));

      expect(young.hasComparison, isFalse);
      expect(young.lastWeek, 0);
    });

    test('an all-zero history offers no comparison', () {
      // A new user with logged days but no doses taken should be encouraged,
      // not told they are flat at zero.
      final empty = TrendHero(series: List.filled(30, 0.0));

      expect(empty.hasComparison, isFalse);
    });

    test('a partial week still averages what exists', () {
      final partial = TrendHero(series: [0.5, 1.0, 0.5]);

      expect(partial.thisWeek, closeTo(0.666, 0.01));
    });
  });

  group('rendering', () {
    testWidgets('states the comparison in words, not just a chip',
        (tester) async {
      await tester
          .pumpWidget(_host(TrendHero(series: _series(older: 0.6, recent: 0.9))));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('90%'), findsOneWidget);
      expect(find.textContaining('30 points better than last week'),
          findsOneWidget);
    });

    testWidgets('a decline is not dressed up as progress', (tester) async {
      await tester
          .pumpWidget(_host(TrendHero(series: _series(older: 0.9, recent: 0.5))));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('40 points below last week'), findsOneWidget);
    });

    testWidgets('a new user is told what unlocks the comparison',
        (tester) async {
      await tester.pumpWidget(_host(const TrendHero(series: [0.0, 0.0])));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Keep logging doses'), findsOneWidget);
    });

    testWidgets('an empty series renders without throwing', (tester) async {
      await tester.pumpWidget(_host(const TrendHero(series: [])));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('a full 30-day series renders', (tester) async {
      final series = [for (var i = 0; i < 30; i++) (i % 10) / 10];

      await tester.pumpWidget(_host(TrendHero(series: series)));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.text('30 days ago'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
    });
  });
}
