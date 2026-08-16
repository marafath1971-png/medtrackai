import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:medai/domain/entities/entities.dart';
import 'package:medai/domain/repositories/medication_repository.dart';
import 'package:medai/providers/controllers/medication_controller.dart';

class MockMedicationRepository extends Mock implements IMedicationRepository {}

/// Adherence drives the Trends headline, the PDF clinical report, and the
/// AI insight prompts, so a wrong denominator quietly misreports how well
/// someone is taking their medication.
///
/// The bug: the denominator counted *medicines* scheduled on a day, while the
/// numerator counted *dose entries* taken. A medicine with two daily slots
/// contributed 1 to the denominator but up to 2 to the numerator, so a
/// perfectly adherent twice-daily user scored 200% (clamped to 100%), and any
/// mix of once- and twice-daily medicines produced a meaningless ratio.
String _dateKey(DateTime d) =>
    "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

Medicine _med({
  required int id,
  required String name,
  required List<String> slots,
}) {
  return Medicine(
    id: id,
    name: name,
    courseStartDate: DateTime.now().toIso8601String(),
    schedule: [
      for (final s in slots)
        ScheduleEntry(
          id: '$id-$s',
          h: 8,
          m: 0,
          label: s,
          days: const [0, 1, 2, 3, 4, 5, 6],
        ),
    ],
  );
}

void main() {
  late MedicationController c;

  setUp(() {
    c = MedicationController(medRepo: MockMedicationRepository());
  });

  test('no medicines and no history scores 0, not a false 100%', () {
    expect(c.getAdherenceScore(), 0.0);
  });

  test('a once-daily medicine taken every day scores 100%', () {
    c.setStateForTest(
      meds: [_med(id: 1, name: 'Vitamin D', slots: ['Morning'])],
      history: {
        for (var i = 0; i < 30; i++)
          _dateKey(DateTime.now().subtract(Duration(days: i))): [
            DoseEntry(
                medId: 1, label: 'Morning', time: '8:00 AM', taken: true),
          ],
      },
    );

    expect(c.getAdherenceScore(), closeTo(1.0, 0.001));
  });

  test('a twice-daily medicine with both doses taken scores 100%, not 200%',
      () {
    c.setStateForTest(
      meds: [
        _med(id: 1, name: 'Metformin', slots: ['Morning', 'Evening'])
      ],
      history: {
        for (var i = 0; i < 30; i++)
          _dateKey(DateTime.now().subtract(Duration(days: i))): [
            DoseEntry(
                medId: 1, label: 'Morning', time: '8:00 AM', taken: true),
            DoseEntry(
                medId: 1, label: 'Evening', time: '8:00 PM', taken: true),
          ],
      },
    );

    expect(c.getAdherenceScore(), closeTo(1.0, 0.001));
  });

  test('a twice-daily medicine with one of two doses taken scores 50%', () {
    c.setStateForTest(
      meds: [
        _med(id: 1, name: 'Metformin', slots: ['Morning', 'Evening'])
      ],
      history: {
        for (var i = 0; i < 30; i++)
          _dateKey(DateTime.now().subtract(Duration(days: i))): [
            DoseEntry(
                medId: 1, label: 'Morning', time: '8:00 AM', taken: true),
          ],
      },
    );

    // Half the scheduled slots were taken. Counting medicines instead of
    // slots reported this as 100%.
    expect(c.getAdherenceScore(), closeTo(0.5, 0.001));
  });

  test('PRN doses do not inflate the score', () {
    c.setStateForTest(
      meds: [_med(id: 1, name: 'Vitamin D', slots: ['Morning'])],
      history: {
        for (var i = 0; i < 30; i++)
          _dateKey(DateTime.now().subtract(Duration(days: i))): [
            DoseEntry(
                medId: 1, label: 'Morning', time: '8:00 AM', taken: true),
            DoseEntry(
                medId: 1, label: 'PRN-1', time: '2:00 PM', taken: true),
          ],
      },
    );

    expect(c.getAdherenceScore(), closeTo(1.0, 0.001),
        reason: 'as-needed doses are unscheduled and must not exceed 100%');
  });

  test('nothing taken scores 0', () {
    c.setStateForTest(
      meds: [_med(id: 1, name: 'Vitamin D', slots: ['Morning'])],
      history: const {},
    );

    expect(c.getAdherenceScore(), 0.0);
  });

  test('the score never leaves the 0..1 range', () {
    c.setStateForTest(
      meds: [_med(id: 1, name: 'Vitamin D', slots: ['Morning'])],
      history: {
        for (var i = 0; i < 30; i++)
          _dateKey(DateTime.now().subtract(Duration(days: i))): [
            for (var j = 0; j < 5; j++)
              DoseEntry(
                  medId: 1, label: 'Morning', time: '8:00 AM', taken: true),
          ],
      },
    );

    final score = c.getAdherenceScore();
    expect(score, lessThanOrEqualTo(1.0));
    expect(score, greaterThanOrEqualTo(0.0));
  });
}
