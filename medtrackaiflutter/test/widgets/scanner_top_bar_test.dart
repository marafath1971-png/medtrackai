import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/l10n/app_localizations.dart';
import 'package:medai/screens/scan/scanner_hub_screen.dart';
import 'package:medai/theme/med_ai_ui.dart';

/// The scanner header is a spaceBetween Row: two fixed 44px circular buttons
/// with a two-line title block between them. The title block had no flex, so
/// the Row asked it for its full intrinsic width no matter how little was
/// left — and "AI medicine recognition" at the app's maximum text scale is
/// wider than the gap on a small phone. RenderFlex then paints the yellow
/// overflow stripes over the camera preview.
///
/// Renders at real sizes rather than asserting on source text, because the
/// failure only exists once laid out.
Widget _host(Widget child, {TextScaler? scaler}) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: scaler ?? TextScaler.noScaling,
          ),
          child: Scaffold(backgroundColor: Colors.black, body: child),
        ),
      ),
    );

/// Every overflow Flutter reported while pumping, as readable strings.
List<String> _overflowErrors(WidgetTester tester) {
  final out = <String>[];
  for (;;) {
    final e = tester.takeException();
    if (e == null) break;
    out.add(e.toString());
  }
  return out;
}

void main() {
  /// The narrowest width the app supports in practice — an iPhone SE.
  const narrow = Size(320, 640);

  /// MedAiA11y.clampTextScale caps dynamic type at 1.35, so that is the
  /// largest the header can ever actually be asked to render.
  final maxScale = TextScaler.linear(MedAiA11y.maxTextScale);

  testWidgets('fits a narrow screen at default text size', (tester) async {
    tester.view.physicalSize = narrow;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(ScannerTopBar(onClose: () {})));
    await tester.pump();

    expect(_overflowErrors(tester), isEmpty);
  });

  testWidgets('fits a narrow screen at the largest supported text size',
      (tester) async {
    tester.view.physicalSize = narrow;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester
        .pumpWidget(_host(ScannerTopBar(onClose: () {}), scaler: maxScale));
    await tester.pump();

    // The regression: the title block took its full intrinsic width and the
    // Row overflowed, striping the camera preview.
    expect(_overflowErrors(tester), isEmpty,
        reason: 'the header must not overflow at the maximum text scale the '
            'app itself allows');
  });

  testWidgets('keeps both buttons on screen and tappable at max scale',
      (tester) async {
    tester.view.physicalSize = narrow;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    var closed = false;
    await tester.pumpWidget(
        _host(ScannerTopBar(onClose: () => closed = true), scaler: maxScale));
    await tester.pump();

    final back = find.byIcon(Icons.arrow_back_ios_new_rounded);
    expect(back, findsOneWidget);

    // An overflowing Row pushes its last child past the right edge, where it
    // cannot be hit — so this fails for the same bug, from the user's side.
    final box = tester.getRect(back);
    expect(box.left, greaterThanOrEqualTo(0.0));
    expect(box.right, lessThanOrEqualTo(320.0));

    await tester.tap(back);
    // AnimatedPressable schedules a 300ms Future.delayed to release its press
    // state. pumpAndSettle does not drain a plain Future.delayed, so advance
    // past it explicitly or the binding reports a pending timer at teardown.
    await tester.pump(const Duration(milliseconds: 350));

    expect(closed, isTrue, reason: 'the close button must stay reachable');
  });

  testWidgets('the title stays legible rather than being clipped away',
      (tester) async {
    tester.view.physicalSize = narrow;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester
        .pumpWidget(_host(ScannerTopBar(onClose: () {}), scaler: maxScale));
    await tester.pump();

    // Fixing overflow by hiding the text would also pass the checks above.
    expect(find.text('Scanner'), findsOneWidget);
    final title = tester.getRect(find.text('Scanner'));
    expect(title.width, greaterThan(0));
  });
}
