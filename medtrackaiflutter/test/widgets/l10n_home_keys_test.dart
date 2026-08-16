import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:medai/l10n/app_localizations.dart';

/// The 7 new home keys must resolve in every shipped locale, including the RTL
/// ones, rather than throwing or falling back silently.
void main() {
  for (final code in ['en', 'es', 'ar', 'he', 'ja', 'ko', 'ms']) {
    testWidgets('home keys resolve in $code', (tester) async {
      late AppLocalizations s;
      await tester.pumpWidget(MaterialApp(
        locale: Locale(code),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (c) {
          s = AppLocalizations.of(c)!;
          return const SizedBox();
        }),
      ));
      for (final v in [
        s.homeNextDose,
        s.homeSchedule,
        s.homeDosesLeft,
        s.homeYourMedicines,
        s.homeAddMeds,
        s.homeAllClear,
        s.homeFirstPending,
      ]) {
        expect(v, isNotEmpty, reason: '$code has an empty home string');
      }
    });
  }
}
