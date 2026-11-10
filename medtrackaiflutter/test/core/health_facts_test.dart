import 'package:flutter_test/flutter_test.dart';
import 'package:medai/core/utils/health_facts.dart';
import 'package:medai/domain/entities/entities.dart';

const _all = [0, 1, 2, 3, 4, 5, 6];

Medicine _med({
  int id = 1,
  String name = 'Metformin',
  List<ScheduleEntry>? schedule,
  int count = 30,
  int totalCount = 60,
  int refillAt = 7,
  String start = '2026-01-01',
}) =>
    Medicine(
      id: id,
      name: name,
      dose: '500 mg',
      schedule: schedule ??
          [
            ScheduleEntry(id: 'm', h: 8, m: 0, label: 'Morning', days: _all),
            ScheduleEntry(id: 'e', h: 20, m: 0, label: 'Evening', days: _all),
          ],
      count: count,
      totalCount: totalCount,
      refillAt: refillAt,
      courseStartDate: start,
    );

String _k(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DoseEntry _taken(String label, {String? at}) =>
    DoseEntry(medId: 1, label: label, time: '', taken: true, takenAt: at);

HealthFact _find(List<HealthFact> f, String label) =>
    f.firstWhere((x) => x.label == label);

void main() {
  final now = DateTime(2026, 9, 29, 21, 0); // a Tuesday evening

  test('ids are sequential so answers can cite them', () {
    final f = buildHealthFacts(
        meds: [_med()], history: {}, symptoms: [], streak: 0, now: now);
    expect(f.map((x) => x.id).take(3), ['F1', 'F2', 'F3']);
  });

  test('adherence is measured from the first logged day, not 30 days back', () {
    // Ten completed days logged, mornings only: 10 of 20 doses.
    final history = <String, List<DoseEntry>>{};
    for (var i = 1; i <= 10; i++) {
      history[_k(now.subtract(Duration(days: i)))] = [_taken('Morning')];
    }
    final f = buildHealthFacts(
        meds: [_med()], history: history, symptoms: [], streak: 0, now: now);
    expect(_find(f, 'Overall adherence').text,
        contains('10 of 20 scheduled doses'));
    expect(_find(f, 'Metformin').text,
        contains('the Evening dose is missed most (10 times)'));
  });

  test('a single-slot medicine is not told which slot is missed most', () {
    final med = _med(schedule: [
      ScheduleEntry(id: 'm', h: 8, m: 0, label: 'Morning', days: _all),
    ]);
    final history = {
      _k(now.subtract(const Duration(days: 1))): <DoseEntry>[],
      _k(now.subtract(const Duration(days: 2))): [_taken('Morning')],
    };
    final f = buildHealthFacts(
        meds: [med], history: history, symptoms: [], streak: 0, now: now);
    expect(_find(f, 'Metformin').text, isNot(contains('missed most')));
  });

  test('stock run-out is computed from the schedule', () {
    // 2 a day, 10 left -> 5 days.
    final f = buildHealthFacts(
        meds: [_med(count: 10, refillAt: 12)],
        history: {},
        symptoms: [],
        streak: 0,
        now: now);
    final t = _find(f, 'Metformin stock').text;
    expect(t, contains('about 5 days'));
    expect(t, contains('2026-10-04'));
    expect(t, contains('refill alert'));
  });

  test("today's overdue doses are named", () {
    final f = buildHealthFacts(meds: [
      _med()
    ], history: {
      _k(now): [_taken('Morning')]
    }, symptoms: [], streak: 3, now: now);
    final t = _find(f, 'Today').text;
    expect(t, contains('1 of 2'));
    expect(t, contains('Metformin (8:00 PM)'));
  });

  test('consistent lateness is reported, occasional lateness is not', () {
    final history = <String, List<DoseEntry>>{};
    for (var i = 1; i <= 6; i++) {
      final d = now.subtract(Duration(days: i));
      history[_k(d)] = [
        _taken('Morning',
            at: DateTime(d.year, d.month, d.day, 8, 50).toIso8601String()),
      ];
    }
    final f = buildHealthFacts(
        meds: [_med()], history: history, symptoms: [], streak: 0, now: now);
    expect(_find(f, 'Metformin timing').text, contains('about 50 minutes'));
  });

  test('a course that has not started yet is not counted as missed', () {
    final f = buildHealthFacts(
        meds: [_med(start: '2026-10-15')],
        history: {_k(now.subtract(const Duration(days: 3))): []},
        symptoms: [],
        streak: 0,
        now: now);
    expect(f.any((x) => x.label == 'Overall adherence'), isFalse);
  });
}
