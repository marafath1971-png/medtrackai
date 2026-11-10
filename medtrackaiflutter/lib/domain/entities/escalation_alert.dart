/// One missed dose as it moves through a patient's caregiver chain.
///
/// Mirrors a `missedDoseAlerts/{id}` document, which only Cloud Functions
/// write: `detectMissedDoses` creates it when the first caregiver's delay
/// elapses and appends each later caregiver to [alertedUids];
/// `acknowledgeMissedDose` fills the acknowledgment fields.
class EscalationAlert {
  final String id;
  final String patientUid;
  final String displayName;
  final String medName;

  /// Scheduled dose time, "HH:MM" in the patient's local time.
  final String time;

  /// Patient-local date, "YYYY-MM-DD".
  final String dayKey;
  final List<String> alertedUids;
  final String? acknowledgedBy;
  final String? acknowledgedByName;

  const EscalationAlert({
    required this.id,
    required this.patientUid,
    required this.displayName,
    required this.medName,
    required this.time,
    required this.dayKey,
    required this.alertedUids,
    this.acknowledgedBy,
    this.acknowledgedByName,
  });

  bool get isAcknowledged => (acknowledgedBy ?? '').isNotEmpty;

  /// How many caregivers the chain has reached so far.
  int get reached => alertedUids.length;

  factory EscalationAlert.fromMap(String id, Map<String, dynamic> j) {
    String str(Object? v, String fallback) =>
        v is String && v.isNotEmpty ? v : fallback;
    return EscalationAlert(
      id: id,
      patientUid: str(j['patientUid'], ''),
      displayName: str(j['displayName'], 'Someone you care for'),
      medName: str(j['medName'], 'a medication'),
      time: str(j['time'], ''),
      dayKey: str(j['dayKey'], ''),
      alertedUids:
          (j['alertedUids'] as List? ?? const []).whereType<String>().toList(),
      acknowledgedBy: j['acknowledgedBy'] as String?,
      acknowledgedByName: j['acknowledgedByName'] as String?,
    );
  }

  /// Alerts worth showing a caregiver: today's and yesterday's, open ones
  /// first, then latest dose first.
  ///
  /// [today] is the caregiver's local date. The patient's `dayKey` is in the
  /// patient's local time, so across time zones an alert can be dated a day
  /// either side of the caregiver's; yesterday is kept for that reason and
  /// because a late-evening miss is still relevant the next morning.
  static List<EscalationAlert> relevant(
      List<EscalationAlert> all, DateTime today) {
    String key(DateTime d) => d.toIso8601String().substring(0, 10);
    final keep = {
      key(today),
      key(today.subtract(const Duration(days: 1))),
      key(today.add(const Duration(days: 1))),
    };
    final list = all.where((a) => keep.contains(a.dayKey)).toList()
      ..sort((a, b) {
        if (a.isAcknowledged != b.isAcknowledged) {
          return a.isAcknowledged ? 1 : -1;
        }
        final byDay = b.dayKey.compareTo(a.dayKey);
        return byDay != 0 ? byDay : b.time.compareTo(a.time);
      });
    return list;
  }
}
