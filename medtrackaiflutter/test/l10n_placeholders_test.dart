import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/l10n/app_localizations.dart';

/// A placeholder message is only correct if the argument actually lands in the
/// rendered string. A compile check does not prove that: `'{count} left'` with
/// the brace mistyped still compiles and still returns a String.
void main() {
  Future<AppLocalizations> load(WidgetTester tester, String code) async {
    late AppLocalizations s;
    await tester.pumpWidget(MaterialApp(
      locale: Locale(code),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (c) {
        s = AppLocalizations.of(c)!;
        return const SizedBox();
      }),
    ));
    return s;
  }

  testWidgets('arguments are substituted, not printed literally', (t) async {
    final s = await load(t, 'en');

    final removed = s.alarmsAlarmForRemoved('Aspirin');
    expect(removed, contains('Aspirin'));
    expect(removed, isNot(contains('{')));

    final at = s.alarmsReminderAt('Aspirin', '8:00 AM');
    expect(at, contains('Aspirin'));
    expect(at, contains('8:00 AM'));
    expect(at, isNot(contains('{')));
  });

  testWidgets('an untranslated locale falls back to English, not to blank',
      (t) async {
    final es = await load(t, 'es');
    // No Spanish translation exists for this key yet.
    expect(es.alarmsAlarmForRemoved('Aspirin'), contains('Aspirin'));
    expect(es.alarmsAlarmForRemoved('Aspirin'), isNotEmpty);
    // A key that *is* translated must still be Spanish.
    expect(es.adherenceLabel, 'ADHERENCIA');
  });
}
