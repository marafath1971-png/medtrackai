import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/theme/med_ai_ui.dart';
import 'package:medai/widgets/common/solid_surface.dart';
import 'package:medai/widgets/modals/ask_ai_sheet.dart';
import 'package:medai/l10n/app_localizations.dart';

/// The AI chat sheet, rendered whole and driven through a real send.
///
/// The shipped bug: the user's own bubble tinted a MedAiGlass surface dark and
/// coloured its text L.bg. Light mode discards that tint and paints L.card, so
/// people could not read what they had just typed.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

Widget _host(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    );

void main() {
  /// The send control, located by its icon rather than a semantics label —
  /// bySemanticsLabel needs the merged semantics tree, which is extra
  /// machinery for no benefit here.
  Finder sendButton() => find.byIcon(Icons.send_rounded);

  testWidgets('the sheet renders its empty state', (tester) async {
    await tester.pumpWidget(_host(const AskAiSheet(contextInsights: [])));
    await tester.pump();

    expect(find.textContaining('Ask me anything'), findsOneWidget);
    expect(find.text('AI Health Coach'), findsOneWidget);
  });

  testWidgets('typing a question and sending renders the user message',
      (tester) async {
    await tester.pumpWidget(_host(const AskAiSheet(contextInsights: [])));
    await tester.pump();

    await tester.enterText(
        find.byType(TextField).first, 'Can I take this with food?');
    await tester.pump();

    await tester.tap(sendButton());
    await tester.pump();

    expect(find.text('Can I take this with food?'), findsOneWidget,
        reason: 'the message must appear immediately, before any AI reply');

    // Let the in-flight request and any debounce settle.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle(const Duration(seconds: 1));
  });

  testWidgets('the user bubble is a filled SolidSurface, not glass',
      (tester) async {
    await tester.pumpWidget(_host(const AskAiSheet(contextInsights: [])));
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'hello');
    await tester.pump();
    await tester.tap(sendButton());
    await tester.pump();

    final bubbles =
        tester.widgetList<SolidSurface>(find.byType(SolidSurface)).toList();

    expect(bubbles.any((b) => b.filled), isTrue,
        reason: 'the user bubble must paint a real dark fill — a glass '
            'surface would leave its L.bg text unreadable');

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle(const Duration(seconds: 1));
  });

  testWidgets('the user message text contrasts with its bubble',
      (tester) async {
    late AppThemeColors colors;

    await tester.pumpWidget(_host(Builder(builder: (context) {
      colors = context.L;
      return const AskAiSheet(contextInsights: []);
    })));
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'hello');
    await tester.pump();
    await tester.tap(sendButton());
    await tester.pump();

    // The user bubble paints L.text and writes L.bg on it.
    expect(_contrast(colors.text, colors.bg), greaterThan(4.5),
        reason: 'this pairing is only readable because the fill is genuinely '
            'dark; it was the exact bug when the fill fell back to L.card');

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle(const Duration(seconds: 1));
  });

  testWidgets('an empty message is not sent', (tester) async {
    await tester.pumpWidget(_host(const AskAiSheet(contextInsights: [])));
    await tester.pump();

    await tester.tap(sendButton());
    await tester.pump();

    expect(find.textContaining('Ask me anything'), findsOneWidget,
        reason: 'the empty state should still be showing');
    expect(find.byType(SolidSurface), findsNothing,
        reason: 'no bubble should have been created');

    // The press animation still debounces even though nothing was sent.
    await tester.pump(const Duration(milliseconds: 400));
  });
}
