import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/domain/entities/medicine.dart';
import 'package:medai/screens/home/widgets/home_dose_row.dart';

void main() {
  testWidgets(
      'HomeDoseRow allows slide-to-take horizontal swipe to trigger onTake',
      (tester) async {
    bool takenTriggered = false;
    bool detailTapped = false;

    final med = Medicine(
      id: 101,
      name: 'Tretinoin 0.05% Cream',
      category: 'Skincare',
      form: 'cream',
      dose: 'Pea-sized amount',
      color: '#4A9E86',
      courseStartDate: '2026-09-26',
    );

    final sched = ScheduleEntry(
      id: 'sched_1',
      h: 21,
      m: 0,
      label: 'Night Routine',
      days: const [0, 1, 2, 3, 4, 5, 6],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeDoseRow(
            med: med,
            sched: sched,
            taken: false,
            overdue: false,
            onTake: () => takenTriggered = true,
            onTap: () => detailTapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Tretinoin 0.05% Cream'), findsOneWidget);
    expect(find.byType(Dismissible), findsOneWidget);

    // Swipe right horizontally past threshold
    await tester.fling(find.byType(Dismissible), const Offset(400, 0), 1000.0);
    await tester.pumpAndSettle();

    expect(takenTriggered, isTrue);
    expect(detailTapped, isFalse);
  });

  testWidgets('HomeDoseRow when taken does not wrap in Dismissible',
      (tester) async {
    final med = Medicine(
      id: 102,
      name: 'Zinc Picolinate',
      category: 'Supplement',
      color: '#8FD14F',
      courseStartDate: '2026-09-26',
    );

    final sched = ScheduleEntry(
      id: 'sched_2',
      h: 8,
      m: 30,
      label: 'Morning',
      days: const [0, 1, 2, 3, 4, 5, 6],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeDoseRow(
            med: med,
            sched: sched,
            taken: true,
            overdue: false,
            onTake: () {},
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Zinc Picolinate'), findsOneWidget);
    expect(find.byType(Dismissible), findsNothing);
  });
}
