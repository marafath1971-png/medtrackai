import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/screens/settings/widgets/delete_account_dialog.dart';
import 'package:medai/theme/med_ai_ui.dart';
import 'package:medai/l10n/app_localizations.dart';

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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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

  group('every delete path uses it', () {
    test('no screen keeps its own destructive dialog', () {
      // A third implementation lived in app_tab and was missed by the first
      // audit — its "Delete" button showed "Account scheduled for deletion
      // within 30 days." and then did nothing at all. A user who wanted their
      // health data erased was told it would be, and it stayed.
      for (final path in [
        'lib/screens/home/widgets/settings/profile_tab.dart',
        'lib/screens/home/widgets/settings/app_tab.dart',
      ]) {
        final src = File(path).readAsStringSync();

        expect(src.contains('DeleteAccountDialog.show'), isTrue,
            reason: '$path should delegate to the shared confirmation');
      }
    });

    test('no delete path fakes the outcome with a toast', () {
      final src =
          File('lib/screens/home/widgets/settings/app_tab.dart').readAsStringSync();

      // Match the toast call, not the phrase: the comment explaining the bug
      // legitimately mentions it.
      expect(src.contains("AppFeedback.toast(context, 'Account scheduled"), isFalse,
          reason: 'claiming a deletion that never happens is worse than '
              'refusing to offer one');
    });

    test('the sub-page no longer duplicates account actions', () {
      // global_settings_screen is reached *through* profile_tab, so a user met
      // the same destructive action twice on one journey, backed by different
      // code.
      final src =
          File('lib/screens/settings/global_settings_screen.dart').readAsStringSync();

      expect(src.contains("title: 'Delete Account Permanently'"), isFalse);
      expect(src.contains("title: 'Export Health Data (CSV)'"), isFalse);
    });
  });
}
