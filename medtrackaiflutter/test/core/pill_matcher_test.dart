import 'package:flutter_test/flutter_test.dart';
import 'package:medai/core/utils/pill_matcher.dart';
import 'package:medai/domain/entities/entities.dart';

Medicine _med(int id, String name,
        {String dose = '', String generic = '', String brand = ''}) =>
    Medicine(
      id: id,
      name: name,
      dose: dose,
      genericName: generic,
      brand: brand,
      schedule: const [],
      courseStartDate: '2026-09-01',
    );

ScanResult _scan(String name,
        {String dose = '',
        String generic = '',
        String brand = '',
        String confidence = 'high',
        bool identified = true}) =>
    ScanResult(
      identified: identified,
      name: name,
      dose: dose,
      genericName: generic,
      brand: brand,
      confidence: confidence,
    );

void main() {
  group('matchScannedPill', () {
    final meds = [
      _med(1, 'Metformin', dose: '500 mg'),
      _med(2, 'Lisinopril', dose: '10mg'),
      _med(3, 'Vitamin D3', dose: '1000 IU'),
    ];

    test('same medicine and strength is a verified match', () {
      final m = matchScannedPill(_scan('Metformin HCl', dose: '500mg'), meds);
      expect(m.kind, PillMatchKind.match);
      expect(m.med?.id, 1);
      expect(m.strengthVerified, isTrue);
    });

    test('a different strength of my medicine is flagged, not matched', () {
      final m = matchScannedPill(_scan('Lisinopril', dose: '20 mg'), meds);
      expect(m.kind, PillMatchKind.strengthMismatch);
      expect(m.med?.id, 2);
    });

    test('extended release is not the same as immediate release', () {
      final m = matchScannedPill(_scan('Metformin ER', dose: '500 mg'),
          [_med(1, 'Metformin XR', dose: '500 mg')]);
      expect(m.kind, PillMatchKind.strengthMismatch);
    });

    test('units are normalised: 0.5 g is 500 mg', () {
      final m = matchScannedPill(_scan('Metformin', dose: '0.5 g'), meds);
      expect(m.kind, PillMatchKind.match);
      expect(m.strengthVerified, isTrue);
    });

    test('a brand name matches the generic in my list', () {
      final m = matchScannedPill(
          _scan('Glucophage', generic: 'Metformin', dose: '500 mg'), meds);
      expect(m.kind, PillMatchKind.match);
    });

    test('a name match without a stated strength is a match, unverified', () {
      final m = matchScannedPill(_scan('Metformin'), meds);
      expect(m.kind, PillMatchKind.match);
      expect(m.strengthVerified, isFalse);
    });

    test('a similar-looking vitamin is not my vitamin', () {
      final m = matchScannedPill(_scan('Vitamin B12', dose: '1000 mcg'), meds);
      expect(m.kind, PillMatchKind.notMine);
    });

    test('something not in my list is not mine', () {
      final m = matchScannedPill(_scan('Ibuprofen', dose: '200 mg'), meds);
      expect(m.kind, PillMatchKind.notMine);
    });

    test('with two strengths listed, the one that fits wins', () {
      final m = matchScannedPill(_scan('Lisinopril', dose: '20 mg'), [
        _med(2, 'Lisinopril', dose: '10 mg'),
        _med(5, 'Lisinopril', dose: '20 mg'),
      ]);
      expect(m.kind, PillMatchKind.match);
      expect(m.med?.id, 5);
    });

    test('low confidence is carried through so the UI can say so', () {
      final m = matchScannedPill(
          _scan('Metformin', dose: '500 mg', confidence: 'low'), meds);
      expect(m.kind, PillMatchKind.match);
      expect(m.confident, isFalse);
    });

    test('an unidentified scan never matches', () {
      final m = matchScannedPill(_scan('Metformin', identified: false), meds);
      expect(m.kind, PillMatchKind.unidentified);
    });
  });

  group('doseToLog', () {
    final med = _med(1, 'Metformin');
    DoseItem dose(int h, String label) => DoseItem(
          med: med,
          sched: ScheduleEntry(
              id: label,
              h: h,
              m: 0,
              label: label,
              days: const [0, 1, 2, 3, 4, 5, 6]),
          key: '1-$label',
        );
    final doses = [dose(8, 'Morning'), dose(20, 'Evening')];

    test('picks the dose closest to now', () {
      final d = doseToLog(
          doses: doses,
          takenToday: const {},
          medId: 1,
          now: DateTime(2026, 9, 29, 9, 15));
      expect(d?.sched.label, 'Morning');
    });

    test('skips a dose already taken', () {
      final d = doseToLog(
          doses: doses,
          takenToday: const {'1-Morning': true},
          medId: 1,
          now: DateTime(2026, 9, 29, 9, 15));
      expect(d?.sched.label, 'Evening');
    });

    test('nothing left to log returns null', () {
      final d = doseToLog(
          doses: doses,
          takenToday: const {'1-Morning': true, '1-Evening': true},
          medId: 1,
          now: DateTime(2026, 9, 29, 9));
      expect(d, isNull);
    });
  });
}
