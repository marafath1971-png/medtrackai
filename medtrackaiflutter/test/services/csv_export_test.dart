import 'package:flutter_test/flutter_test.dart';
import 'package:medai/domain/entities/entities.dart';
import 'package:medai/services/report_service.dart';

/// The CSV export is what people hand to their doctor, and the Data Safety
/// form promises it works. Unescaped fields silently shift every later column,
/// so a dose logged as "Taken" can read as "Missed" once the file is opened.
Medicine _med({required int id, required String name, String dose = '10 mg'}) =>
    Medicine(
      id: id,
      name: name,
      dose: dose,
      courseStartDate: '2026-08-16T09:00:00.000',
    );

DoseEntry _entry({
  required int medId,
  bool taken = true,
  String? takenAt,
}) =>
    DoseEntry(
      medId: medId,
      label: 'Morning',
      time: '8:00 AM',
      taken: taken,
      takenAt: takenAt,
    );

void main() {
  group('csvField escaping', () {
    test('leaves ordinary values untouched', () {
      expect(ReportService.csvField('Lisinopril'), 'Lisinopril');
      expect(ReportService.csvField('10 mg'), '10 mg');
    });

    test('null becomes an empty field', () {
      expect(ReportService.csvField(null), '');
    });

    test('quotes a value containing a comma', () {
      expect(ReportService.csvField('Aspirin, Enteric Coated'),
          '"Aspirin, Enteric Coated"');
    });

    test('doubles embedded quotes', () {
      expect(ReportService.csvField('Brand "X"'), '"Brand ""X"""');
    });

    test('quotes a value containing a newline', () {
      expect(ReportService.csvField('Line1\nLine2'), '"Line1\nLine2"');
    });
  });

  group('buildCsv', () {
    test('writes the header row', () {
      final csv = ReportService.buildCsv(meds: const [], history: const {});
      expect(csv.trim(), 'Date,Medicine,Dose,Status,Timestamp');
    });

    test('emits one row per dose entry', () {
      final csv = ReportService.buildCsv(
        meds: [_med(id: 1, name: 'Lisinopril')],
        history: {
          '2026-08-16': [_entry(medId: 1), _entry(medId: 1, taken: false)],
        },
      );

      final rows = csv.trim().split('\n');
      expect(rows.length, 3, reason: 'header plus two entries');
      expect(rows[1], contains('Taken'));
      expect(rows[2], contains('Missed'));
    });

    test('a medicine name with a comma keeps the column count intact', () {
      final csv = ReportService.buildCsv(
        meds: [_med(id: 1, name: 'Aspirin, Enteric Coated')],
        history: {
          '2026-08-16': [_entry(medId: 1, takenAt: '08:05')],
        },
      );

      final row = csv.trim().split('\n')[1];
      expect(row, contains('"Aspirin, Enteric Coated"'));

      // Split on commas that are not inside quotes — a correct row has
      // exactly 5 fields, so Status still reads as the 4th.
      final fields = RegExp(r'(?:^|,)("(?:[^"]|"")*"|[^,]*)')
          .allMatches(row)
          .map((m) => m.group(1)!)
          .toList();
      expect(fields.length, 5,
          reason: 'an unescaped comma would push this to 6 and shift Status');
      expect(fields[3], 'Taken');
    });

    test('an unknown medicine id falls back rather than dropping the row', () {
      final csv = ReportService.buildCsv(
        meds: [_med(id: 1, name: 'Lisinopril')],
        history: {
          '2026-08-16': [_entry(medId: 999)],
        },
      );

      expect(csv, contains('Unknown'));
    });

    test('dates are ordered newest first', () {
      final csv = ReportService.buildCsv(
        meds: [_med(id: 1, name: 'Lisinopril')],
        history: {
          '2026-08-14': [_entry(medId: 1)],
          '2026-08-16': [_entry(medId: 1)],
          '2026-08-15': [_entry(medId: 1)],
        },
      );

      final rows = csv.trim().split('\n');
      expect(rows[1], startsWith('2026-08-16'));
      expect(rows[2], startsWith('2026-08-15'));
      expect(rows[3], startsWith('2026-08-14'));
    });

    test('a missing timestamp leaves an empty trailing field', () {
      final csv = ReportService.buildCsv(
        meds: [_med(id: 1, name: 'Lisinopril')],
        history: {
          '2026-08-16': [_entry(medId: 1)],
        },
      );

      expect(csv.trim().split('\n')[1], endsWith(','));
    });
  });
}
