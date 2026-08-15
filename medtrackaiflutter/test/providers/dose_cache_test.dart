import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:medai/domain/repositories/medication_repository.dart';
import 'package:medai/providers/controllers/medication_controller.dart';

class MockMedicationRepository extends Mock implements IMedicationRepository {}

/// `getDoses()` caches only the no-arg (today) result. The cache had no notion
/// of which day it was built for, so a cache populated on one day — or before
/// seeding finished — was served indefinitely. Callers using the no-arg form
/// (the home header) then disagreed with callers passing an explicit date (the
/// progress ring): "0 of 2 done" beside a 2/5 ring on the same screen.
void main() {
  test('no-arg getDoses agrees with an explicit today', () {
    final c = MedicationController(medRepo: MockMedicationRepository());
    c.devSeed();

    final implicit = c.getDoses();
    final explicit = c.getDoses(date: DateTime.now());

    expect(implicit.length, explicit.length,
        reason: 'the header and the ring must count the same doses');
  });

  test('the cache does not leak across days', () {
    final c = MedicationController(medRepo: MockMedicationRepository());
    c.devSeed();

    // Warm the cache for today.
    final today = c.getDoses();
    expect(today, isNotEmpty);

    // A different day must be recomputed, never served from today's cache.
    final tomorrow = c.getDoses(date: DateTime.now().add(const Duration(days: 1)));
    expect(identical(today, tomorrow), isFalse);
  });

  test('seeding after a warm cache is reflected, not masked by it', () {
    final c = MedicationController(medRepo: MockMedicationRepository());

    // Warm the cache while empty — this is what made the header stick at a
    // stale count after devSeed populated the meds.
    expect(c.getDoses(), isEmpty);

    c.devSeed();
    expect(c.getDoses(), isNotEmpty,
        reason: 'a stale empty cache must not survive seeding');
  });
}
