import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/widgets/animations/pixel_art_mascot.dart';

void main() {
  testWidgets('PixelArtMascot renders and responds to tap', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PixelArtMascot(
              size: 100,
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(PixelArtMascot), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);

    // Tap triggers on tap and hop animation
    await tester.tap(find.byType(PixelArtMascot));
    await tester.pump();
    expect(tapped, isTrue);

    // Let idle and hop animations run without errors
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 300));
  });
}

