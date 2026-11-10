import '../../domain/entities/step_day.dart';

/// Milestones a walker can earn. Order is display order.
enum StepBadge {
  firstGoal,
  tenK,
  streak3,
  streak7,
  marathonWeek,
  duoDay,
  duoStreak3,
}

/// Pure step arithmetic: no clock, no plugins, no storage — so every number
/// the steps screen shows can be tested without a device.
abstract final class StepMath {
  static const int defaultGoal = 8000;
  static const int minGoal = 1000;
  static const int maxGoal = 40000;
  static const int goalIncrement = 500;

  /// A brisk walk is about 100 steps a minute; used to turn "steps to go"
  /// into "minutes of walking".
  static const int stepsPerWalkingMinute = 100;

  /// An hour counts as active from 250 steps, the usual "did you move this
  /// hour" threshold.
  static const int activeHourThreshold = 250;

  /// 42.195 km at an average stride is roughly 55,000 steps.
  static const int marathonSteps = 55000;

  static String dateKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  /// The [count] days ending on [today], oldest first.
  ///
  /// Built with the day-of-month constructor rather than by subtracting
  /// 24-hour durations, which lands on the wrong date across a DST change.
  static List<DateTime> lastDays(DateTime today, int count) => [
        for (var i = count - 1; i >= 0; i--)
          DateTime(today.year, today.month, today.day - i),
      ];

  static int clampGoal(int goal) {
    final snapped = (goal / goalIncrement).round() * goalIncrement;
    return snapped.clamp(minGoal, maxGoal);
  }

  // ── Estimates ──────────────────────────────────────────────────────────

  /// Stride from height (0.415 × height), or the population average when the
  /// profile has no usable height.
  static double strideMeters(double? heightCm) {
    if (heightCm == null || heightCm < 100 || heightCm > 230) return 0.762;
    return heightCm * 0.415 / 100;
  }

  static double distanceKm(int steps, {double? heightCm}) =>
      steps * strideMeters(heightCm) / 1000;

  /// About 0.04 kcal per step at 70 kg, scaled by body weight.
  static int kcal(int steps, {double? weightKg}) {
    final w =
        (weightKg == null || weightKg < 30 || weightKg > 250) ? 70.0 : weightKg;
    return (steps * w * 0.00057).round();
  }

  /// Reads a free-text profile height ("172", "172 cm", "5'8") as centimetres.
  static double? parseHeightCm(String raw) {
    final s = raw.trim().toLowerCase();
    if (s.isEmpty) return null;
    final feet = RegExp(r"^(\d)\s*(?:'|ft|feet)\s*(\d{1,2})?").firstMatch(s);
    if (feet != null) {
      final ft = int.parse(feet.group(1)!);
      final inch = int.tryParse(feet.group(2) ?? '') ?? 0;
      return (ft * 12 + inch) * 2.54;
    }
    final n = double.tryParse(RegExp(r'\d+(\.\d+)?').stringMatch(s) ?? '');
    if (n == null) return null;
    if (s.contains('in')) return n * 2.54;
    if (n < 3) return n * 100; // metres
    return n;
  }

  /// Reads a free-text profile weight ("70", "70kg", "154 lb") as kilograms.
  static double? parseWeightKg(String raw) {
    final s = raw.trim().toLowerCase();
    if (s.isEmpty) return null;
    final n = double.tryParse(RegExp(r'\d+(\.\d+)?').stringMatch(s) ?? '');
    if (n == null) return null;
    if (s.contains('lb') || s.contains('pound')) return n * 0.45359237;
    return n;
  }

  static int walkMinutesFor(int steps) =>
      steps <= 0 ? 0 : (steps / stepsPerWalkingMinute).ceil();

  // ── Today ──────────────────────────────────────────────────────────────

  static int activeHours(List<int> hourly) =>
      hourly.where((h) => h >= activeHourThreshold).length;

  /// The hour with the most steps, or null on a day with none.
  static int? peakHour(List<int> hourly) {
    int? best;
    var bestSteps = 0;
    for (var h = 0; h < hourly.length; h++) {
      if (hourly[h] > bestSteps) {
        bestSteps = hourly[h];
        best = h;
      }
    }
    return best;
  }

  // ── History ────────────────────────────────────────────────────────────

  /// Consecutive goal days ending today.
  ///
  /// Today only counts once its goal is met, but an unfinished today does not
  /// break the run — at 9am nobody has walked 8,000 steps, and showing a
  /// streak of 0 until they do would erase it every morning.
  static int goalStreak(Map<String, StepDay> days, DateTime today) =>
      _streak(today, (key) => days[key]?.goalMet ?? false);

  /// Consecutive days on which both walkers met their own goal.
  static int duoStreak(
    Map<String, StepDay> mine,
    Map<String, StepDay> partner,
    DateTime today,
  ) =>
      _streak(
        today,
        (key) =>
            (mine[key]?.goalMet ?? false) && (partner[key]?.goalMet ?? false),
      );

  static int _streak(DateTime today, bool Function(String key) hit) {
    var streak = 0;
    for (var i = 0; i < 400; i++) {
      final day = DateTime(today.year, today.month, today.day - i);
      if (hit(dateKey(day))) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    return streak;
  }

  static int totalSteps(Iterable<StepDay> days) =>
      days.fold(0, (sum, d) => sum + d.steps);

  /// Mean over the days that have any steps; a day the phone recorded nothing
  /// is missing data, not a rest day, and would drag the average down.
  static int averageSteps(Iterable<StepDay> days) {
    final counted = days.where((d) => d.steps > 0).toList();
    if (counted.isEmpty) return 0;
    return (totalSteps(counted) / counted.length).round();
  }

  static StepDay? bestDay(Iterable<StepDay> days) {
    StepDay? best;
    for (final d in days) {
      if (d.steps > 0 && (best == null || d.steps > best.steps)) best = d;
    }
    return best;
  }

  /// Days of the last week each walker out-stepped the other. Days where
  /// either side has no data are not scored.
  static ({int mine, int partner}) weekWins(
    Map<String, StepDay> mine,
    Map<String, StepDay> partner,
    DateTime today,
  ) {
    var a = 0, b = 0;
    for (final day in lastDays(today, 7)) {
      final key = dateKey(day);
      final m = mine[key]?.steps ?? 0;
      final p = partner[key]?.steps ?? 0;
      if (m == 0 || p == 0 || m == p) continue;
      if (m > p) {
        a++;
      } else {
        b++;
      }
    }
    return (mine: a, partner: b);
  }

  static Set<StepBadge> badges({
    required Map<String, StepDay> mine,
    required Map<String, StepDay> partner,
    required DateTime today,
  }) {
    final earned = <StepBadge>{};
    if (mine.values.any((d) => d.goalMet)) earned.add(StepBadge.firstGoal);
    if (mine.values.any((d) => d.steps >= 10000)) earned.add(StepBadge.tenK);

    final best = longestGoalRun(mine);
    if (best >= 3) earned.add(StepBadge.streak3);
    if (best >= 7) earned.add(StepBadge.streak7);

    final week = lastDays(today, 7).map((d) => mine[dateKey(d)]).nonNulls;
    if (totalSteps(week) >= marathonSteps) earned.add(StepBadge.marathonWeek);

    final duoDays = mine.keys
        .where((k) => mine[k]!.goalMet && (partner[k]?.goalMet ?? false))
        .toSet();
    if (duoDays.isNotEmpty) earned.add(StepBadge.duoDay);
    if (_longestRun(duoDays) >= 3) earned.add(StepBadge.duoStreak3);
    return earned;
  }

  static int longestGoalRun(Map<String, StepDay> days) => _longestRun(
      days.entries.where((e) => e.value.goalMet).map((e) => e.key).toSet());

  static int _longestRun(Set<String> hitKeys) {
    var best = 0;
    for (final key in hitKeys) {
      final d = DateTime.tryParse(key);
      if (d == null) continue;
      // Only count from the first day of a run.
      if (hitKeys.contains(dateKey(DateTime(d.year, d.month, d.day - 1)))) {
        continue;
      }
      var run = 1;
      while (
          hitKeys.contains(dateKey(DateTime(d.year, d.month, d.day + run)))) {
        run++;
      }
      if (run > best) best = run;
    }
    return best;
  }

  /// 12345 -> "12,345". Grouping is locale-neutral on purpose: the widget and
  /// the app must print the same string.
  static String format(int n) {
    final s = n.abs().toString();
    final out = StringBuffer(n < 0 ? '-' : '');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
      out.write(s[i]);
    }
    return out.toString();
  }
}
