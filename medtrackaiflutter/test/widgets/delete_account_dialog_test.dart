import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/screens/settings/widgets/delete_account_dialog.dart';
import 'package:medai/theme/med_ai_ui.dart';

/// Permanent account deletion had two confirmations with different safety,
/// and which one a user got depended on how they navigated:
///
/// * profile_tab (behind Home's gear — the route users actually take) showed a
///   plain AlertDialog where "Delete" carried the same visual weight as
///   "Cancel". One stray tap erased every medication record.
/// * global_settings_screen had haptics, a red title and a warning banner, but
///   still deleted on a single tap.
///
/// Both now delegate here, and the destructive button stays disabled until the
/// word DELETE is typed.
Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    );

void main() {
  group('the typed confirmation', () {
    test('accepts the exact word', () {
      expect(DeleteAccountDialog.isConfirmed('DELETE'), isTrue);
    });

    test('tolerates case and surrounding whitespace', () {
      // Mobile keyboards autocapitalise and users paste with spaces; fighting
      // that would push people to tap harder, not think harder.
      expect(DeleteAccountDialog.isConfirmed('delete'), isTrue);
      expect(DeleteAccountDialog.isConfirmed('  Delete  '), isTrue);
    });

    test('rejects anything else', () {
      for (final input in ['', 'DELET', 'DELETEE', 'yes', 'confirm', 'D']) {
        expect(DeleteAccountDialog.isConfirmed(input), isFalse,
            reason: '"$input" must not arm a permanent deletion');
      }
    });
  });

  group('the dialog', () {
    testWidgets('opens with the destructive action disabled', (tester) async {
      await tester.pumpWidget(_host(const DeleteAccountDialog()));
      await tester.pump();

      final button = tester.widget<TextButton>(
        find.ancestor(
          of: find.text('Delete forever'),
          matching: find.byType(TextButton),
        ),
      );

      expect(button.onPressed, isNull,
          reason: 'the destructive choice must never be what a stray tap hits');
    });

    testWidgets('typing the word arms it', (tester) async {
      await tester.pumpWidget(_host(const DeleteAccountDialog()));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'DELETE');
      await tester.pump();

      final button = tester.widget<TextButton>(
        find.ancestor(
          of: find.text('Delete forever'),
          matching: find.byType(TextButton),
        ),
      );

      expect(button.onPressed, isNotNull);
    });

    testWidgets('a partial word does not arm it', (tester) async {
      await tester.pumpWidget(_host(const DeleteAccountDialog()));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'DELE');
      await tester.pump();

      final button = tester.widget<TextButton>(
        find.ancestor(
          of: find.text('Delete forever'),
          matching: find.byType(TextButton),
        ),
      );

      expect(button.onPressed, isNull);
    });

    testWidgets('the safe choice is stated positively', (tester) async {
      // "Cancel" beside "Delete" reads as two equal options. Naming the safe
      // outcome makes the default obvious.
      await tester.pumpWidget(_host(const DeleteAccountDialog()));
      await tester.pump();

      expect(find.text('Keep my account'), findsOneWidget);
    });

    testWidgets('it says the deletion cannot be undone', (tester) async {
      await tester.pumpWidget(_host(const DeleteAccountDialog()));
      await tester.pump();

      expect(find.textContaining('cannot be undone'), findsOneWidget);
    });
  });

  group('both entry points use it', () {
    test('neither screen keeps its own single-tap dialog', () {
      for (final path in [
        'lib/screens/home/widgets/settings/profile_tab.dart',
        'lib/screens/settings/global_settings_screen.dart',
      ]) {
        final src = File(path).readAsStringSync();

        expect(src.contains('DeleteAccountDialog.show'), isTrue,
            reason: '$path should delegate to the shared confirmation');
        expect(src.contains("child: Text('CONFIRM DELETE'"), isFalse,
            reason: '$path still has its own destructive dialog');
      }
    });
  });
}
