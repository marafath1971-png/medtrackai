import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/screens/scan/scanner_hub_screen.dart';
import 'package:medai/theme/med_ai_ui.dart';

/// The scanner search field types in white.
///
/// Its container was `Colors.white @ 0.20` — a translucent wash that only
/// worked while a dark camera feed sat behind it. Android also paints its own
/// near-white autofill highlight behind fields it considers fillable, and white
/// text on that is invisible: typing a medicine name produced a blank white box
/// with a cursor in it.
///
/// The field now paints its own dark, opaque ground and declares itself
/// unfillable. Because the text colour is hardcoded white, that ground is what
/// keeps it readable, so it is asserted here rather than left to the theme.

double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();

  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Flattens a translucent colour onto an opaque backdrop, which is what the eye
/// actually sees — comparing against the unflattened colour is how a wash this
/// transparent passed review by inspection.
Color _over(Color fg, Color bg) {
  final a = fg.a;
  return Color.fromARGB(
    255,
    ((fg.r * a + bg.r * (1 - a)) * 255).round(),
    ((fg.g * a + bg.g * (1 - a)) * 255).round(),
    ((fg.b * a + bg.b * (1 - a)) * 255).round(),
  );
}

Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  late TextEditingController controller;
  late FocusNode focus;

  setUp(() {
    controller = TextEditingController();
    focus = FocusNode();
  });

  tearDown(() {
    controller.dispose();
    focus.dispose();
  });

  Future<Container> pumpAndFindGround(WidgetTester tester) async {
    await tester.pumpWidget(_host(ScanSearchInput(
      controller: controller,
      focusNode: focus,
      onSubmit: () {},
    )));
    await tester.pump(const Duration(milliseconds: 400));

    // The decorated container wrapping the row is the field's own ground.
    final containers = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) => c.decoration is BoxDecoration)
        .where((c) => (c.decoration as BoxDecoration).borderRadius != null)
        .toList();

    return containers.firstWhere((c) {
      final d = c.decoration as BoxDecoration;
      return d.color != null && d.border != null;
    });
  }

  testWidgets('typed text contrasts against the field ground', (tester) async {
    final ground = await pumpAndFindGround(tester);
    final fill = (ground.decoration as BoxDecoration).color!;

    // Worst case: the field sits over a white surface — a bright camera frame,
    // or the platform's autofill highlight. Flatten onto white, not onto the
    // dark feed we hope is there.
    final effective = _over(fill, const Color(0xFFFFFFFF));
    final ratio = _contrast(const Color(0xFFFFFFFF), effective);

    expect(ratio, greaterThan(4.5),
        reason: 'white text needs a dark ground even when what is behind the '
            'field is white; the old 20%-white wash gave a ratio near 1');
  });

  testWidgets('the field does not offer itself for autofill', (tester) async {
    await tester.pumpWidget(_host(ScanSearchInput(
      controller: controller,
      focusNode: focus,
      onSubmit: () {},
    )));
    await tester.pump(const Duration(milliseconds: 400));

    final field = tester.widget<TextField>(find.byType(TextField));

    expect(field.autofillHints, isEmpty,
        reason: 'a medicine name is not an identity field, and the autofill '
            'highlight is what painted white-on-white');
  });

  testWidgets('the hint is readable, not a ghost', (tester) async {
    await tester.pumpWidget(_host(ScanSearchInput(
      controller: controller,
      focusNode: focus,
      onSubmit: () {},
    )));
    await tester.pump(const Duration(milliseconds: 400));

    final field = tester.widget<TextField>(find.byType(TextField));
    final hint = field.decoration!.hintStyle!.color!;

    // At 0.30 on the old translucent wash the placeholder was barely visible.
    expect(hint.a, greaterThanOrEqualTo(0.45));
  });

  testWidgets('submitting runs the search', (tester) async {
    var submitted = 0;
    await tester.pumpWidget(_host(ScanSearchInput(
      controller: controller,
      focusNode: focus,
      onSubmit: () => submitted++,
    )));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.enterText(find.byType(TextField), 'Metformin');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();

    expect(controller.text, 'Metformin');
    expect(submitted, 1);
  });
}
