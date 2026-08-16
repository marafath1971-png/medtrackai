import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:medai/domain/entities/entities.dart';
import 'package:medai/domain/repositories/medication_repository.dart';
import 'package:medai/providers/controllers/medication_controller.dart';

class MockMedicationRepository extends Mock implements IMedicationRepository {}

/// The streak is the app's main retention hook — it drives the home hero, the
/// freeze economy, and share cards. Getting it wrong either robs someone of a
/// streak they earned or credits one they did not.
///
/// getStreak() keys history by `toIso8601String().substring(0, 10)`, so tests
/// must build keys the same way.
String _key(DateTime d) => d.toIso8601String().substring(0, 10);

Medicine _med({
  required int id,
  required List<String> slots,
  List<int> days = const [0, 1, 2, 3, 4, 5, 6],
}) {
  return Medicine(
    id: id,
    name: 'Med$id',
    courseStartDate: DateTime.now().toIso8601String(),
    schedule: [
      for (final s in slots)
        ScheduleEntry(id: '$id-$s', h: 8, m: 0, label: s, days: days),
    ],
  );
}

DoseEntry _taken(String label) =>
    DoseEntry(medId: 1, label: label, time: '8:00 AM', taken: true);

void main() {
  late MedicationController c;

  setUp(() {
    c = MedicationController(medRepo: MockMedicationRepository());
  });

  test('no medicines means no streak', () {
    expect(c.getStreak(), 0);
  });

  test('a full day yesterday and today counts both', () {
    final now = DateTime.now();
    c.setStateForTest(
      meds: [_med(id: 1, slots: ['Morning'])],
      history: {
        _key(now): [_taken('Morning')],
        _key(now.subtract(const Duration(days: 1))): [_taken('Morning')],
      },
    );

    expect(c.getStreak(), 2);
  });

  test('an incomplete today does not break the streak', () {
    final now = DateTime.now();
    c.setStateForTest(
      meds: [_med(id: 1, slots: ['Morning'])],
      history: {
        // Nothing logged today yet — the day is still in progress.
        _key(now.subtract(const Duration(days: 1))): [_taken('Morning')],
        _key(now.subtract(const Duration(days: 2))): [_taken('Morning')],
      },
    );

    expect(c.getStreak(), 2,
        reason: 'today being unfinished must not cost the user their streak');
  });

  test('a missed past day ends the streak', () {
    final now = DateTime.now();
    c.setStateForTest(
      meds: [_med(id: 1, slots: ['Morning'])],
      history: {
        _key(now): [_taken('Morning')],
        // day 1 missed entirely
        _key(now.subtract(const Duration(days: 2))): [_taken('Morning')],
      },
    );

    expect(c.getStreak(), 1);
  });

  test('a frozen day bridges a gap instead of breaking the streak', () {
    final now = DateTime.now();
    final missed = _key(now.subtract(const Duration(days: 1)));
    c.setStateForTest(
      meds: [_med(id: 1, slots: ['Morning'])],
      history: {
        _key(now): [_taken('Morning')],
        _key(now.subtract(const Duration(days: 2))): [_taken('Morning')],
      },
      frozenDates: [missed],
    );

    expect(c.getStreak(), 3,
        reason: 'the frozen day should be bridged, not end the run');
  });

  test('days with nothing scheduled are skipped, not counted as missed', () {
    final now = DateTime.now();
    // Scheduled only on the weekday that is two days ago, so yesterday has
    // nothing due and must not break the run.
    final onlyDay = now.subtract(const Duration(days: 2)).weekday % 7;
    c.setStateForTest(
      meds: [_med(id: 1, slots: ['Morning'], days: [onlyDay])],
      history: {
        _key(now.subtract(const Duration(days: 2))): [_taken('Morning')],
      },
    );

    expect(c.getStreak(), greaterThanOrEqualTo(1),
        reason: 'a day with no doses due is not a missed day');
  });

  group('twice-daily medicines', () {
    test('taking only one of two daily doses does not earn a streak day', () {
      final now = DateTime.now();
      c.setStateForTest(
        meds: [
          _med(id: 1, slots: ['Morning', 'Evening'])
        ],
        history: {
          // Yesterday: only half the doses taken -> 50%, below the 0.8 bar.
          _key(now.subtract(const Duration(days: 1))): [_taken('Morning')],
          _key(now.subtract(const Duration(days: 2))): [
            _taken('Morning'),
            _taken('Evening'),
          ],
        },
      );

      expect(c.getStreak(), 0,
          reason:
              'counting medicines instead of slots made 1-of-2 look like 100%');
    });

    test('taking both daily doses does earn the streak day', () {
      final now = DateTime.now();
      c.setStateForTest(
        meds: [
          _med(id: 1, slots: ['Morning', 'Evening'])
        ],
        history: {
          _key(now.subtract(const Duration(days: 1))): [
            _taken('Morning'),
            _taken('Evening'),
          ],
        },
      );

      expect(c.getStreak(), 1);
    });
  });
}
