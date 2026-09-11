import 'package:flutter_test/flutter_test.dart';
import 'package:medai/data/repositories/medication_repository_impl.dart';

/// Pins the taken-today reconciliation rule used by
/// `MedicationRepositoryImpl.getTakenToday`.
///
/// That method previously replaced the local map with the cloud map whenever
/// the cloud was non-empty. A dose logged while offline exists only locally,
/// so the overwrite silently discarded it and the user watched a dose they had
/// logged flip back to untaken.
///
/// These call the repository's own helpers rather than restating the rule, so
/// the tests cannot drift away from the shipped behaviour.
void main() {
  group('mergeTakenToday', () {
    test('keeps a dose logged offline that the cloud never saw', () {
      final merged = mergeTakenToday(
        cloud: {'1-Morning': true},
        local: {'1-Morning': true, '2-Evening': true},
      );

      expect(merged['2-Evening'], isTrue,
          reason: 'the offline-logged dose must survive reconciliation');
      expect(merged.length, 2);
    });

    test('local wins on conflict — only local can hold an unsynced action', () {
      final merged = mergeTakenToday(
        cloud: {'1-Morning': false},
        local: {'1-Morning': true},
      );

      expect(merged['1-Morning'], isTrue);
    });

    test('cloud-only keys from another device are preserved', () {
      final merged = mergeTakenToday(
        cloud: {'3-Night': true},
        local: {'1-Morning': true},
      );

      expect(merged['3-Night'], isTrue);
      expect(merged['1-Morning'], isTrue);
    });

    test('empty local leaves the cloud state untouched', () {
      const cloud = {'1-Morning': true, '2-Evening': false};

      expect(mergeTakenToday(cloud: cloud, local: const {}), equals(cloud));
    });

    test('regression: the old overwrite dropped the offline dose', () {
      const cloud = {'1-Morning': true};
      const local = {'1-Morning': true, '2-Evening': true};

      // The previous implementation returned the cloud map verbatim, so the
      // offline dose simply was not in the result.
      expect(cloud.containsKey('2-Evening'), isFalse);
      expect(
        mergeTakenToday(cloud: cloud, local: local).containsKey('2-Evening'),
        isTrue,
      );
    });
  });

  group('takenTodayNeedsPush', () {
    test('pushes when local holds a key the cloud is missing', () {
      expect(
        takenTodayNeedsPush(
          cloud: {'1-Morning': true},
          merged: {'1-Morning': true, '2-Evening': true},
        ),
        isTrue,
      );
    });

    test('pushes when local disagrees with the cloud value', () {
      expect(
        takenTodayNeedsPush(
          cloud: {'1-Morning': false},
          merged: {'1-Morning': true},
        ),
        isTrue,
      );
    });

    test('does not push when the cloud already agrees', () {
      expect(
        takenTodayNeedsPush(
          cloud: {'1-Morning': true, '2-Evening': false},
          merged: {'1-Morning': true, '2-Evening': false},
        ),
        isFalse,
        reason: 'a no-op write on every load would be wasteful',
      );
    });

    test('a merge that changed nothing must not trigger a write', () {
      const cloud = {'1-Morning': true};
      final merged = mergeTakenToday(cloud: cloud, local: const {});

      expect(takenTodayNeedsPush(cloud: cloud, merged: merged), isFalse);
    });
  });
}
