import 'package:flutter_test/flutter_test.dart';
import 'package:medai/data/datasources/steps_cloud.dart';
import 'package:medai/domain/entities/step_day.dart';
import 'package:medai/providers/controllers/steps_controller.dart';
import 'package:medai/services/steps_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeStepSource source;
  late FakeStepsCloud cloud;
  late SharedPreferences prefs;
  var now = DateTime(2026, 10, 13, 15, 30);

  Future<StepsController> build({Map<String, Object> stored = const {}}) async {
    SharedPreferences.setMockInitialValues(stored);
    prefs = await SharedPreferences.getInstance();
    return StepsController(
        prefs: prefs, source: source, cloud: cloud, now: () => now);
  }

  setUp(() {
    now = DateTime(2026, 10, 13, 15, 30);
    source = FakeStepSource();
    cloud = FakeStepsCloud();
    source.todayHourly[8] = 1200;
    source.todayHourly[12] = 3000;
    source.todayHourly[15] = 400;
    source.pastDays = {
      DateTime(2026, 10, 12): 9000,
      DateTime(2026, 10, 11): 8500,
      DateTime(2026, 10, 10): 2000,
    };
  });

  group('turning it on', () {
    test('starts off, with the default goal and an empty today', () async {
      final c = await build();
      expect(c.enabled, isFalse);
      expect(c.goal, 8000);
      expect(c.today.steps, 0);
      await c.refresh(force: true);
      expect(source.reads, 0,
          reason: 'nothing is read before the user opts in');
    });

    test('a granted request enables, reads and remembers', () async {
      final c = await build();
      expect(await c.enable(), StepAccess.granted);
      expect(c.enabled, isTrue);
      expect(c.today.steps, 4600);
      expect(prefs.getBool('steps_enabled'), isTrue);
    });

    test('a refusal leaves it off', () async {
      final c = await build();
      source.access = StepAccess.denied;
      expect(await c.enable(), StepAccess.denied);
      expect(c.enabled, isFalse);
      expect(c.access, StepAccess.denied);
    });

    test('a missing Health Connect is reported, not treated as zero steps',
        () async {
      final c = await build(stored: {'steps_enabled': true});
      source.access = StepAccess.needsInstall;
      await c.refresh(force: true);
      expect(c.access, StepAccess.needsInstall);
      expect(c.days, isEmpty);
    });
  });

  group('reading', () {
    test('today has an hourly breakdown; history fills the week', () async {
      final c = await build(stored: {'steps_enabled': true});
      await c.refresh(force: true);

      expect(c.today.hourly[12], 3000);
      expect(c.today.hourly[16], 0, reason: 'hours not yet reached are empty');
      expect(c.peakHour, 12);
      expect(c.activeHours, 3);
      expect(c.week.map((d) => d.steps).toList().sublist(3),
          [2000, 8500, 9000, 4600]);
      expect(c.week.length, 7);
    });

    test('the streak survives an unfinished today', () async {
      final c = await build(stored: {'steps_enabled': true});
      await c.refresh(force: true);
      expect(c.today.goalMet, isFalse);
      expect(c.streak, 2);
    });

    test('refreshes are throttled unless forced', () async {
      final c = await build(stored: {'steps_enabled': true});
      await c.refresh(force: true);
      final reads = source.reads;
      await c.refresh();
      expect(source.reads, reads);
      now = now.add(const Duration(minutes: 1));
      await c.refresh();
      expect(source.reads, greaterThan(reads));
    });

    test('old days are read once; recent days are re-read', () async {
      final c = await build(stored: {'steps_enabled': true});
      await c.refresh(force: true);
      // A watch delivers yesterday's steps late.
      source.pastDays[DateTime(2026, 10, 12)] = 9900;
      source.pastDays[DateTime(2026, 10, 10)] = 7777;
      await c.refresh(force: true);
      expect(c.days['2026-10-12']!.steps, 9900);
      expect(c.days['2026-10-10']!.steps, 2000);
    });

    test('the cache survives a restart', () async {
      final first = await build(stored: {'steps_enabled': true});
      await first.refresh(force: true);

      final second = StepsController(
          prefs: prefs, source: source, cloud: cloud, now: () => now);
      expect(second.today.steps, 4600);
      expect(second.today.hourly[12], 3000);
      expect(second.days['2026-10-12']!.steps, 9000);
    });

    test('a new day starts at zero, not at yesterday\'s count', () async {
      final c = await build(stored: {'steps_enabled': true});
      await c.refresh(force: true);
      now = DateTime(2026, 10, 14, 0, 5);
      expect(c.today.dateKey, '2026-10-14');
      expect(c.today.steps, 0);
    });
  });

  group('goal', () {
    test('changing it re-scores today but not the past', () async {
      final c = await build(stored: {'steps_enabled': true});
      await c.refresh(force: true);
      await c.setGoal(4500);

      expect(c.today.goalMet, isTrue);
      expect(c.days['2026-10-10']!.goal, 8000);
      expect(c.days['2026-10-10']!.goalMet, isFalse);
      expect(prefs.getInt('steps_goal'), 4500);
    });

    test('out-of-range goals are clamped', () async {
      final c = await build();
      await c.setGoal(3);
      expect(c.goal, 1000);
    });
  });

  group('cloud', () {
    test('today is pushed with the owner\'s name, and only when it changes',
        () async {
      final c = await build(stored: {'steps_enabled': true});
      c.attachAccount(name: 'Alex', avatar: '🙂');
      await c.refresh(force: true);
      await c.refresh(force: true);

      expect(cloud.saved.length, 1);
      expect(cloud.saved.single.steps, 4600);
      expect(cloud.saved.single.name, 'Alex');
      expect(cloud.saved.single.hourly, isEmpty,
          reason: 'a partner sees the total, not when you were moving');
    });

    test('nothing is pushed while signed out', () async {
      cloud.uid = null;
      final c = await build(stored: {'steps_enabled': true});
      await c.refresh(force: true);
      expect(cloud.saved, isEmpty);
    });
  });

  group('partner', () {
    Future<StepsController> paired() async {
      final c = await build(stored: {'steps_enabled': true});
      c.attachAccount(name: 'Alex', avatar: '');
      await c.refresh(force: true);
      cloud.partners.add([const StepPartner(uid: 'sam')]);
      await pumpEventQueue();
      cloud.daysOf('sam').add({
        '2026-10-13': const StepDay(
            dateKey: '2026-10-13', steps: 6000, goal: 6000, name: 'Sam'),
        '2026-10-12': const StepDay(
            dateKey: '2026-10-12', steps: 7000, goal: 6000, name: 'Sam'),
      });
      await pumpEventQueue();
      return c;
    }

    test('their name comes from their own day documents', () async {
      final c = await paired();
      expect(c.partner!.name, 'Sam');
      expect(c.partnerToday!.steps, 6000);
    });

    test('together is both counts against both goals', () async {
      final c = await paired();
      expect(c.togetherSteps, 10600);
      expect(c.togetherGoal, 14000);
    });

    test('the duo streak needs both to have hit their own goal', () async {
      final c = await paired();
      // Today: Sam hit 6000/6000, Alex is at 4600/8000. Yesterday both hit.
      expect(c.duoStreak, 1);
      await c.setGoal(4500);
      expect(c.duoStreak, 2);
    });

    test('unpairing on the other side clears them here', () async {
      final c = await paired();
      cloud.partners.add(const []);
      await pumpEventQueue();
      expect(c.partner, isNull);
      expect(c.partnerToday, isNull);
      expect(c.togetherSteps, c.today.steps);
    });

    test('join normalises the code and rejects the wrong length', () async {
      final c = await build();
      expect(await c.join('abc'), StepJoinResult.notFound);
      expect(cloud.lastCode, isNull);
      expect(await c.join(' abc234 '), StepJoinResult.joined);
      expect(cloud.lastCode, 'ABC234');
    });

    test('cheers are rate-limited', () async {
      final c = await paired();
      expect(await c.sendCheer(StepCheerKind.cheer), isTrue);
      expect(await c.sendCheer(StepCheerKind.nudge), isFalse);
      now = now.add(StepsController.cheerCooldown);
      expect(await c.sendCheer(StepCheerKind.nudge), isTrue);
      expect(cloud.sent, [StepCheerKind.cheer, StepCheerKind.nudge]);
    });

    test('a failed cheer can be retried straight away', () async {
      final c = await paired();
      cloud.failCheer = true;
      expect(await c.sendCheer(StepCheerKind.cheer), isFalse);
      expect(c.canCheer, isTrue);
    });

    test('an incoming cheer is shown once and cleared', () async {
      final c = await paired();
      final shown = <String>[];
      c.onCheer = (kind, name) => shown.add('${kind.name}:$name');

      const cheer =
          StepCheer(id: 'c1', fromUid: 'sam', kind: StepCheerKind.nudge);
      cloud.cheers.add([cheer]);
      cloud.cheers.add([cheer]);
      await pumpEventQueue();

      expect(shown, ['nudge:Sam']);
      expect(cloud.consumed, ['c1']);
    });

    test('a cheer from someone who is not the partner is dropped silently',
        () async {
      final c = await paired();
      var shown = 0;
      c.onCheer = (_, __) => shown++;
      cloud.cheers.add([
        const StepCheer(id: 'x', fromUid: 'ex', kind: StepCheerKind.cheer),
      ]);
      await pumpEventQueue();
      expect(shown, 0);
      expect(cloud.consumed, ['x']);
    });
  });

  test('signing out drops the previous user\'s steps and partner', () async {
    final c = await build(stored: {'steps_enabled': true});
    c.attachAccount(name: 'Alex', avatar: '');
    await c.refresh(force: true);
    cloud.partners.add([const StepPartner(uid: 'sam', name: 'Sam')]);
    await pumpEventQueue();

    await c.detachAccount();

    expect(c.days, isEmpty);
    expect(c.partner, isNull);
    expect(prefs.getString('steps_days_v1'), isNull);
  });
}
