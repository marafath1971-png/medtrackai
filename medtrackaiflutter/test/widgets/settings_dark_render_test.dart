import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/screens/settings/widgets/settings_kit.dart';
import 'package:medai/theme/med_ai_ui.dart';
import 'package:medai/l10n/app_localizations.dart';

/// settings_contrast_test reasons about token pairs by reading source. That
/// catches a card declared white next to theme-driven text, but it cannot
/// catch a widget that resolves the wrong token at runtime — the source can
/// look correct and still paint an invisible row.
///
/// These build the real widgets under the real dark theme and read the colours
/// actually handed to the painted Text and Container.
double _lum(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double _ratio(Color fg, Color bg) {
  final a = _lum(fg), b = _lum(bg);
  final hi = a > b ? a : b, lo = a > b ? b : a;
  return (hi + 0.05) / (lo + 0.05);
}

Widget _dark(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.dark(),
      home: Scaffold(
        backgroundColor: AppTheme.dark().scaffoldBackgroundColor,
        body: SingleChildScrollView(child: child),
      ),
    );

void main() {
  testWidgets('a settings row paints readable text in dark mode',
      (tester) async {
    await tester.pumpWidget(_dark(const SettingsSection(
      title: 'Account',
      children: [
        SettingsRow(
          icon: Icons.person_rounded,
          title: 'Profile',
          subtitle: 'Name, photo and email',
        ),
      ],
    )));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    final title = tester.widget<Text>(find.text('Profile'));
    final sub = tester.widget<Text>(find.text('Name, photo and email'));

    // Whatever the card resolves to, the text on it must not be near-black on
    // near-black. Both colours must be light against a dark surface.
    final tc = title.style?.color;
    final sc = sub.style?.color;
    expect(tc, isNotNull, reason: 'the title must carry an explicit colour');
    expect(sc, isNotNull);
    expect(_lum(tc!), greaterThan(0.3),
        reason: 'dark-mode title text must be light, got $tc');
    expect(_lum(sc!), greaterThan(0.15),
        reason: 'dark-mode subtitle must stay legible, got $sc');
  });

  testWidgets('a destructive row is still readable, not just red',
      (tester) async {
    await tester.pumpWidget(_dark(const SettingsSection(
      title: 'Danger',
      children: [
        SettingsRow(
          icon: Icons.delete_rounded,
          title: 'Delete account',
          destructive: true,
        ),
      ],
    )));
    await tester.pumpAndSettle();

    final c = tester.widget<Text>(find.text('Delete account')).style?.color;
    expect(c, isNotNull);
    expect(_ratio(c!, AppTheme.dark().scaffoldBackgroundColor),
        greaterThan(3.0),
        reason: 'destructive red must clear 3:1 on the dark ground, got $c');
  });

  testWidgets('a toggle renders and stays readable in dark mode',
      (tester) async {
    await tester.pumpWidget(_dark(SettingsSection(
      title: 'Reminders',
      children: [
        SettingsToggle(
          icon: Icons.notifications_rounded,
          title: 'Refill alerts',
          subtitle: 'Warn me before I run out',
          value: true,
          onChanged: (_) {},
        ),
      ],
    )));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final c = tester.widget<Text>(find.text('Refill alerts')).style?.color;
    expect(c, isNotNull);
    expect(_lum(c!), greaterThan(0.3), reason: 'toggle label went dark: $c');
  });
}
