import 'package:flutter_test/flutter_test.dart';
import 'package:medai/services/notification_service.dart';

/// `nextOccurrence` was extracted out of `scheduleWeeklyReminder` so the budget
/// planner and the scheduler agree on exactly when a dose lands. These pin the
/// original date arithmetic so the extraction cannot have changed behaviour.
///
/// The app's day index is 0 = Sunday, matching `ScheduleEntry.days`.
void main() {
  // Friday 2026-08-07, 08:00.
  final friday = DateTime(2026, 8, 7, 8, 0);

  group('nextOccurrence', () {
    test('a later slot today stays today', () {
      final result = NotificationService.nextOccurrence(
        dayIdx: 5, // Friday
        hour: 20,
        minute: 0,
        now: friday,
      );

      expect(result, DateTime(2026, 8, 7, 20, 0));
    });

    test('a slot that already passed today rolls to next week', () {
      final result = NotificationService.nextOccurrence(
        dayIdx: 5, // Friday
        hour: 6,
        minute: 0,
        now: friday,
      );

      expect(result, DateTime(2026, 8, 14, 6, 0));
    });

    test('a slot already taken today rolls to next week', () {
      final result = NotificationService.nextOccurrence(
        dayIdx: 5,
        hour: 20,
        minute: 0,
        isTakenToday: true,
        now: friday,
      );

      expect(result, DateTime(2026, 8, 14, 20, 0));
    });

    test('finds the next matching weekday later this week', () {
      final result = NotificationService.nextOccurrence(
        dayIdx: 0, // Sunday
        hour: 9,
        minute: 30,
        now: friday,
      );

      expect(result, DateTime(2026, 8, 9, 9, 30));
    });

    test('wraps to next week for a weekday already past', () {
      final result = NotificationService.nextOccurrence(
        dayIdx: 1, // Monday
        hour: 9,
        minute: 0,
        now: friday,
      );

      expect(result, DateTime(2026, 8, 10, 9, 0));
    });

    test('never returns a past instant', () {
      for (var day = 0; day < 7; day++) {
        for (final hour in [0, 8, 23]) {
          final result = NotificationService.nextOccurrence(
            dayIdx: day,
            hour: hour,
            minute: 0,
            now: friday,
          );
          expect(result.isBefore(friday), isFalse,
              reason: 'day $day at $hour:00 resolved to a past instant');
        }
      }
    });

    test('a slot falling exactly on now is left as-is', () {
      // Pre-existing behaviour, preserved by the extraction: the roll-forward
      // checks isBefore, so an exact match is treated as still upcoming. Only
      // reachable on a to-the-millisecond collision, hence left alone rather
      // than "fixed" under a refactor.
      final result = NotificationService.nextOccurrence(
        dayIdx: 5, // Friday, the same weekday as `friday`
        hour: 8,
        minute: 0,
        now: friday,
      );

      expect(result, friday);
    });

    test('never schedules more than a week out', () {
      for (var day = 0; day < 7; day++) {
        final result = NotificationService.nextOccurrence(
          dayIdx: day,
          hour: 12,
          minute: 0,
          now: friday,
        );
        expect(result.difference(friday).inDays, lessThanOrEqualTo(7));
      }
    });
  });
}
