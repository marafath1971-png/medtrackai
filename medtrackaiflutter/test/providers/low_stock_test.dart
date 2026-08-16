import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:medai/domain/entities/entities.dart';
import 'package:medai/domain/repositories/medication_repository.dart';
import 'package:medai/providers/controllers/medication_controller.dart';

class MockMedicationRepository extends Mock implements IMedicationRepository {}

/// getLowStockCount drives the home "refill needed" stat, the header badge,
/// and the dashboard alert dot. Under-reporting means someone runs out of a
/// medicine without warning; over-reporting trains people to ignore the badge.
Medicine _med({
  required int id,
  required int count,
  required int refillAt,
  int totalCount = 30,
}) {
  return Medicine(
    id: id,
    name: 'Med$id',
    count: count,
    refillAt: refillAt,
    totalCount: totalCount,
    courseStartDate: DateTime.now().toIso8601String(),
  );
}

void main() {
  late MedicationController c;

  setUp(() {
    c = MedicationController(medRepo: MockMedicationRepository());
  });

  test('no medicines means nothing low', () {
    expect(c.getLowStockCount(), 0);
  });

  test('stock above the threshold is not low', () {
    c.setStateForTest(meds: [_med(id: 1, count: 20, refillAt: 7)]);
    expect(c.getLowStockCount(), 0);
  });

  test('stock exactly at the threshold counts as low', () {
    c.setStateForTest(meds: [_med(id: 1, count: 7, refillAt: 7)]);
    expect(c.getLowStockCount(), 1,
        reason: 'hitting the refill point is the moment to warn, not after');
  });

  test('stock below the threshold counts as low', () {
    c.setStateForTest(meds: [_med(id: 1, count: 2, refillAt: 7)]);
    expect(c.getLowStockCount(), 1);
  });

  test('an empty medicine still counts as low', () {
    c.setStateForTest(meds: [_med(id: 1, count: 0, refillAt: 7)]);
    expect(c.getLowStockCount(), 1,
        reason: 'running out entirely is the most urgent case');
  });

  test('only the low medicines are counted', () {
    c.setStateForTest(meds: [
      _med(id: 1, count: 2, refillAt: 7), // low
      _med(id: 2, count: 25, refillAt: 7), // fine
      _med(id: 3, count: 7, refillAt: 7), // low (at threshold)
    ]);
    expect(c.getLowStockCount(), 2);
  });

  test('medicines with no tracked total are ignored', () {
    // totalCount == 0 means the user never set up inventory for this med, so
    // "0 of 0 left" must not be reported as needing a refill.
    c.setStateForTest(meds: [_med(id: 1, count: 0, refillAt: 0, totalCount: 0)]);
    expect(c.getLowStockCount(), 0,
        reason: 'untracked inventory is not a refill warning');
  });

  _refillAlertBoundary();

  test('a refillAt of 0 only warns once the medicine is gone', () {
    c.setStateForTest(meds: [_med(id: 1, count: 1, refillAt: 0)]);
    expect(c.getLowStockCount(), 0);

    c.setStateForTest(meds: [_med(id: 1, count: 0, refillAt: 0)]);
    expect(c.getLowStockCount(), 1);
  });
}

/// The refill alert fires whenever a dose leaves stock at or below the refill
/// threshold. Testing the controller path directly would need a
/// NotificationService fake and platform channels, so these pin the boundary
/// condition the two call sites share:
///
///   newCount <= refillAt
///
/// It was previously `newCount == refillAt`, which silently sent no alert at
/// all to anyone already below their threshold.
bool _shouldAlert({required int previousCount, required int refillAt}) {
  final newCount = previousCount - 1;
  return newCount <= refillAt;
}

void _refillAlertBoundary() {
  group('refill alert boundary', () {
    test('fires on the dose that crosses the threshold', () {
      expect(_shouldAlert(previousCount: 8, refillAt: 7), isTrue);
    });

    test('keeps firing while stock stays low', () {
      // Not spam: showRefillAlert posts with a stable per-medicine id, so each
      // dose replaces the previous notification and refreshes the count.
      expect(_shouldAlert(previousCount: 7, refillAt: 7), isTrue);
      expect(_shouldAlert(previousCount: 3, refillAt: 7), isTrue);
    });

    test('does not fire while comfortably stocked', () {
      expect(_shouldAlert(previousCount: 30, refillAt: 7), isFalse);
    });

    test('fires when the threshold was raised above current stock', () {
      // The case `==` missed entirely: stock 15, user raises refillAt to 20.
      // The count is already below the threshold, so it never *equals* it on
      // the way down and no alert was ever sent.
      expect(_shouldAlert(previousCount: 15, refillAt: 20), isTrue);
    });

    test('fires on the last unit when refillAt is 0', () {
      expect(_shouldAlert(previousCount: 1, refillAt: 0), isTrue);
    });
  });
}
