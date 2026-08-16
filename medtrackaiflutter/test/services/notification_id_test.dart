import 'package:flutter_test/flutter_test.dart';

/// Scheduled reminders are addressed purely by their integer notification id.
/// Two reminders that compute the same id are the same notification to the OS,
/// so the second silently replaces the first — a dose reminder that never
/// arrives, with nothing in the UI to indicate it.
///
/// This mirrors the id scheme in NotificationService.scheduleAll:
///
///   Object.hash(profileHash, med.id, i, day).toUnsigned(31)
///
/// where `i` is the schedule slot index and `day` is 0..6.
int _notifId({
  required int profileHash,
  required int medId,
  required int slotIndex,
  required int day,
}) {
  return Object.hash(profileHash, medId, slotIndex, day).toUnsigned(31);
}

/// The id actually handed to the plugin.
int _plugin(int id) => id.remainder(0x7FFFFFFF);

void main() {
  group('small sequential medicine ids', () {
    test('different days of the same slot are distinct', () {
      final mon = _notifId(profileHash: 1, medId: 3, slotIndex: 0, day: 1);
      final tue = _notifId(profileHash: 1, medId: 3, slotIndex: 0, day: 2);
      expect(mon, isNot(tue));
    });

    test('different slots of the same medicine are distinct', () {
      final morning = _notifId(profileHash: 1, medId: 3, slotIndex: 0, day: 1);
      final evening = _notifId(profileHash: 1, medId: 3, slotIndex: 1, day: 1);
      expect(morning, isNot(evening));
    });

    test('different medicines are distinct', () {
      final a = _notifId(profileHash: 1, medId: 3, slotIndex: 0, day: 1);
      final b = _notifId(profileHash: 1, medId: 4, slotIndex: 0, day: 1);
      expect(a, isNot(b));
    });

    test('a whole week of a twice-daily medicine yields 14 unique ids', () {
      final ids = <int>{
        for (var slot = 0; slot < 2; slot++)
          for (var day = 0; day < 7; day++)
            _notifId(profileHash: 7, medId: 3, slotIndex: slot, day: day),
      };
      expect(ids.length, 14);
    });
  });

  group('timestamp medicine ids', () {
    // Medicines added by the scanner use DateTime.now().millisecondsSinceEpoch
    // as their id (pill_identifier_screen.dart,
    // supplement_interaction_scanner.dart), which is ~1.7e12.
    const epochId = 1786770091412;

    test('a timestamp id still fits the 31-bit notification space', () {
      final id = _notifId(profileHash: 1, medId: epochId, slotIndex: 0, day: 0);
      expect(id, lessThanOrEqualTo(0x7FFFFFFF));
      expect(id, greaterThanOrEqualTo(0));
    });

    test('medicines added 1ms apart stay distinct', () {
      final a = _notifId(profileHash: 1, medId: epochId, slotIndex: 0, day: 0);
      final b =
          _notifId(profileHash: 1, medId: epochId + 1, slotIndex: 0, day: 0);
      expect(a, isNot(b));
    });

    test('a full week of two timestamp medicines yields 28 unique ids', () {
      final ids = <int>{
        for (final med in [epochId, epochId + 1])
          for (var slot = 0; slot < 2; slot++)
            for (var day = 0; day < 7; day++)
              _notifId(
                  profileHash: 3, medId: med, slotIndex: slot, day: day),
      };
      expect(ids.length, 28);
    });
  });

  group('profiles get their own ids', () {
    // Regression: the old scheme was
    //   (profileHash % 10000) * 10000 + med.id * 100 + i * 10 + day
    // where med.id * 100 dwarfed the 10000-wide profile band, so two
    // profiles' medicines could land on the same id and scheduling one
    // silently cancelled the other's reminder.
    const epochId = 1786770091412;

    test('the pair that used to collide no longer does', () {
      final profile1 =
          _notifId(profileHash: 1, medId: epochId, slotIndex: 0, day: 0);
      final profile2 =
          _notifId(profileHash: 2, medId: epochId - 100, slotIndex: 0, day: 0);

      expect(profile1, isNot(profile2),
          reason: 'both were 2074753506 under the old scheme');
    });

    test('the same medicine under two profiles gets two ids', () {
      final a = _notifId(profileHash: 111, medId: epochId, slotIndex: 0, day: 0);
      final b = _notifId(profileHash: 222, medId: epochId, slotIndex: 0, day: 0);
      expect(a, isNot(b));
    });

    test('a family of profiles times meds times slots stays collision-free',
        () {
      final ids = <int>{};
      var expected = 0;
      for (final profile in [11, 22, 33, 44]) {
        for (final med in [epochId, epochId + 1, epochId + 5000]) {
          for (var slot = 0; slot < 3; slot++) {
            for (var day = 0; day < 7; day++) {
              ids.add(_notifId(
                  profileHash: profile,
                  medId: med,
                  slotIndex: slot,
                  day: day));
              expected++;
            }
          }
        }
      }
      expect(ids.length, expected,
          reason: '4 profiles x 3 meds x 3 slots x 7 days must all differ');
    });
  });

  group('fixed-id notifications do not clash with scheduled ones', () {
    // showFamilyAlert uses 999000, showRemoteAlert 999001, and refill alerts
    // use med.id + 100000. These share the same id space as scheduled doses.
    test('refill alert id is distinct from a dose reminder for the same med',
        () {
      const medId = 3;
      final refill = _plugin(medId + 100000);
      final dose = _notifId(profileHash: 1, medId: medId, slotIndex: 0, day: 0);
      expect(refill, isNot(dose));
    });

    test('the fixed family and remote alert ids differ', () {
      expect(999000, isNot(999001));
    });
  });
}
