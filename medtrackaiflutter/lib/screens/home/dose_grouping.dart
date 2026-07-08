import '../../providers/app_state.dart';

/// Single source of truth for the day-part time boundaries used by the
/// home timeline (blueprint §3.3 — was duplicated inline across screens).
///
/// Morning 05:00–10:59 · Afternoon 11:00–16:59 · Evening 17:00–20:59 ·
/// Night 21:00–04:59.
class DoseGrouping {
  DoseGrouping._();

  static bool isMorning(int h) => h >= 5 && h < 11;
  static bool isAfternoon(int h) => h >= 11 && h < 17;
  static bool isEvening(int h) => h >= 17 && h < 21;
  static bool isNight(int h) => h >= 21 || h < 5;

  /// Buckets [doses] into named day-part groups, dropping empty groups.
  static List<({String title, List<DoseItem> items})> group(
      List<DoseItem> doses) {
    return [
      (
        title: 'Morning',
        items: doses.where((d) => isMorning(d.sched.h)).toList()
      ),
      (
        title: 'Afternoon',
        items: doses.where((d) => isAfternoon(d.sched.h)).toList()
      ),
      (
        title: 'Evening',
        items: doses.where((d) => isEvening(d.sched.h)).toList()
      ),
      (title: 'Night', items: doses.where((d) => isNight(d.sched.h)).toList()),
    ].where((g) => g.items.isNotEmpty).toList();
  }
}
