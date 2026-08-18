import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The paywall showed "Subscription plans are currently unavailable" with a
/// dead "Unavailable" button, so nobody could pay. It was not a code fault:
/// .env still carries the template value `demo_purchases_key`, so
/// PurchasesService rejects it, never configures the SDK, and
/// getAvailablePackages() returns [] before it ever reaches RevenueCat.
///
/// The rejection was right; the reporting was not. The build logged the key
/// verbatim (fine for a placeholder, a secret leak the moment a real one lands)
/// and told the user to "try again later" about a state no amount of retrying
/// can change.
void main() {
  group('the placeholder key is still in .env', () {
    // Not a failure — a standing reminder. Flipping to a real key is a launch
    // blocker only the account owner can clear, and this test names it.
    test('billing cannot work until PURCHASES_API_KEY is replaced', () {
      final env = File('.env');
      if (!env.existsSync()) {
        markTestSkipped('.env not present in this checkout');
        return;
      }

      final line = env
          .readAsLinesSync()
          .firstWhere((l) => l.startsWith('PURCHASES_API_KEY='),
              orElse: () => '');
      final value = line.split('=').skip(1).join('=').trim();

      if (value.isEmpty || value.toLowerCase().contains('demo')) {
        markTestSkipped(
            'PURCHASES_API_KEY is "$value" — the RevenueCat placeholder. '
            'In-app purchases are disabled until a real goog_/appl_ key from '
            'the RevenueCat dashboard replaces it.');
        return;
      }

      // Once a real key is in place, hold it to RevenueCat's shape.
      expect(
        value.startsWith('goog_') ||
            value.startsWith('appl_') ||
            value.startsWith('public_'),
        isTrue,
        reason: 'RevenueCat public keys start with goog_, appl_ or public_',
      );
      expect(value.length, greaterThan(25));
    });
  });

  group('secrets stay out of the log', () {
    test('the API key is never logged verbatim', () {
      // `appLogger.i('... Resolved API Key is "$key"')` printed the key into
      // logcat, which is readable by anyone with the device plugged in.
      final src = File('lib/services/purchases_service.dart').readAsStringSync();

      expect(src.contains(r'API Key is "$key"'), isFalse,
          reason: 'logging the raw key leaks it as soon as it is real');
    });

    test('no other service logs a raw key', () {
      final offenders = <String>[];

      void walk(Directory dir) {
        for (final e in dir.listSync()) {
          if (e is Directory) {
            walk(e);
          } else if (e.path.endsWith('.dart')) {
            final src = File(e.path).readAsStringSync();
            for (final line in src.split('\n')) {
              final t = line.trimLeft();
              if (t.startsWith('//') || t.startsWith('///')) continue;
              // Only credential-shaped names. A bare `$key` is usually a map
              // or SharedPreferences key — local_prefs_datasource logs one
              // when decryption fails, which is a useful debug breadcrumb and
              // not a secret.
              final logsKey = RegExp(
                      r'appLogger\.\w+\([^)]*\$_?\w*(apiKey|ApiKey|API_KEY|secret|Secret|token|Token)\b')
                  .hasMatch(line);
              if (logsKey) offenders.add('${e.path}: ${line.trim()}');
            }
          }
        }
      }

      walk(Directory('lib'));

      expect(offenders, isEmpty,
          reason: 'API keys must never reach logcat');
    });
  });
}
