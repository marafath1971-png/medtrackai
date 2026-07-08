import 'package:flutter_test/flutter_test.dart';
import 'package:medai/domain/entities/entities.dart';
import 'package:medai/screens/home/dose_grouping.dart';

/// Tests for the day-part grouping logic extracted from home_tab.dart
/// (blueprint §3.3). Boundaries: Morning 05–10:59, Afternoon 11–16:59,
/// Evening 17–20:59, Night 21–04:59.
void main() {
  Medicine med(int id) => Medicine(
        id: id,
        name: 'Med $id',
        courseStartDate: '2026-01-01',
      );

  DoseItem dose(int id, int hour, {int minute = 0}) {
    final m = med(id);
    final s = ScheduleEntry(
      id: 'S$id',
      h: hour,
      m: minute,
      label: 'Dose',
      days: const [0, 1, 2, 3, 4, 5, 6],
    );
    return DoseItem(med: m, sched: s, key: '${id}_S$id');
  }

  group('DoseGrouping boundary predicates', () {
    test('05:00 is Morning, 04:59 is Night', () {
      expect(DoseGrouping.isMorning(5), isTrue);
      expect(DoseGrouping.isNight(4), isTrue);
      expect(DoseGrouping.isMorning(4), isFalse);
    });

    test('11:00 flips Morning -> Afternoon', () {
      expect(DoseGrouping.isMorning(10), isTrue);
      expect(DoseGrouping.isAfternoon(11), isTrue);
      expect(DoseGrouping.isMorning(11), isFalse);
    });

    test('17:00 flips Afternoon -> Evening', () {
      expect(DoseGrouping.isAfternoon(16), isTrue);
      expect(DoseGrouping.isEvening(17), isTrue);
    });

    test('21:00 flips Evening -> Night', () {
      expect(DoseGrouping.isEvening(20), isTrue);
      expect(DoseGrouping.isNight(21), isTrue);
      expect(DoseGrouping.isNight(23), isTrue);
      expect(DoseGrouping.isNight(0), isTrue);
    });

    test('every hour belongs to exactly one day-part', () {
      for (var h = 0; h < 24; h++) {
        final memberships = [
          DoseGrouping.isMorning(h),
          DoseGrouping.isAfternoon(h),
          DoseGrouping.isEvening(h),
          DoseGrouping.isNight(h),
        ].where((x) => x).length;
        expect(memberships, 1, reason: 'hour $h');
      }
    });
  });

  group('DoseGrouping.group', () {
    test('buckets doses and preserves order within a group', () {
      final doses = [
        dose(1, 8), // Morning
        dose(2, 9, minute: 30), // Morning
        dose(3, 13), // Afternoon
        dose(4, 22), // Night
      ];
      final groups = DoseGrouping.group(doses);

      expect(groups.map((g) => g.title), ['Morning', 'Afternoon', 'Night']);
      expect(groups.first.items.map((d) => d.med.id), [1, 2]);
    });

    test('drops empty groups entirely', () {
      final groups = DoseGrouping.group([dose(1, 18)]); // Evening only
      expect(groups.length, 1);
      expect(groups.single.title, 'Evening');
    });

    test('empty input yields no groups', () {
      expect(DoseGrouping.group(const []), isEmpty);
    });

    test('midnight and pre-dawn doses land in Night', () {
      final groups = DoseGrouping.group([dose(1, 0), dose(2, 4, minute: 59)]);
      expect(groups.single.title, 'Night');
      expect(groups.single.items.length, 2);
    });
  });
}
