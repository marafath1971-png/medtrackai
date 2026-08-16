import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/theme/med_ai_ui.dart';
import 'package:medai/widgets/common/solid_surface.dart';

/// [SolidSurface] is the one place the "content must contrast with its fill"
/// rule lives. Three screens each had their own private copy after
/// [MedAiGlass] silently dropped their dark tint in light mode, producing the
/// invisible Apple sign-in button, invisible selection chips, and unreadable
/// user chat bubbles.
///
/// These render the real widget and read the colour it actually paints, rather
/// than asserting on tokens.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

Widget _host(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      theme: brightness == Brightness.light
          ? AppTheme.light()
          : AppTheme.dark(),
      home: Scaffold(body: Center(child: child)),
    );

/// The colour SolidSurface paints, read off its own DecoratedBox.
Color _paintedFill(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find
        .descendant(
            of: find.byType(SolidSurface), matching: find.byType(DecoratedBox))
        .first,
  );
  return (box.decoration as BoxDecoration).color!;
}

void main() {
  group('filled surfaces are genuinely dark', () {
    testWidgets('white content is readable on a filled surface',
        (tester) async {
      await tester.pumpWidget(_host(
        const SolidSurface(
          filled: true,
          child: Text('Continue with Apple',
              style: TextStyle(color: Colors.white)),
        ),
      ));

      expect(_contrast(_paintedFill(tester), Colors.white), greaterThan(4.5),
          reason: 'this is the Apple sign-in button — white on a fill that is '
              'not dark is the bug that shipped');
    });

    testWidgets('L.bg content is readable on a filled surface', (tester) async {
      late Color content;

      await tester.pumpWidget(_host(
        Builder(builder: (context) {
          content = context.L.bg;
          return SolidSurface(
            filled: true,
            child: Text('EQUIPPED', style: TextStyle(color: content)),
          );
        }),
      ));

      expect(_contrast(_paintedFill(tester), content), greaterThan(4.5),
          reason: 'selection chips and user chat bubbles colour their content '
              'L.bg, which only works on a real dark fill');
    });

    testWidgets('the same holds in dark mode', (tester) async {
      await tester.pumpWidget(_host(
        const SolidSurface(filled: true, child: Text('x')),
        brightness: Brightness.dark,
      ));

      // Whatever the theme, a filled surface must differ from an unfilled one.
      final filled = _paintedFill(tester);

      await tester.pumpWidget(_host(
        const SolidSurface(filled: false, child: Text('x')),
        brightness: Brightness.dark,
      ));

      expect(_contrast(filled, _paintedFill(tester)), greaterThan(1.5),
          reason: 'selected and unselected must be distinguishable');
    });
  });

  group('unfilled surfaces keep dark content readable', () {
    testWidgets('L.text content is readable on an unfilled surface',
        (tester) async {
      late Color content;

      await tester.pumpWidget(_host(
        Builder(builder: (context) {
          content = context.L.text;
          return SolidSurface(
            filled: false,
            child: Text('Continue with Google',
                style: TextStyle(color: content)),
          );
        }),
      ));

      expect(_contrast(_paintedFill(tester), content), greaterThan(4.5));
    });
  });

  group('selected and unselected states are distinguishable', () {
    testWidgets('a filled chip differs visibly from an unfilled one',
        (tester) async {
      await tester
          .pumpWidget(_host(const SolidSurface(filled: true, child: Text('A'))));
      final selected = _paintedFill(tester);

      await tester.pumpWidget(
          _host(const SolidSurface(filled: false, child: Text('A'))));
      final unselected = _paintedFill(tester);

      expect(_contrast(selected, unselected), greaterThan(3.0),
          reason: 'the caregiver avatar and relationship pickers rely on this '
              'to show which option is chosen');
    });

    testWidgets('a border thickens when filled', (tester) async {
      await tester.pumpWidget(_host(const SolidSurface(
          filled: true, showBorder: true, child: Text('A'))));

      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
                of: find.byType(SolidSurface),
                matching: find.byType(DecoratedBox))
            .first,
      );
      final border = (box.decoration as BoxDecoration).border as Border;

      expect(border.top.width, greaterThan(1.0));
    });
  });

  group('glassWhenUnfilled', () {
    testWidgets('renders glass only when unfilled', (tester) async {
      await tester.pumpWidget(_host(const SolidSurface(
          filled: false, glassWhenUnfilled: true, child: Text('x'))));
      expect(find.byType(MedAiGlass), findsOneWidget);

      await tester.pumpWidget(_host(const SolidSurface(
          filled: true, glassWhenUnfilled: true, child: Text('x'))));
      expect(find.byType(MedAiGlass), findsNothing,
          reason: 'a filled surface must never fall back to glass, which is '
              'what dropped the tint in the first place');
    });

    testWidgets('a filled glass-capable surface still paints a dark fill',
        (tester) async {
      await tester.pumpWidget(_host(const SolidSurface(
        filled: true,
        glassWhenUnfilled: true,
        child: Text('Continue with Apple',
            style: TextStyle(color: Colors.white)),
      )));

      expect(_contrast(_paintedFill(tester), Colors.white), greaterThan(4.5));
    });
  });

  group('the child is always rendered', () {
    testWidgets('content survives both states', (tester) async {
      await tester.pumpWidget(
          _host(const SolidSurface(filled: true, child: Text('EQUIPPED'))));
      expect(find.text('EQUIPPED'), findsOneWidget);

      await tester.pumpWidget(
          _host(const SolidSurface(filled: false, child: Text('EQUIPPED'))));
      expect(find.text('EQUIPPED'), findsOneWidget);
    });
  });
}
