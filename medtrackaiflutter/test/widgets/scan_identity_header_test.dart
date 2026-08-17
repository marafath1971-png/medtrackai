import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/screens/analysis/widgets/scan_identity_header.dart';
import 'package:medai/theme/med_ai_ui.dart';

/// Voice search and name search produce a result with no photo. The old header
/// still reserved a 16:11 slot for one — about 370px of empty gradient behind a
/// faded pill glyph, at the very top of the screen, saying nothing. A scan of
/// "Metformin" opened on a blank blue rectangle.
Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  group('without a photo', () {
    testWidgets('shows a compact band carrying the name', (tester) async {
      await tester.pumpWidget(_host(const ScanIdentityHeader(
        imageFile: null,
        category: 'Medicine',
        name: 'Metformin',
      )));

      expect(find.text('Metformin'), findsOneWidget);
      expect(find.text('IDENTIFIED'), findsOneWidget);
      expect(find.text('Medicine'), findsOneWidget);
    });

    testWidgets('does not reserve the tall photo slot', (tester) async {
      await tester.pumpWidget(_host(const ScanIdentityHeader(
        imageFile: null,
        category: 'Medicine',
        name: 'Metformin',
      )));

      final height = tester.getSize(find.byType(ScanIdentityHeader)).height;

      // The photo variant is 16:11 of the full width — on any phone that is
      // well over 200px. The band must stay far below it.
      expect(height, lessThan(120),
          reason: 'a missing photo should not cost a screenful of gradient');
    });

    testWidgets('a long name is truncated rather than overflowing',
        (tester) async {
      await tester.pumpWidget(_host(const ScanIdentityHeader(
        imageFile: null,
        category: 'Supplement',
        name: 'Alben Albendazole Suspension Extended Release Oral 200mg',
      )));

      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(find.textContaining('Albendazole'));
      expect(text.overflow, TextOverflow.ellipsis);
      expect(text.maxLines, 1);
    });
  });

  group('with a photo', () {
    testWidgets('a missing file does not throw the screen away',
        (tester) async {
      // Image.file on a path that no longer exists reports through the error
      // builder / console rather than crashing, but the header itself must
      // still lay out — the analysis around it is the valuable part.
      await tester.pumpWidget(_host(ScanIdentityHeader(
        imageFile: File('/nonexistent/scan.jpg'),
        category: 'Medicine',
        name: 'Metformin',
      )));

      expect(find.byType(ScanIdentityHeader), findsOneWidget);
      // The photo variant does not print the name — it is shown by the display
      // heading below, which only renders when a photo is present.
      expect(find.text('IDENTIFIED'), findsNothing);
    });
  });

  group('ScanSectionHeader', () {
    testWidgets('renders title, subtitle and icon', (tester) async {
      await tester.pumpWidget(_host(const ScanSectionHeader(
        title: 'Safety first',
        subtitle: 'Important alerts — know before you take.',
        icon: Icons.shield_outlined,
      )));

      expect(find.text('Safety first'), findsOneWidget);
      expect(find.textContaining('know before you take'), findsOneWidget);
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    });

    testWidgets('a subtitle is optional', (tester) async {
      await tester.pumpWidget(_host(const ScanSectionHeader(
        title: 'Side-effect map',
        icon: Icons.monitor_heart_outlined,
      )));

      expect(find.text('Side-effect map'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
