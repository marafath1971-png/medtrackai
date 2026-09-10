import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/core/constants/med_ai_assets.dart';
import 'package:medai/models/constants.dart';
import 'package:medai/screens/loading/loading_screen.dart';
import 'package:medai/widgets/common/ghost_mascot.dart';
import 'package:medai/l10n/app_localizations.dart';

/// The loading and lock screens are the two surfaces every user sees before
/// they can do anything — a cold start and a locked app. Both showed generic
/// chrome: a stock onboarding illustration, and a red error glyph over red body
/// copy that made a dismissed biometric prompt look like the health data itself
/// had failed. Both now use the app's own mascot set.
void main() {
  group('LoadingScreen', () {
    testWidgets('shows an animated mascot, not a stock illustration',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LoadingScreen(),
      ));
      await tester.pump(const Duration(milliseconds: 600));

      final mascot = tester.widget<GhostMascot>(find.byType(GhostMascot));
      expect(mascot.asset, MedAiAssets.mascotMedsBottle);
      expect(mascot.showGlow, isTrue);

      // No pumpAndSettle: the mascot idle float loops forever by design.
    });

    testWidgets('still names the app and its state', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LoadingScreen(),
      ));
      await tester.pump(const Duration(milliseconds: 600));

      // Renamed: the wordmark follows kAppName rather than a literal, so
      // this asserts the constant and not the string it happens to hold.
      expect(find.text(kAppName), findsOneWidget);
      expect(find.text('Preparing your health workspace'), findsOneWidget);

      // No pumpAndSettle: the mascot idle float loops forever by design.
    });
  });

  group('mascot assets are real files', () {
    // GhostMascot falls back to a tinted disc when a PNG is missing, so a typo
    // in a constant degrades silently to exactly the generic blob these screens
    // were redesigned to remove.
    test('every mascot referenced by these screens is bundled', () {
      for (final asset in [
        MedAiAssets.mascotMedsBottle,
        MedAiAssets.mascotShieldGuard,
        MedAiAssets.mascotSearchTime,
      ]) {
        expect(File(asset).existsSync(), isTrue,
            reason: '$asset is referenced by a screen but not on disk');
      }
    });

    test('the mascot directory is declared in pubspec', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();

      expect(pubspec.contains('assets/mascots/'), isTrue,
          reason: 'present on disk but unbundled renders the fallback disc on '
              'a real device while tests still pass');
    });
  });
}
