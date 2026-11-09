/// Pure pricing logic for the paywall: plan identity, order, savings and the
/// trial timeline.
///
/// Kept free of the RevenueCat types so it can be tested without a store, and
/// so every number the paywall shows is derived from real store prices rather
/// than typed in — the paywall used to show a hardcoded "Save 58%" and a
/// "Day 5 / Day 7" trial timeline regardless of what the store actually sold.
library;

enum PlanKind { annual, family, monthly, weekly, lifetime, other }

/// Which plan a store package is.
///
/// The Family plan is a RevenueCat custom package, so it cannot be told apart
/// by package type; its identifier carries "family" (e.g. `family_annual`).
/// `isLifetime` / `isAnnual` etc. come from RevenueCat's PackageType.
PlanKind planKindOf({
  required String identifier,
  bool isAnnual = false,
  bool isMonthly = false,
  bool isWeekly = false,
  bool isLifetime = false,
}) {
  if (identifier.toLowerCase().contains('family')) return PlanKind.family;
  if (isAnnual) return PlanKind.annual;
  if (isMonthly) return PlanKind.monthly;
  if (isWeekly) return PlanKind.weekly;
  if (isLifetime) return PlanKind.lifetime;
  return PlanKind.other;
}

/// Display order. Annual leads (it is ~60% of Health & Fitness revenue);
/// Family sits beside it as the step-up; lifetime last so it anchors rather
/// than distracts.
int planRank(PlanKind k) => switch (k) {
      PlanKind.annual => 0,
      PlanKind.family => 1,
      PlanKind.monthly => 2,
      PlanKind.weekly => 3,
      PlanKind.lifetime => 4,
      PlanKind.other => 5,
    };

/// Short plan name for the tile.
String planName(PlanKind k) => switch (k) {
      PlanKind.annual => 'Yearly',
      PlanKind.family => 'Family',
      PlanKind.monthly => 'Monthly',
      PlanKind.weekly => 'Weekly',
      PlanKind.lifetime => 'Lifetime',
      PlanKind.other => 'Plan',
    };

/// "/ year", "/ month", "one-time"…
///
/// [isoPeriod] is the store's ISO-8601 subscription period ("P1Y", "P1M",
/// "P1W"); the Family plan needs it because its package type is custom.
String periodLabel(PlanKind k, {String? isoPeriod}) {
  switch (k) {
    case PlanKind.annual:
      return '/ year';
    case PlanKind.monthly:
      return '/ month';
    case PlanKind.weekly:
      return '/ week';
    case PlanKind.lifetime:
      return 'one-time';
    case PlanKind.family:
    case PlanKind.other:
      final p = (isoPeriod ?? '').toUpperCase();
      if (p.endsWith('Y')) return '/ year';
      if (p.endsWith('M')) return '/ month';
      if (p.endsWith('W')) return '/ week';
      return '';
  }
}

/// Whole-percent saving of the annual price against twelve monthly payments.
///
/// Null when there is no monthly plan to compare with, the prices are not in
/// the same currency, or the saving is too small to be worth claiming — a
/// badge must never assert a saving the store prices do not show.
int? annualSavingsPercent({
  required double annualPrice,
  required double monthlyPrice,
  String? annualCurrency,
  String? monthlyCurrency,
}) {
  if (monthlyPrice <= 0 || annualPrice <= 0) return null;
  if (annualCurrency != null &&
      monthlyCurrency != null &&
      annualCurrency != monthlyCurrency) {
    return null;
  }
  final pct = ((1 - annualPrice / (monthlyPrice * 12)) * 100).floor();
  return pct >= 5 ? pct : null;
}

/// The trial timeline, matched to the real trial length.
///
/// The reminder step is the "trial ends tomorrow" push the paywall schedules
/// for day `days - 1` (see `_scheduleTrialReminder`), so this must say the
/// same day. Empty when there is no free trial: showing a trial timeline on a
/// plan without one misdescribes what the user is buying.
List<(String, String)> trialTimeline(int? days) {
  if (days == null || days < 1) return const [];
  if (days == 2) {
    return [
      ('Today', '2-day free trial begins'),
      ('Tomorrow', 'Reminder before trial ends'),
      ('Day 3', 'Plan begins unless cancelled'),
    ];
  }
  if (days < 2) {
    return [
      ('Today', 'Full Pro access free'),
      ('Day $days', 'Plan begins unless cancelled'),
    ];
  }
  return [
    ('Today', 'Full Pro access free'),
    ('Day ${days - 1}', 'Reminder before trial ends'),
    ('Day $days', 'Plan begins unless cancelled'),
  ];
}
