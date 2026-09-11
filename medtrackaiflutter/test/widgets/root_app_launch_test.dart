import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/l10n/app_localizations.dart';

/// The app's root widget builds ABOVE its own MaterialApp, so anything it reads
/// from the enclosing context has no Localizations and no Directionality
/// ancestor.
///
/// `AppLocalizations.of(context)!` lived in that enclosing build for four
/// commits. The null check threw on every launch, the error boundary caught it,
/// and the boundary's own fallback Text — also lacking Directionality — painted
/// nothing. The app opened to a pure black screen on a real device while the
/// entire widget-test suite stayed green, because no test built the root the
/// way runApp does.
///
/// This pins the shape rather than the symptom: a widget that returns a
/// MaterialApp must not read localizations from the context it was given.
void main() {
  testWidgets('a root widget cannot read l10n above its own MaterialApp',
      (tester) async {
    await tester.pumpWidget(_BadRoot());

    // Reproduces the shipped failure: the lookup runs before any Localizations
    // ancestor exists.
    expect(tester.takeException(), isA<TypeError>());
  });

  testWidgets('onGenerateTitle resolves the title below the MaterialApp',
      (tester) async {
    await tester.pumpWidget(_GoodRoot());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('inside'), findsOneWidget);
  });
}

/// The pattern that shipped broken.
class _BadRoot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MaterialApp(
      title: l10n.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Text('inside'),
    );
  }
}

/// The fix: the title is resolved with a context below the app.
class _GoodRoot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: Text('inside')),
    );
  }
}
