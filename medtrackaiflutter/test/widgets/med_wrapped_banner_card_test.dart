import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/screens/dashboard/widgets/med_wrapped_banner_card.dart';

void main() {
  testWidgets(
      'MedWrappedBannerCard renders badge, headline, subtitle, and play button',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MedWrappedBannerCard(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('VIRAL RECAP'), findsOneWidget);
    expect(find.text('Your Med Wrapped ✨'), findsOneWidget);
    expect(
        find.text(
            'Tap to reveal your archetype, streaks & shareable story card'),
        findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });
}
