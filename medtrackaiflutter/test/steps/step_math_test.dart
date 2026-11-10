import 'package:flutter_test/flutter_test.dart';
import 'package:medai/core/utils/step_math.dart';
import 'package:medai/domain/entities/step_day.dart';

StepDay _day(String key, int steps, {int goal = 8000}) =>
    StepDay(dateKey: key, steps: steps, goal: goal);

Map<String, StepDay> _days(Map<String, int> steps, {int goal = 8000}) =>
    {for (final e in steps.entries) e.key: _day(e.key, e.value, goal: goal)};

void main() {
  final today = DateTime(2026, 10, 13);

  group('dates', () {
    test('keys are zero-padded and sortable', () {
      expect(StepMath.dateKey(DateTime(2026, 3, 5)), '2026-03-05');
    });

    test('lastDays crosses a month boundary, oldest first', () {
      final days = StepMath.lastDays(DateTime(2026, 3, 2), 4)
          .map(StepMath.dateKey)
          .toList();
      expect(days, ['2026-02-27', '2026-02-28', '2026-03-01', '2026-03-02']);
    });

    test('lastDays does not skip or repeat a day across DST', () {
      // US clocks went back on 2026-11-01; subtracting 24h durations from
      // midnight lands on 23:00 the day before and repeats a date.
      final keys = StepMath.lastDays(DateTime(2026, 11, 3), 5)
          .map(StepMath.dateKey)
          .toSet();
      expect(keys.length, 5);
    });
  });

  group('goal', () {
    test('snaps to 500s and stays in range', () {
      expect(StepMath.clampGoal(7740), 7500);
      expect(StepMath.clampGoal(7760), 8000);
      expect(StepMath.clampGoal(10), StepMath.minGoal);
      expect(StepMath.clampGoal(999999), StepMath.maxGoal);
    });
  });

  group('estimates', () {
    test('distance uses height when it is plausible', () {
      expect(StepMath.distanceKm(10000), closeTo(7.62, 0.01));
      expect(StepMath.distanceKm(10000, heightCm: 180), closeTo(7.47, 0.01));
      // Nonsense heights fall back to the average instead of producing a
      // 40 km walk.
      expect(StepMath.distanceKm(10000, heightCm: 1000), closeTo(7.62, 0.01));
    });

    test('energy scales with weight', () {
      expect(StepMath.kcal(10000), 399);
      expect(StepMath.kcal(10000, weightKg: 90), greaterThan(399));
      expect(StepMath.kcal(0), 0);
    });

    test('profile height and weight are read in common formats', () {
      expect(StepMath.parseHeightCm('172'), 172);
      expect(StepMath.parseHeightCm('172 cm'), 172);
      expect(StepMath.parseHeightCm('1.72'), closeTo(172, 0.01));
      expect(StepMath.parseHeightCm("5'8"), closeTo(172.72, 0.01));
      expect(StepMath.parseHeightCm(''), isNull);
      expect(StepMath.parseWeightKg('70kg'), 70);
      expect(StepMath.parseWeightKg('154 lb'), closeTo(69.85, 0.01));
      expect(StepMath.parseWeightKg('n/a'), isNull);
    });

    test('steps to go become minutes of walking, rounded up', () {
      expect(StepMath.walkMinutesFor(0), 0);
      expect(StepMath.walkMinutesFor(1), 1);
      expect(StepMath.walkMinutesFor(2140), 22);
    });
  });

  group('today', () {
    test('active hours and the peak hour', () {
      final hourly = List.filled(24, 0);
      hourly[8] = 900;
      hourly[13] = 249;
      hourly[18] = 2100;
      expect(StepMath.activeHours(hourly), 2);
      expect(StepMath.peakHour(hourly), 18);
      expect(StepMath.peakHour(List.filled(24, 0)), isNull);
    });
  });

  group('streak', () {
    test('counts back from today', () {
      final days = _days({
        '2026-10-13': 9000,
        '2026-10-12': 8000,
        '2026-10-11': 8200,
        '2026-10-10': 100,
        '2026-10-09': 9999,
      });
      expect(StepMath.goalStreak(days, today), 3);
    });

    test('an unfinished today does not erase the streak', () {
      final days = _days({
        '2026-10-13': 1200,
        '2026-10-12': 8000,
        '2026-10-11': 8200,
      });
      expect(StepMath.goalStreak(days, today), 2);
    });

    test('a missed yesterday ends it', () {
      final days = _days({'2026-10-13': 500, '2026-10-11': 9000});
      expect(StepMath.goalStreak(days, today), 0);
    });

    test('each day is judged against its own goal', () {
      final days = {
        '2026-10-13': _day('2026-10-13', 6000, goal: 5000),
        '2026-10-12': _day('2026-10-12', 6000, goal: 10000),
      };
      expect(StepMath.goalStreak(days, today), 1);
    });

    test('the duo streak needs both walkers', () {
      final mine = _days({'2026-10-13': 9000, '2026-10-12': 9000});
      final theirs = _days({'2026-10-13': 9000, '2026-10-12': 10});
      expect(StepMath.duoStreak(mine, theirs, today), 1);
      expect(StepMath.duoStreak(mine, const {}, today), 0);
    });
  });

  group('history', () {
    test('the average ignores days with no data', () {
      final days = _days({'a': 6000, 'b': 0, 'c': 8000}).values;
      expect(StepMath.averageSteps(days), 7000);
      expect(StepMath.averageSteps(const []), 0);
    });

    test('week wins skip days either side has no data', () {
      final mine = _days({
        '2026-10-13': 9000,
        '2026-10-12': 2000,
        '2026-10-11': 5000,
        '2026-10-10': 5000,
      });
      final theirs = _days({
        '2026-10-13': 4000,
        '2026-10-12': 7000,
        '2026-10-10': 5000,
      });
      expect(StepMath.weekWins(mine, theirs, today), (mine: 1, partner: 1));
    });
  });

  group('badges', () {
    test('nothing is earned from nothing', () {
      expect(
        StepMath.badges(mine: const {}, partner: const {}, today: today),
        isEmpty,
      );
    });

    test('streak badges come from the longest run, not the current one', () {
      final mine = _days({
        '2026-10-01': 9000,
        '2026-10-02': 9000,
        '2026-10-03': 9000,
        '2026-10-13': 100,
      });
      final earned =
          StepMath.badges(mine: mine, partner: const {}, today: today);
      expect(earned, contains(StepBadge.firstGoal));
      expect(earned, contains(StepBadge.streak3));
      expect(earned, isNot(contains(StepBadge.streak7)));
      expect(earned, isNot(contains(StepBadge.tenK)));
    });

    test('duo badges need a partner who also hit their goal', () {
      final mine = _days({'2026-10-13': 12000});
      final theirs = _days({'2026-10-13': 8000});
      final earned = StepMath.badges(mine: mine, partner: theirs, today: today);
      expect(earned, containsAll([StepBadge.tenK, StepBadge.duoDay]));
      expect(earned, isNot(contains(StepBadge.duoStreak3)));
    });

    test('a marathon week is 55,000 steps in the last seven days', () {
      final mine = _days({
        for (var d = 7; d <= 13; d++)
          '2026-10-${d.toString().padLeft(2, '0')}': 8000,
      });
      expect(
        StepMath.badges(mine: mine, partner: const {}, today: today),
        contains(StepBadge.marathonWeek),
      );
    });
  });

  test('numbers are grouped in threes', () {
    expect(StepMath.format(0), '0');
    expect(StepMath.format(999), '999');
    expect(StepMath.format(1000), '1,000');
    expect(StepMath.format(1234567), '1,234,567');
  });
}
