import 'package:flutter_test/flutter_test.dart';
import 'package:medai/services/notification_budget.dart';

/// iOS silently drops pending local notifications beyond 64, keeping the
/// soonest. The weekly scheduler requests up to three per dose occurrence
/// across seven days, so a realistic regimen blows past the cap and the
/// casualties are later-week dose reminders — the one thing a medication app
/// cannot afford to lose.
///
/// These pin the rule that decides what survives.
void main() {
  final now = DateTime(2026, 8, 7, 8, 0);

  PlannedNotification at(
    NotificationKind kind,
    Duration fromNow, {
    int id = 1,
  }) =>
      PlannedNotification(
        kind: kind,
        scheduledDate: now.add(fromNow),
        notifId: id,
      );

  group('planNotifications', () {
    test('returns everything when the regimen fits', () {
      final candidates = [
        at(NotificationKind.doseReminder, const Duration(hours: 1)),
        at(NotificationKind.streakNudge, const Duration(hours: 2)),
        at(NotificationKind.caregiverEscalation, const Duration(hours: 3)),
      ];

      expect(planNotifications(candidates, limit: 10, now: now).length, 3);
    });

    test('drops streak nudges before dose reminders', () {
      final candidates = [
        // The nudge fires sooner, so a naive "keep the soonest" rule would
        // retain it and drop the reminder.
        at(NotificationKind.streakNudge, const Duration(hours: 1), id: 1),
        at(NotificationKind.doseReminder, const Duration(hours: 5), id: 2),
      ];

      final selected = planNotifications(candidates, limit: 1, now: now);

      expect(selected.single.kind, NotificationKind.doseReminder);
    });

    test('drops motivational nudges before caregiver escalations', () {
      final candidates = [
        at(NotificationKind.streakNudge, const Duration(hours: 1), id: 1),
        at(NotificationKind.caregiverEscalation, const Duration(hours: 5),
            id: 2),
      ];

      final selected = planNotifications(candidates, limit: 1, now: now);

      expect(selected.single.kind, NotificationKind.caregiverEscalation);
    });

    test('keeps the soonest reminders when reminders alone exceed the cap', () {
      final candidates = List.generate(
        10,
        (i) => at(NotificationKind.doseReminder, Duration(days: i, hours: 1),
            id: i),
      );

      final selected = planNotifications(candidates, limit: 3, now: now);

      expect(selected.length, 3);
      expect(selected.map((e) => e.notifId), [0, 1, 2],
          reason: 'the three soonest doses must be the ones that survive');
    });

    test('every dose reminder survives while any budget remains', () {
      // 7 reminders + 7 nudges + 7 escalations, budget for only 8.
      final candidates = <PlannedNotification>[];
      for (var i = 0; i < 7; i++) {
        candidates
          ..add(at(NotificationKind.doseReminder, Duration(days: i, hours: 1),
              id: i))
          ..add(at(NotificationKind.streakNudge, Duration(days: i, hours: 2),
              id: i))
          ..add(at(
              NotificationKind.caregiverEscalation, Duration(days: i, hours: 3),
              id: i));
      }

      final selected = planNotifications(candidates, limit: 8, now: now);
      final reminders =
          selected.where((n) => n.kind == NotificationKind.doseReminder);

      expect(reminders.length, 7,
          reason: 'all 7 dose reminders fit before any extra is scheduled');
      expect(selected.length, 8);
    });

    test('discards candidates already in the past', () {
      final candidates = [
        at(NotificationKind.doseReminder, const Duration(hours: -2)),
        at(NotificationKind.doseReminder, const Duration(hours: 2)),
      ];

      expect(planNotifications(candidates, limit: 10, now: now).length, 1);
    });

    test('returns results in chronological order', () {
      final candidates = [
        at(NotificationKind.caregiverEscalation, const Duration(hours: 3)),
        at(NotificationKind.doseReminder, const Duration(hours: 1)),
        at(NotificationKind.streakNudge, const Duration(hours: 2)),
      ];

      final selected = planNotifications(candidates, limit: 10, now: now);
      final dates = selected.map((e) => e.scheduledDate).toList();

      expect(dates, equals([...dates]..sort()));
    });

    test('a zero or negative budget schedules nothing', () {
      final candidates = [
        at(NotificationKind.doseReminder, const Duration(hours: 1)),
      ];

      expect(planNotifications(candidates, limit: 0, now: now), isEmpty);
    });
  });

  group('exceedsBudget', () {
    test('is false when everything fits', () {
      final candidates = [
        at(NotificationKind.doseReminder, const Duration(hours: 1)),
      ];

      expect(exceedsBudget(candidates, limit: 5, now: now), isFalse);
    });

    test('is true once the regimen outgrows the allowance', () {
      final candidates = List.generate(
        6,
        (i) => at(NotificationKind.doseReminder, Duration(days: i, hours: 1),
            id: i),
      );

      expect(exceedsBudget(candidates, limit: 5, now: now), isTrue);
    });

    test('past candidates do not count against the budget', () {
      final candidates = [
        at(NotificationKind.doseReminder, const Duration(days: -1), id: 1),
        at(NotificationKind.doseReminder, const Duration(days: 1), id: 2),
      ];

      expect(exceedsBudget(candidates, limit: 1, now: now), isFalse);
    });
  });

  group('reminderHorizon', () {
    test('reports the furthest reminder that fit', () {
      final selected = [
        at(NotificationKind.doseReminder, const Duration(days: 1)),
        at(NotificationKind.doseReminder, const Duration(days: 3)),
        // A later escalation must not be mistaken for reminder coverage.
        at(NotificationKind.caregiverEscalation, const Duration(days: 9)),
      ];

      expect(reminderHorizon(selected), now.add(const Duration(days: 3)));
    });

    test('is null when no reminders were scheduled', () {
      expect(reminderHorizon([]), isNull);
      expect(
        reminderHorizon(
            [at(NotificationKind.streakNudge, const Duration(days: 1))]),
        isNull,
      );
    });
  });

  group('regression: the shipped cap', () {
    test('a 5-med twice-daily week is truncated, not silently dropped', () {
      // 5 meds x 2 doses x 7 days x 3 notification kinds = 210 requests.
      final candidates = <PlannedNotification>[];
      var id = 0;
      for (var med = 0; med < 5; med++) {
        for (var slot = 0; slot < 2; slot++) {
          for (var day = 0; day < 7; day++) {
            final fire = Duration(days: day, hours: slot * 8 + 1);
            candidates
              ..add(at(NotificationKind.doseReminder, fire, id: id))
              ..add(at(
                  NotificationKind.streakNudge, fire + const Duration(hours: 1),
                  id: id))
              ..add(at(NotificationKind.caregiverEscalation,
                  fire + const Duration(hours: 2),
                  id: id));
            id++;
          }
        }
      }

      expect(candidates.length, 210);
      expect(exceedsBudget(candidates, now: now), isTrue);

      final selected = planNotifications(candidates, now: now);

      expect(selected.length,
          kIosPendingNotificationLimit - kReservedNotificationSlots);
      expect(selected.length, lessThanOrEqualTo(kIosPendingNotificationLimit));
      // Under the cap, the budget goes to reminders rather than nudges.
      expect(
        selected.every((n) => n.kind == NotificationKind.doseReminder),
        isTrue,
        reason: 'core reminders must consume the budget before extras',
      );
    });
  });
}
