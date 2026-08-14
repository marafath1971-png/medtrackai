import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/screens/medicine/widgets/interaction_warning_sheet.dart';
import 'package:medai/theme/med_ai_ui.dart';

/// Safety and consent surfaces staggered their entrance over as much as
/// 800ms, revealing the action buttons last. Under reduced motion the content
/// must be on screen and readable in the first frame.
Widget _host({required bool disableAnimations, required Widget child}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
  );
}

void main() {
  const sheet = InteractionWarningSheet(
    medicineName: 'Lisinopril',
    interactionName: 'Vitamin C',
    interactionDetails: 'Space them out by 2 hours.',
  );

  group('MedAiA11y.reducedMotion', () {
    testWidgets('follows MediaQuery.disableAnimations', (tester) async {
      late bool reduced;
      await tester.pumpWidget(_host(
        disableAnimations: true,
        child: Builder(builder: (context) {
          reduced = MedAiA11y.reducedMotion(context);
          return const SizedBox();
        }),
      ));
      expect(reduced, isTrue);
    });

    testWidgets('motion() collapses durations to zero', (tester) async {
      late Duration d;
      await tester.pumpWidget(_host(
        disableAnimations: true,
        child: Builder(builder: (context) {
          d = MedAiA11y.motion(context, const Duration(milliseconds: 400));
          return const SizedBox();
        }),
      ));
      expect(d, Duration.zero);
    });
  });

  group('InteractionWarningSheet', () {
    testWidgets('renders warning text and actions on the first frame '
        'when reduced motion is on', (tester) async {
      await tester.pumpWidget(_host(disableAnimations: true, child: sheet));

      // No settle — this is the first frame.
      expect(find.text('Lisinopril + Vitamin C'), findsOneWidget);
      expect(find.text('Space them out by 2 hours.'), findsOneWidget);

      // The staggered entrance previously left these fully transparent.
      for (final o in tester.widgetList<Opacity>(find.byType(Opacity))) {
        expect(o.opacity, greaterThan(0.0),
            reason: 'reduced motion must not hide safety copy behind a fade');
      }
    });

    testWidgets('still renders the same content with motion enabled',
        (tester) async {
      await tester.pumpWidget(_host(disableAnimations: false, child: sheet));
      await tester.pumpAndSettle();

      expect(find.text('Lisinopril + Vitamin C'), findsOneWidget);
      expect(find.text('Space them out by 2 hours.'), findsOneWidget);
    });
  });
}
