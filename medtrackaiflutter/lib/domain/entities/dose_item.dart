import 'medicine.dart';

class DoseItem {
  final Medicine med;
  final ScheduleEntry sched;
  final String key;

  DoseItem({
    required this.med,
    required this.sched,
    required this.key,
  });

  /// Canonical key format for dose tracking across state and persistence
  static String buildKey(int medId, String label) => '$medId-$label';
}
