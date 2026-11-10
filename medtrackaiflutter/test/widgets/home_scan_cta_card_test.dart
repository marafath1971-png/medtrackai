import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/screens/home/widgets/home_scan_cta_card.dart';

void main() {
  testWidgets('HomeScanCtaCard renders hero text, chips and triggers onScan',
      (tester) async {
    var scanned = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: HomeScanCtaCard(
              onScan: () => scanned = true,
            ),
          ),
        ),
      ),
    );

    // Pump past initial entrance animations
    await tester.pump(const Duration(milliseconds: 500));

    // Verify chips
    expect(find.text('Scan Medicine'), findsOneWidget);
    expect(find.text('Skincare Check'), findsOneWidget);
    expect(find.text('Supplements'), findsOneWidget);

    // Verify headline and sub
    expect(find.text('Scan anything.\nKnow everything.'), findsOneWidget);
    expect(find.text('Meds • Skincare • Supplements'), findsOneWidget);

    // Verify social proof chips
    expect(find.text('2M+ Users'), findsOneWidget);
    expect(find.text('5-star Rated'), findsOneWidget);
    expect(find.text('AI-Powered'), findsOneWidget);

    // Tap hero card
    final hero = find.text('Scan anything.\nKnow everything.');
    await tester.tap(hero);
    await tester.pump(const Duration(milliseconds: 400));

    expect(scanned, isTrue);
  });
}
