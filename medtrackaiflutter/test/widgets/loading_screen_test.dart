import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/models/constants.dart';
import 'package:medai/screens/loading/loading_screen.dart';
import 'package:medai/theme/med_ai_ui.dart';
import 'package:medai/widgets/common/app_loading_indicator.dart';
import 'package:medai/widgets/common/ghost_mascot.dart';

/// The splash is the first thing seen on every cold start, and it shipped with
/// the pre-rename wordmark hardcoded while kAppName already said otherwise.
Widget _host() => MaterialApp(
      theme: AppTheme.light(),
      home: const LoadingScreen(),
    );

void main() {
  testWidgets('it shows the current app name, not the old one', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text(kAppName), findsOneWidget);
    expect(find.text('MedTrack AI'), findsNothing);
  });

  testWidgets('the name is not hardcoded', (tester) async {
    // A literal would drift from kAppName again on the next rename.
    final src =
        File('lib/screens/loading/loading_screen.dart').readAsStringSync();
    expect(src.contains("'MedTrack"), isFalse);
    expect(src.contains('kAppName'), isTrue);
  });

  testWidgets('the logo appears once, not twice', (tester) async {
    // AppLoadingIndicator is MedAiLogo.badge; at size 18 under the mascot it
    // rendered as an illegible speck of the same mark shown above it.
    await tester.pumpWidget(_host());
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(GhostMascot), findsOneWidget);
    expect(find.byType(AppLoadingIndicator), findsNothing);
  });

  testWidgets('the wordmark is not set in the heaviest weight', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pump(const Duration(milliseconds: 600));

    final w = tester.widget<Text>(find.text(kAppName)).style?.fontWeight;
    expect(w, isNotNull);
    expect(w!.value, lessThan(FontWeight.w900.value),
        reason: 'w900 at display size reads as blocky, not confident');
  });

  testWidgets('it settles without overflowing a small screen', (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 568 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host());
    await tester.pump(const Duration(milliseconds: 800));

    expect(tester.takeException(), isNull);
  });
}
