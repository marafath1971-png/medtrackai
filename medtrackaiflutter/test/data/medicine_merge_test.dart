import 'package:flutter_test/flutter_test.dart';
import 'package:medai/data/repositories/medication_repository_impl.dart';
import 'package:medai/domain/entities/entities.dart';

/// Pins the medicine reconciliation rule used by
/// `MedicationRepositoryImpl.getMedicines`.
///
/// That merge used to be a union by id — cloud records, plus any local id the
/// cloud did not have. It was wrong in both directions, and on a medication
/// app both are safety issues rather than annoyances:
///
///  * **Deletions came back.** Deleting a medicine on phone A removed it from
///    the cloud, but phone B still held it locally, saw an id the cloud
///    lacked, and re-uploaded it — so it reappeared on phone A. A drug the
///    user deliberately stopped taking returning to their schedule is the
///    worst version of this bug.
///  * **Edits were silently reverted.** On an id collision the cloud copy won
///    unconditionally, so an edit made offline on phone A was overwritten by
///    phone B's stale copy on A's next load.
///
/// These call the repository's own helpers rather than restating the rule, so
/// the tests cannot drift away from the shipped behaviour.
const _kStart = '2026-08-15T09:00:00.000';

Medicine _med(int id, {String name = 'Warfarin', DateTime? updatedAt, int count = 30}) =>
    Medicine(
      id: id,
      name: name,
      count: count,
      courseStartDate: _kStart,
      updatedAt: updatedAt,
    );

final _older = DateTime.utc(2026, 9, 1, 10);
final _newer = DateTime.utc(2026, 9, 20, 10);

void main() {
  group('mergeMedicines — deletions', () {
    test('a tombstoned medicine is not resurrected from local', () {
      // The original bug: phone B holds a stale local copy of a medicine
      // phone A deleted. Without the tombstone this looked like "local has an
      // id the cloud lacks" and got re-uploaded.
      final result = mergeMedicines(
        cloud: [],
        local: [_med(1)],
        tombstones: {1: _newer},
      );

      expect(result.merged, isEmpty);
      expect(result.toPush, isEmpty,
          reason: 'a deleted medicine must never be re-uploaded');
    });

    test('a tombstone deletes the cloud copy that is still there', () {
      // Deleting while offline: the local removal succeeded, the Firestore
      // call did not. The tombstone is what replays it.
      final result = mergeMedicines(
        cloud: [_med(1)],
        local: [],
        tombstones: {1: _newer},
      );

      expect(result.merged, isEmpty);
      expect(result.toDelete, [1],
          reason: 'the pending deletion must be replayed to the cloud');
    });

    test('a deletion does not disturb the surviving medicines', () {
      final result = mergeMedicines(
        cloud: [_med(1), _med(2, name: 'Metformin')],
        local: [_med(1), _med(2, name: 'Metformin')],
        tombstones: {1: _newer},
      );

      expect(result.merged.map((m) => m.id), [2]);
      expect(result.toDelete, [1]);
    });

    test('an untombstoned local-only medicine is still pushed', () {
      // The legitimate case the old union merge existed to serve: added
      // offline, never uploaded. This must keep working.
      final result = mergeMedicines(
        cloud: [],
        local: [_med(1)],
        tombstones: {},
      );

      expect(result.merged.map((m) => m.id), [1]);
      expect(result.toPush.map((m) => m.id), [1]);
    });
  });

  group('mergeMedicines — conflicting edits', () {
    test('the newer local edit wins over a stale cloud copy', () {
      final result = mergeMedicines(
        cloud: [_med(1, count: 30, updatedAt: _older)],
        local: [_med(1, count: 12, updatedAt: _newer)],
        tombstones: {},
      );

      expect(result.merged.single.count, 12,
          reason: 'the offline edit must not be reverted');
      expect(result.toPush.map((m) => m.id), [1],
          reason: 'and it has to reach the cloud');
    });

    test('the newer cloud edit wins over a stale local copy', () {
      final result = mergeMedicines(
        cloud: [_med(1, count: 12, updatedAt: _newer)],
        local: [_med(1, count: 30, updatedAt: _older)],
        tombstones: {},
      );

      expect(result.merged.single.count, 12);
      expect(result.toPush, isEmpty,
          reason: 'the cloud already holds the winning copy');
    });

    test('an unstamped legacy record loses to a stamped edit', () {
      // Records written before updatedAt existed read as null. Treating null
      // as "oldest" means a fresh edit always beats a legacy copy, in both
      // directions.
      final localWins = mergeMedicines(
        cloud: [_med(1, count: 30)],
        local: [_med(1, count: 12, updatedAt: _newer)],
        tombstones: {},
      );
      expect(localWins.merged.single.count, 12);

      final cloudWins = mergeMedicines(
        cloud: [_med(1, count: 12, updatedAt: _newer)],
        local: [_med(1, count: 30)],
        tombstones: {},
      );
      expect(cloudWins.merged.single.count, 12);
    });

    test('with no timestamps on either side the cloud wins, as before', () {
      // Preserves the pre-existing behaviour for data that predates the fix,
      // so upgrading cannot itself change what a user sees.
      final result = mergeMedicines(
        cloud: [_med(1, count: 30)],
        local: [_med(1, count: 12)],
        tombstones: {},
      );

      expect(result.merged.single.count, 30);
      expect(result.toPush, isEmpty);
    });

    test('an identical timestamp does not cause a pointless re-push', () {
      final result = mergeMedicines(
        cloud: [_med(1, updatedAt: _newer)],
        local: [_med(1, updatedAt: _newer)],
        tombstones: {},
      );

      expect(result.toPush, isEmpty);
    });
  });

  group('mergeMedicines — the ordinary cases', () {
    test('a cloud-only medicine added elsewhere is adopted', () {
      final result = mergeMedicines(
        cloud: [_med(1)],
        local: [],
        tombstones: {},
      );

      expect(result.merged.map((m) => m.id), [1]);
      expect(result.toPush, isEmpty);
      expect(result.toDelete, isEmpty);
    });

    test('two empty sides merge to empty without any writes', () {
      final result = mergeMedicines(cloud: [], local: [], tombstones: {});

      expect(result.merged, isEmpty);
      expect(result.toPush, isEmpty);
      expect(result.toDelete, isEmpty);
    });

    test('disjoint libraries are unioned', () {
      final result = mergeMedicines(
        cloud: [_med(1)],
        local: [_med(2, name: 'Metformin')],
        tombstones: {},
      );

      expect(result.merged.map((m) => m.id).toSet(), {1, 2});
      expect(result.toPush.map((m) => m.id), [2]);
    });
  });

  group('pruneTombstones', () {
    test('keeps a deletion still inside the retention window', () {
      final now = DateTime.utc(2026, 9, 22);
      final pruned = pruneTombstones(
        {1: now.subtract(const Duration(days: 10))},
        now: now,
      );

      expect(pruned.keys, [1]);
    });

    test('drops a deletion older than the retention window', () {
      // Past this point every device has long since reconciled, and keeping
      // tombstones forever would grow the key without bound.
      final now = DateTime.utc(2026, 9, 22);
      final pruned = pruneTombstones(
        {1: now.subtract(kTombstoneRetention + const Duration(days: 1))},
        now: now,
      );

      expect(pruned, isEmpty);
    });

    test('an expired tombstone no longer suppresses the medicine', () {
      // The deliberate trade-off: a device offline for longer than the
      // retention window will resurrect that one medicine. 90 days is chosen
      // so that is vanishingly rare, and the alternative is unbounded growth.
      final now = DateTime.utc(2026, 9, 22);
      final pruned = pruneTombstones(
        {1: now.subtract(kTombstoneRetention + const Duration(days: 1))},
        now: now,
      );

      final result = mergeMedicines(
        cloud: [],
        local: [_med(1)],
        tombstones: pruned,
      );

      expect(result.merged.map((m) => m.id), [1]);
    });
  });

  group('Medicine.updatedAt', () {
    test('copyWith stamps the edit so it can win a conflict', () {
      final before = DateTime.now().toUtc();
      final edited = _med(1, updatedAt: _older).copyWith(count: 12);

      expect(edited.updatedAt, isNotNull);
      expect(edited.updatedAt!.isBefore(before), isFalse,
          reason: 'an edit must advance the clock, not keep the old stamp');
    });

    test('touch: false preserves the timestamp for non-edit rewrites', () {
      // The sync path rewrites records it did not author; re-stamping them
      // would make last-write-wins resolve in favour of whoever synced most
      // recently rather than whoever edited most recently.
      final copied = _med(1, updatedAt: _older).copyWith(count: 12, touch: false);

      expect(copied.updatedAt, _older);
    });

    test('the timestamp survives a JSON round trip as UTC', () {
      final restored = Medicine.fromJson(_med(1, updatedAt: _newer).toJson());

      expect(restored.updatedAt, _newer);
      expect(restored.updatedAt!.isUtc, isTrue,
          reason: 'cross-device comparison requires a zone-independent stamp');
    });

    test('a record with no timestamp round trips as null, not an epoch', () {
      // A garbage default would sort as 1970 and lose every conflict, which is
      // right by luck; but a non-null default would also mark legacy records
      // as comparable, which is not.
      final restored = Medicine.fromJson(_med(1).toJson());

      expect(restored.updatedAt, isNull);
    });

    test('a corrupt timestamp reads as null rather than throwing', () {
      final json = _med(1).toJson()..['updatedAt'] = 'not-a-date';

      expect(Medicine.fromJson(json).updatedAt, isNull);
    });
  });
}
