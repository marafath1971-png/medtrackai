import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The paywall wrapped its sheet in `Semantics(scopesRoute: true)` without
/// `explicitChildNodes: true`. Flutter asserts on that combination in
/// RenderObject.attach, so presenting the paywall threw and the app dropped
/// into its global error boundary — "Something went wrong. RESTART APP".
///
/// It surfaced when a gated feature (medicine search) tried to show the
/// paywall over the scanner, taking the whole app down rather than the sheet.
///
/// The real overlay needs Provider, RevenueCat and routing to build, so this
/// pins the framework contract that was violated. Any widget in the app
/// combining these flags incorrectly fails the same way.
void main() {
  testWidgets('scopesRoute without explicitChildNodes throws', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Semantics(
            scopesRoute: true,
            namesRoute: true,
            label: 'A route-scoping sheet',
            child: const Text('content'),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNotNull,
        reason: 'this is the exact combination that crashed the app, kept as '
            'the reason the fix below is required rather than cosmetic');
  });

  testWidgets('scopesRoute with explicitChildNodes renders cleanly',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Semantics(
            scopesRoute: true,
            explicitChildNodes: true,
            namesRoute: true,
            label: 'Med AI Pro subscription',
            child: const Text('content'),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('content'), findsOneWidget);
  });

  test('no widget in lib/ sets scopesRoute without explicitChildNodes', () {
    // A guard rather than a unit test: the crash is a compile-clean runtime
    // assertion, so only rendering or a scan like this catches a new instance.
    const dir = 'lib';
    final offenders = <String>[];

    void walk(String path) {
      final entries = Directory(path).listSync();
      for (final e in entries) {
        if (e is Directory) {
          walk(e.path);
        } else if (e.path.endsWith('.dart')) {
          final src = File(e.path).readAsStringSync();
          var i = src.indexOf('scopesRoute: true');
          while (i != -1) {
            // Look at the enclosing Semantics(...) call: take a window after
            // the match and check the sibling flag is present.
            final window = src.substring(
                (i - 400).clamp(0, src.length), (i + 400).clamp(0, src.length));
            if (!window.contains('explicitChildNodes: true')) {
              offenders.add(e.path);
            }
            i = src.indexOf('scopesRoute: true', i + 1);
          }
        }
      }
    }

    walk(dir);

    expect(offenders, isEmpty,
        reason: 'scopesRoute: true requires explicitChildNodes: true, or the '
            'app crashes into its error boundary when that widget renders');
  });
}
