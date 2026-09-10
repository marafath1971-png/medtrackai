import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/theme/med_ai_ui.dart';
import 'package:medai/l10n/app_localizations.dart';

/// Three shipped bugs had the same shape: a widget tinted a surface dark and
/// coloured its content to match, but [MedAiGlass] discards its tint in light
/// mode and paints L.card. The result was white-on-white — an Apple sign-in
/// button that looked like an empty pill, caregiver chips where the selection
/// was invisible, and chat bubbles where users could not read their own
/// messages.
///
/// None of these were caught by analyzer, unit tests, or code review. They were
/// found by running the app. These tests assert the property that was violated:
/// content must contrast with what is actually painted behind it.

/// Relative luminance per WCAG, used to compare foreground against background.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();

  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

/// Contrast ratio between two colours, 1.0 (identical) to 21.0 (black/white).
double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

Widget _lightHost(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('MedAiGlass tint behaviour in light mode', () {
    testWidgets('a dark tint is NOT honoured — the documented trap',
        (tester) async {
      late Color painted;
      late Color intendedTint;

      await tester.pumpWidget(_lightHost(
        Builder(builder: (context) {
          intendedTint = context.L.text;
          return MedAiGlass(
            tint: intendedTint,
            child: const SizedBox(width: 40, height: 40),
          );
        }),
      ));

      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
                of: find.byType(MedAiGlass),
                matching: find.byType(DecoratedBox))
            .first,
      );
      painted = (box.decoration as BoxDecoration).color!;

      // This is the trap: what gets painted is nothing like the tint asked for.
      expect(_contrast(painted, intendedTint), greaterThan(4.0),
          reason: 'MedAiGlass paints L.card in light mode, not the tint — '
              'so white content on a dark tint would be invisible. If this '
              'assertion starts failing, MedAiGlass changed and the solid '
              'surfaces in auth_screen / add_cg_flow / ask_ai_sheet can be '
              'reconsidered.');
    });
  });

  group('solid surfaces keep their content readable', () {
    testWidgets('a dark solid fill contrasts with white content',
        (tester) async {
      late Color fill;
      late Color content;

      await tester.pumpWidget(_lightHost(
        Builder(builder: (context) {
          fill = context.L.text;
          content = Colors.white;
          return Container(
            decoration: BoxDecoration(color: fill),
            child: const SizedBox(width: 40, height: 40),
          );
        }),
      ));

      expect(_contrast(fill, content), greaterThan(4.5),
          reason: 'the Apple button, selected chips and user chat bubbles all '
              'rely on this being a real dark fill');
    });

    testWidgets('L.bg content on an L.card surface is NOT readable',
        (tester) async {
      late Color surface;
      late Color content;

      await tester.pumpWidget(_lightHost(
        Builder(builder: (context) {
          surface = context.L.card;
          content = context.L.bg;
          return const SizedBox();
        }),
      ));

      // Exactly the shipped bug: cream text on a near-white card.
      expect(_contrast(surface, content), lessThan(3.0),
          reason: 'documents why L.bg content requires a genuinely dark fill '
              'behind it, never a glass surface');
    });
  });
}
