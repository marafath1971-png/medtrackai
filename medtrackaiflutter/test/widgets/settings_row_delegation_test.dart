import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/screens/home/widgets/settings/settings_shared.dart';
import 'package:medai/screens/settings/widgets/settings_kit.dart';
import 'package:medai/theme/med_ai_ui.dart';
import 'package:medai/l10n/app_localizations.dart';

/// SettingsModalRow and SettingsRow were two row implementations of the same
/// thing, which is how the settings surface ended up with a hardcoded white
/// card in one and a themed one in the other. The modal row now delegates, so
/// there is a single definition; it keeps its own emoji resolution and
/// first/last/border grouping so none of the 38 call sites had to change.
Widget _host(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(),
      home: Scaffold(body: Column(children: [child])),
    );

void main() {
  group('the modal row delegates', () {
    testWidgets('it renders through SettingsRow', (tester) async {
      await tester.pumpWidget(_host(const SettingsModalRow(
        icon: '🔔',
        label: 'Dose Reminders',
        sub: "Get notified when it's time",
      )));
      await tester.pump();

      expect(find.byType(SettingsRow), findsOneWidget,
          reason: 'two row implementations is what let them drift apart');
      expect(find.text('Dose Reminders'), findsOneWidget);
      expect(find.text("Get notified when it's time"), findsOneWidget);
    });

    testWidgets('a mapped emoji becomes its icon', (tester) async {
      await tester.pumpWidget(_host(const SettingsModalRow(
        icon: '🔔',
        label: 'Dose Reminders',
      )));
      await tester.pump();

      expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);
    });

    testWidgets('an unmapped emoji renders as itself, not a blank chip',
        (tester) async {
      // Two rows shipped with empty icon tiles because the resolver returned
      // null and the row drew the tile anyway.
      await tester.pumpWidget(_host(const SettingsModalRow(
        icon: '🦄',
        label: 'Something new',
      )));
      await tester.pump();

      expect(find.text('🦄'), findsOneWidget);
    });

    testWidgets('a trailing control is kept', (tester) async {
      await tester.pumpWidget(_host(SettingsModalRow(
        icon: '⚡',
        label: 'Haptics',
        right: Switch(value: true, onChanged: (_) {}),
      )));
      await tester.pump();

      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('tapping fires the callback', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(SettingsModalRow(
        icon: '📊',
        label: 'Export CSV Data',
        onClick: () => taps++,
      )));
      await tester.pump();

      await tester.tap(find.text('Export CSV Data'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(taps, 1);
    });

    testWidgets('an interactive row clears the 48dp minimum', (tester) async {
      await tester.pumpWidget(_host(SettingsModalRow(
        icon: '📊',
        label: 'Export CSV Data',
        onClick: () {},
      )));
      await tester.pump();

      final h = tester.getSize(find.byType(SettingsRow)).height;
      expect(h, greaterThanOrEqualTo(48));
    });
  });
}
