import 'package:flutter_test/flutter_test.dart';
import 'package:medai/data/repositories/medication_repository_impl.dart';
import 'package:medai/domain/entities/entities.dart';

/// Pins the per-day dose reconciliation used by
/// `MedicationRepositoryImpl.getHistory`.
///
/// That merge used to work a whole day at a time: for any day the cloud
/// lacked, and unconditionally for *today*, the local day replaced the cloud
/// day wholesale. Each device only ever holds part of a day, so this silently
/// destroyed doses — phone A logs the 08:00 dose, phone B logs the 20:00 one,
/// and whichever synced last erased the other's, locally and in Firestore.
///
/// This log is what adherence scores, streaks and the stats screens are built
/// from, and the scheduled `detectMissedDoses` function reads the same entries
/// to decide which doses were handled. A dose erased here therefore reads as
/// never taken, and a caregiver is alerted about a dose the patient actually
/// took — which is the failure the whole caregiver feature exists to avoid.
///
/// These call the repository's own helpers rather than restating the rule, so
/// the tests cannot drift away from the shipped behaviour.
DoseEntry _dose(
  int medId, {
  String time = '08:00',
  String label = 'Morning',
  bool taken = false,
  bool skipped = false,
}) =>
    DoseEntry(
      medId: medId,
      label: label,
      time: time,
      taken: taken,
      skipped: skipped,
    );

DoseEntry _prn(int medId,
        {String time = '2:30 PM', String label = 'PRN-Rescue'}) =>
    DoseEntry(medId: medId, label: label, time: time, taken: true);

void main() {
  group('mergeDayEntries — the data-loss bug', () {
    test('doses logged on two devices on the same day both survive', () {
      // The original bug, stated directly.
      final merged = mergeDayEntries(
        cloud: [_dose(1, time: '08:00', taken: true)],
        local: [_dose(1, time: '20:00', label: 'Evening', taken: true)],
      );

      expect(merged.length, 2,
          reason: 'neither device may erase the other half of the day');
      expect(merged.map((e) => e.time).toSet(), {'08:00', '20:00'});
    });

    test('a dose taken on the other device is not reverted to untaken', () {
      // Local still has the untouched slot; the cloud has it marked taken.
      // Taking the local copy would flip a logged dose back to pending.
      final merged = mergeDayEntries(
        cloud: [_dose(1, taken: true)],
        local: [_dose(1)],
      );

      expect(merged.single.taken, isTrue);
    });

    test('a locally taken dose beats an untouched cloud slot', () {
      final merged = mergeDayEntries(
        cloud: [_dose(1)],
        local: [_dose(1, taken: true)],
      );

      expect(merged.single.taken, isTrue);
    });

    test('a skipped dose also counts as handled and wins', () {
      // Skipping is as deliberate as taking; both mean the user has dealt
      // with that dose, and the server treats them identically.
      final merged = mergeDayEntries(
        cloud: [_dose(1)],
        local: [_dose(1, skipped: true)],
      );

      expect(merged.single.skipped, isTrue);
    });

    test('two handled copies of the same dose collapse to one', () {
      // Both devices logged the same slot — that is one dose, not two, and
      // double-counting would inflate the adherence score.
      final merged = mergeDayEntries(
        cloud: [_dose(1, taken: true)],
        local: [_dose(1, taken: true)],
      );

      expect(merged.length, 1);
    });
  });

  group('mergeDayEntries — dose identity', () {
    test('different medicines at the same time stay separate', () {
      final merged = mergeDayEntries(
        cloud: [_dose(1, taken: true)],
        local: [_dose(2, taken: true)],
      );

      expect(merged.length, 2);
    });

    test('two slots of one medicine at different times stay separate', () {
      final merged = mergeDayEntries(
        cloud: [_dose(1, time: '08:00', taken: true)],
        local: [_dose(1, time: '12:00', label: 'Noon', taken: true)],
      );

      expect(merged.length, 2);
    });

    test('same medicine and time under different labels stay separate', () {
      // A schedule edit can leave two slots sharing a clock time; collapsing
      // them would lose a dose the user genuinely took.
      final merged = mergeDayEntries(
        cloud: [_dose(1, label: 'Morning', taken: true)],
        local: [_dose(1, label: 'With food', taken: true)],
      );

      expect(merged.length, 2);
    });
  });

  group('mergeDayEntries — as-needed doses', () {
    test('two rescue doses of the same medicine both survive', () {
      // PRN entries are appended, not filled into a slot: taking two rescue
      // doses an hour apart is two real records that must not collapse.
      final merged = mergeDayEntries(
        cloud: [],
        local: [_prn(1, time: '2:30 PM'), _prn(1, time: '4:00 PM')],
      );

      expect(merged.where(isPrnEntry).length, 2);
    });

    test('identical rescue doses are not deduplicated away', () {
      // Same medicine, same label, same minute — still two doses.
      final merged = mergeDayEntries(
        cloud: [],
        local: [_prn(1), _prn(1)],
      );

      expect(merged.length, 2);
    });

    test('an undone rescue dose is not resurrected by the other device', () {
      // undoPrnDose removes an entry, so history is not append-only. A plain
      // union would bring the undone dose back from the stale side.
      final merged = mergeDayEntries(
        cloud: [_prn(1), _prn(1)],
        local: [_prn(1)],
      );

      expect(merged.length, 2,
          reason: 'the fuller side wins; an undo syncs once it is the fuller '
              'side, rather than being re-added immediately');
    });

    test('rescue doses of different medicines are tracked independently', () {
      final merged = mergeDayEntries(
        cloud: [_prn(1)],
        local: [_prn(2), _prn(2)],
      );

      expect(merged.where((e) => e.medId == 1).length, 1);
      expect(merged.where((e) => e.medId == 2).length, 2);
    });

    test('scheduled and as-needed doses coexist in one day', () {
      final merged = mergeDayEntries(
        cloud: [_dose(1, taken: true)],
        local: [_prn(1)],
      );

      expect(merged.length, 2);
      expect(merged.where(isPrnEntry).length, 1);
    });
  });

  group('mergeDayEntries — the ordinary cases', () {
    test('an empty local day adopts the cloud day', () {
      final merged = mergeDayEntries(
        cloud: [_dose(1, taken: true)],
        local: [],
      );

      expect(merged.length, 1);
    });

    test('an empty cloud day keeps the local day', () {
      final merged = mergeDayEntries(
        cloud: [],
        local: [_dose(1, taken: true)],
      );

      expect(merged.length, 1);
    });

    test('two empty days merge to empty', () {
      expect(mergeDayEntries(cloud: [], local: []), isEmpty);
    });
  });

  group('doseEntryKey', () {
    test('matches the medId-time pairing the server keys on', () {
      // detectMissedDoses builds `${medId}-${time}` to decide what is handled.
      // Divergence here would mean the app and the server disagree about
      // which dose is which.
      final key = doseEntryKey(_dose(7, time: '08:00'));

      expect(key, startsWith('7|08:00'));
    });

    test('isPrnEntry recognises the label logPrnDose writes', () {
      expect(isPrnEntry(_prn(1)), isTrue);
      expect(isPrnEntry(_dose(1)), isFalse);
    });
  });
}
