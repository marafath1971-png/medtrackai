/// iOS keeps at most 64 *pending* local notifications per app. Anything beyond
/// that is dropped silently — no error, no callback — and because iOS keeps the
/// 64 soonest, the ones lost are the furthest out. For a medication app that
/// means later-week dose reminders simply never fire.
///
/// The weekly schedule requests up to three notifications per dose occurrence
/// (the reminder, a streak nudge, and a caregiver escalation) across 7 days, so
/// the cap is reached quickly: 3 medicines at one dose a day already exceeds it.
/// This planner decides what fits.
library;

/// Apple's documented per-app limit on pending local notifications.
const int kIosPendingNotificationLimit = 64;

/// Headroom left for notifications scheduled outside the weekly dose loop —
/// the morning summary, the re-engagement nudge, snoozes, and refill alerts —
/// so the dose loop cannot consume the entire allowance.
const int kReservedNotificationSlots = 4;

/// What a scheduled notification is for. Order defines what survives when the
/// budget runs out: a dose reminder is the product's core promise, whereas a
/// streak nudge is motivational garnish.
enum NotificationKind {
  /// "Time to take X" — never dropped while any budget remains.
  doseReminder,

  /// Escalation to a caregiver when a dose looks missed. Safety-relevant, so
  /// it outranks motivation but yields to the reminder itself.
  caregiverEscalation,

  /// Streak encouragement. Purely motivational; first to go.
  streakNudge,
}

/// A single notification the weekly scheduler would like to post.
class PlannedNotification {
  final NotificationKind kind;
  final DateTime scheduledDate;

  /// Identifies the dose occurrence this belongs to, so a kind can be dropped
  /// without disturbing the reminder it accompanies.
  final int notifId;

  const PlannedNotification({
    required this.kind,
    required this.scheduledDate,
    required this.notifId,
  });
}

/// Selects which of [candidates] to actually schedule under [limit].
///
/// Selection is by urgency first and importance second: candidates are ordered
/// by kind (reminders, then escalations, then nudges) and, within a kind, by
/// how soon they fire. That ordering matters — taking simply the 64 soonest
/// would let a burst of day-one nudges crowd out day-six dose reminders, which
/// is the exact failure the cap already causes.
///
/// The result is returned in chronological order so scheduling reads naturally.
/// Candidates already in the past are discarded; [now] is injectable for tests.
List<PlannedNotification> planNotifications(
  List<PlannedNotification> candidates, {
  int limit = kIosPendingNotificationLimit - kReservedNotificationSlots,
  DateTime? now,
}) {
  if (limit <= 0) return const [];

  final cutoff = now ?? DateTime.now();
  final upcoming =
      candidates.where((c) => c.scheduledDate.isAfter(cutoff)).toList()
        ..sort((a, b) {
          final byKind = a.kind.index.compareTo(b.kind.index);
          if (byKind != 0) return byKind;
          return a.scheduledDate.compareTo(b.scheduledDate);
        });

  final selected = upcoming.take(limit).toList()
    ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

  return selected;
}

/// True when [candidates] cannot fit under [limit] — i.e. the user's regimen is
/// large enough that some notifications will be dropped. Callers use this to
/// decide whether the shortened horizon is worth surfacing.
bool exceedsBudget(
  List<PlannedNotification> candidates, {
  int limit = kIosPendingNotificationLimit - kReservedNotificationSlots,
  DateTime? now,
}) {
  final cutoff = now ?? DateTime.now();
  return candidates.where((c) => c.scheduledDate.isAfter(cutoff)).length >
      limit;
}

/// The date after which no dose reminder could be scheduled, or null when
/// everything fit. This is how far ahead reminders are actually guaranteed —
/// worth telling the user about rather than letting reminders quietly stop.
DateTime? reminderHorizon(List<PlannedNotification> selected) {
  final reminders = selected
      .where((n) => n.kind == NotificationKind.doseReminder)
      .map((n) => n.scheduledDate)
      .toList()
    ..sort();
  return reminders.isEmpty ? null : reminders.last;
}
