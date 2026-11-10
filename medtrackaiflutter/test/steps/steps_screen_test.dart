import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/data/datasources/steps_cloud.dart';
import 'package:medai/domain/entities/step_day.dart';
import 'package:medai/l10n/app_localizations.dart';
import 'package:medai/providers/controllers/steps_controller.dart';
import 'package:medai/screens/home/widgets/home_steps_card.dart';
import 'package:medai/screens/steps/steps_screen.dart';
import 'package:medai/screens/steps/widgets/step_ring.dart';
import 'package:medai/screens/steps/widgets/steps_charts.dart';
import 'package:medai/services/steps_service.dart';
import 'package:medai/theme/med_ai_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

/// These pump the real screen and measure what was laid out. Asserting on the
/// source text of a screen has passed here before while the screen itself
/// rendered off-screen.
void main() {
  late FakeStepSource source;
  late FakeStepsCloud cloud;
  final now = DateTime(2026, 10, 13, 15, 30);

  Future<StepsController> controller({bool enabled = true}) async {
    SharedPreferences.setMockInitialValues({'steps_enabled': enabled});
    final prefs = await SharedPreferences.getInstance();
    return StepsController(
        prefs: prefs, source: source, cloud: cloud, now: () => now)
      ..attachAccount(name: 'Alex', avatar: '');
  }

  Widget host(Widget child, {ThemeData? theme, double textScale = 1}) =>
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: theme ?? AppTheme.light(),
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: app!,
        ),
        home: child,
      );

  /// Scrolls the dashboard until [finder] is built and on screen. The list is
  /// lazy, so anything below the fold does not exist until it is scrolled to.
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      120,
      scrollable: find
          .descendant(
              of: find.byType(ListView), matching: find.byType(Scrollable))
          .first,
    );
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// A real phone, not the 800x600 test default.
  void phone(WidgetTester tester, [Size size = const Size(390, 844)]) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> pair(WidgetTester tester, StepsController c) async {
    cloud.partners.add([const StepPartner(uid: 'sam')]);
    await tester.pump();
    cloud.daysOf('sam').add({
      '2026-10-13': const StepDay(
          dateKey: '2026-10-13', steps: 6000, goal: 6000, name: 'Sam'),
    });
    await tester.pump();
  }

  setUp(() {
    source = FakeStepSource();
    cloud = FakeStepsCloud();
    source.todayHourly[8] = 1200;
    source.todayHourly[12] = 3000;
    source.todayHourly[15] = 400;
    source.pastDays = {
      DateTime(2026, 10, 12): 9000,
      DateTime(2026, 10, 11): 8500,
    };
  });

  group('before it is turned on', () {
    testWidgets('the screen explains the feature and offers to turn it on',
        (tester) async {
      phone(tester);
      final c = await controller(enabled: false);
      await tester.pumpWidget(host(StepsScreen(controller: c)));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Count every step'), findsOneWidget);
      expect(find.text('Turn on step counting'), findsOneWidget);
      expect(find.text('Walk together'), findsNothing);
    });

    testWidgets('turning it on swaps in the dashboard', (tester) async {
      phone(tester);
      final c = await controller(enabled: false);
      await tester.pumpWidget(host(StepsScreen(controller: c)));
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text('Turn on step counting'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('4,600'), findsOneWidget);
      expect(find.text('Count every step'), findsNothing);
    });

    testWidgets('a phone with no step source is told so, with no dead button',
        (tester) async {
      phone(tester);
      source.access = StepAccess.unavailable;
      final c = await controller(enabled: false);
      await c.enable();
      await tester.pumpWidget(host(StepsScreen(controller: c)));
      await tester.pump(const Duration(seconds: 2));

      expect(find.textContaining('no step source'), findsOneWidget);
      expect(find.text('Turn on step counting'), findsNothing);
    });
  });

  group('dashboard', () {
    testWidgets('shows the count, the goal and what is left', (tester) async {
      phone(tester);
      final c = await controller();
      await tester.pumpWidget(host(StepsScreen(controller: c)));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('4,600'), findsOneWidget);
      expect(find.text('of 8,000 steps'), findsOneWidget);
      expect(
          find.text('3,400 to go · about 34 min of walking'), findsOneWidget);
      await reveal(tester, find.text('Distance'));
      expect(find.text('3.51 km'), findsOneWidget);
    });

    testWidgets('the count sits inside the ring, not across it',
        (tester) async {
      phone(tester);
      final c = await controller();
      await tester.pumpWidget(host(StepsScreen(controller: c)));
      await tester.pump(const Duration(seconds: 2));

      final ring = tester.getRect(find.byType(StepRing).first);
      final count = tester.getRect(find.text('4,600'));
      // Inside the ring's inner circle: clear of the stroke on both sides.
      expect(count.left, greaterThan(ring.left + 18));
      expect(count.right, lessThan(ring.right - 18));
    });

    testWidgets('nothing overflows on a small phone at a large text size',
        (tester) async {
      phone(tester, const Size(320, 568));

      final c = await controller();
      await tester
          .pumpWidget(host(StepsScreen(controller: c), textScale: 1.35));
      await tester.pump(const Duration(seconds: 2));
      await pair(tester, c);
      await tester.pump(const Duration(seconds: 1));

      // Scroll the whole dashboard through the viewport so every card lays
      // out; an overflow anywhere throws.
      for (var i = 0; i < 12; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull, reason: 'after scroll $i');
      }
    });

    testWidgets('a met goal says so instead of counting down', (tester) async {
      phone(tester);
      source.todayHourly[10] = 5000;
      final c = await controller();
      await tester.pumpWidget(host(StepsScreen(controller: c)));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Goal reached · 1,600 past it'), findsOneWidget);
      expect(find.textContaining('to go'), findsNothing);
    });

    testWidgets('zero steps comes with a hint, not a bare zero',
        (tester) async {
      phone(tester);
      source.todayHourly = List.filled(24, 0);
      final c = await controller();
      await tester.pumpWidget(host(StepsScreen(controller: c)));
      await tester.pump(const Duration(seconds: 2));

      expect(find.textContaining('Seeing 0?'), findsOneWidget);
    });

    testWidgets('tapping a day in the week chart shows that day',
        (tester) async {
      phone(tester);
      final c = await controller();
      await tester.pumpWidget(host(StepsScreen(controller: c)));
      await tester.pump(const Duration(seconds: 2));

      await reveal(tester, find.byType(StepsWeekChart));
      expect(find.text('Tuesday: 4,600 steps'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Monday: 9,000 steps'));
      await tester.pump();
      expect(find.text('Monday: 9,000 steps'), findsOneWidget);
    });

    testWidgets('the goal sheet changes the goal', (tester) async {
      phone(tester);
      final c = await controller();
      await tester.pumpWidget(host(StepsScreen(controller: c)));
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text('Change goal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('5,000'));
      await tester.pump();
      await tester.tap(find.text('Save goal'));
      await tester.pumpAndSettle();

      expect(c.goal, 5000);
      expect(find.text('of 5,000 steps'), findsOneWidget);
    });
  });

  group('walking together', () {
    testWidgets('unpaired, it offers both ways to pair', (tester) async {
      phone(tester);
      final c = await controller();
      await tester.pumpWidget(host(StepsScreen(controller: c)));
      await tester.pump(const Duration(seconds: 2));

      await reveal(tester, find.text('I have a code'));
      expect(find.text('Invite a partner'), findsOneWidget);
      expect(find.text('I have a code'), findsOneWidget);
    });

    testWidgets('signed out, it asks for sign-in rather than failing later',
        (tester) async {
      phone(tester);
      cloud.uid = null;
      final c = await controller();
      await tester.pumpWidget(host(StepsScreen(controller: c)));
      await tester.pump(const Duration(seconds: 2));

      await reveal(tester, find.text('Sign in to pair with a partner.'));
      expect(find.text('Sign in to pair with a partner.'), findsOneWidget);
      expect(find.text('Invite a partner'), findsNothing);
    });

    testWidgets('paired, it shows both walkers and the shared total',
        (tester) async {
      phone(tester);
      final c = await controller();
      await tester.pumpWidget(host(StepsScreen(controller: c)));
      await tester.pump(const Duration(seconds: 2));
      await pair(tester, c);
      await tester.pump(const Duration(seconds: 1));

      // Two rings in the hero once there is a partner.
      final ring = tester.widget<StepRing>(find.byType(StepRing).first);
      expect(ring.arcs.length, 2);

      await reveal(tester, find.text('Cheer'));
      expect(find.text('10,600 of 14,000 together'), findsOneWidget);
      expect(find.text('Sam is 1,400 ahead'), findsOneWidget);
    });

    testWidgets('the invite sheet shows a code the partner can type',
        (tester) async {
      phone(tester);
      final c = await controller();
      await tester.pumpWidget(host(StepsScreen(controller: c)));
      await tester.pump(const Duration(seconds: 2));

      await reveal(tester, find.text('Invite a partner'));
      await tester.tap(find.text('Invite a partner'));
      await tester.pumpAndSettle();

      expect(find.text('ABC234'), findsOneWidget);
      expect(find.text('Share code'), findsOneWidget);
    });

    testWidgets('a bad code is explained in the sheet', (tester) async {
      phone(tester);
      cloud.joinResult = StepJoinResult.notFound;
      final c = await controller();
      await tester.pumpWidget(host(StepsScreen(controller: c)));
      await tester.pump(const Duration(seconds: 2));

      await reveal(tester, find.text('I have a code'));
      await tester.tap(find.text('I have a code'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'zzz999');
      await tester.pump();
      await tester.tap(find.text('Pair up'));
      await tester.pumpAndSettle();

      expect(cloud.lastCode, 'ZZZ999');
      expect(
          find.text("That code isn't valid or has expired."), findsOneWidget);
    });
  });

  group('home card', () {
    testWidgets('off: it is the way in', (tester) async {
      phone(tester);
      final c = await controller(enabled: false);
      var opened = 0;
      await tester.pumpWidget(host(
          Scaffold(body: HomeStepsCard(steps: c, onOpen: () => opened++))));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Count your steps'), findsOneWidget);
      await tester.tap(find.byType(HomeStepsCard));
      // The press animation and haptic throttle run on timers.
      await tester.pump(const Duration(seconds: 1));
      expect(opened, 1);
    });

    testWidgets('on: today\'s count; paired: the partner\'s too',
        (tester) async {
      phone(tester);
      final c = await controller();
      await c.refresh(force: true);
      await tester.pumpWidget(host(
          Scaffold(body: HomeStepsCard(steps: c, onOpen: () {})),
          theme: AppTheme.dark()));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('4,600 steps'), findsOneWidget);
      expect(find.text('3,400 to go today'), findsOneWidget);

      await pair(tester, c);
      expect(find.text('Sam: 6,000'), findsOneWidget);
    });
  });
}
