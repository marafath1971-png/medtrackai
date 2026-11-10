import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/screens/home/widgets/home_daily_celebration_card.dart';

void main() {
  testWidgets(
      'HomeDailyCelebrationCard renders celebration text, badges and triggers onShare',
      (tester) async {
    var shared = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeDailyCelebrationCard(
            takenCount: 3,
            totalDoses: 3,
            streak: 5,
            onShare: () => shared = true,
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('PERFECT DAY'), findsOneWidget);
    expect(find.text('5 day streak'), findsOneWidget);
    expect(find.text('All Doses Done for Today! 🎉'), findsOneWidget);
    expect(find.text("Share Today's Win"), findsOneWidget);

    await tester.tap(find.text("Share Today's Win"));
    await tester.pump(const Duration(milliseconds: 400));

    expect(shared, isTrue);
  });
}
