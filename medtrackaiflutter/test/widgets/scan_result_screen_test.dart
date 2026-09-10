import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/domain/entities/entities.dart';
import 'package:medai/screens/scan/widgets/scan_result_detail_view.dart';
import 'package:medai/theme/med_ai_ui.dart';
import 'package:medai/l10n/app_localizations.dart';

/// The screen a user sees after scanning a medicine — it decides what they
/// believe about a pill they are about to take.
///
/// The camera itself cannot be tested (the emulator renders a synthetic
/// pattern, and AI scan is gated behind App Check on an unsigned build), but
/// this view is pure props: given a ScanResult it renders confidence, warnings
/// and interactions. That is the part where being wrong is dangerous.
/// The result view is a tall column; give it a real scroll viewport so the
/// test surface does not overflow before assertions run.
Widget _host(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(),
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );

Widget _view(ScanResult result) => ScanResultDetailView(
      result: result,
      onAddToMedicines: () {},
      onScanAnother: () {},
    );

void main() {
  group('confidenceValue parsing', () {
    test('reads a percentage string', () {
      expect(ScanResultDetailView.confidenceValue('95%'), closeTo(0.95, 0.001));
      expect(ScanResultDetailView.confidenceValue('40'), closeTo(0.40, 0.001));
    });

    test('clamps out-of-range percentages', () {
      expect(ScanResultDetailView.confidenceValue('140%'), 1.0);
      expect(ScanResultDetailView.confidenceValue('-20'), 0.0);
    });

    test('maps the qualitative words the model returns', () {
      expect(ScanResultDetailView.confidenceValue('high'), greaterThan(0.85));
      expect(ScanResultDetailView.confidenceValue('very high'),
          greaterThan(0.85));
      expect(ScanResultDetailView.confidenceValue('medium'),
          inInclusiveRange(0.6, 0.8));
      expect(ScanResultDetailView.confidenceValue('moderate'),
          inInclusiveRange(0.6, 0.8));
      expect(ScanResultDetailView.confidenceValue('low'), lessThan(0.5));
    });

    test('is case insensitive and tolerates whitespace', () {
      expect(ScanResultDetailView.confidenceValue('  HIGH  '),
          ScanResultDetailView.confidenceValue('high'));
    });

    group('unparseable input must not read as confident', () {
      // A medicine scan that cannot report its confidence is exactly the case
      // where the user should be cautious. Anything above the meter's 0.5
      // amber threshold presents a guess as a reasonable match.
      for (final raw in const ['', '   ', 'unknown', 'uncertain', 'not sure', 'n/a']) {
        test('"$raw" stays in the low band', () {
          expect(ScanResultDetailView.confidenceValue(raw), lessThan(0.5),
              reason: 'an unknown confidence must not be shown as a '
                  'mid-confidence match');
        });
      }
    });
  });

  group('rendering a result', () {
    testWidgets('shows the medicine name and dose', (tester) async {
      await tester.pumpWidget(_host(_view(ScanResult(
        name: 'Metformin',
        dose: '500 mg',
        identified: true,
        confidence: 'high',
      ))));
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.textContaining('Metformin'), findsWidgets);
    });

    testWidgets('surfaces warnings returned by the scan', (tester) async {
      await tester.pumpWidget(_host(_view(ScanResult(
        name: 'Warfarin',
        identified: true,
        confidence: 'high',
        warnings: 'Do not take with aspirin\nAvoid alcohol',
      ))));
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.textContaining('aspirin'), findsWidgets,
          reason: 'a warning the scan found must reach the user');
    });

    testWidgets('surfaces interactions returned by the scan', (tester) async {
      await tester.pumpWidget(_host(_view(ScanResult(
        name: 'Warfarin',
        identified: true,
        confidence: 'high',
        interactions: 'Interacts with ibuprofen',
      ))));
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.textContaining('ibuprofen'), findsWidgets);
    });

    testWidgets('an unidentified result is not presented as a match',
        (tester) async {
      await tester.pumpWidget(_host(_view(ScanResult(
        name: 'Unknown',
        identified: false,
        confidence: 'low',
      ))));
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.textContaining('Not confirmed'), findsWidgets,
          reason: 'the honest next step is to rescan, not to track a guess');
    });

    testWidgets('a confirmed result advises verifying with a pharmacist',
        (tester) async {
      await tester.pumpWidget(_host(_view(ScanResult(
        name: 'Metformin',
        identified: true,
        confidence: 'high',
      ))));
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.textContaining('pharmacist'), findsWidgets,
          reason: 'AI identification is a suggestion, never a diagnosis');
    });

    testWidgets('renders without throwing on a sparse result', (tester) async {
      // Models return partial payloads; the view must not blow up on them.
      await tester.pumpWidget(_host(_view(ScanResult(name: 'X'))));
      await tester.pump(const Duration(milliseconds: 700));

      expect(tester.takeException(), isNull);
    });
  });
}
