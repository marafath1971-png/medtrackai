import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// `.env` is gitignored, so a release built from a clean checkout picks up no
/// key at all. Every downstream billing failure is silent by design — the
/// paywall reads "Not available yet" and the user simply cannot pay — so the
/// only place this can be caught is at startup.
void main() {
  group('the release build refuses to ship with billing off', () {
    late String main_;
    late String svc;

    setUpAll(() {
      main_ = File('lib/main.dart').readAsStringSync();
      svc = File('lib/services/purchases_service.dart').readAsStringSync();
    });

    test('startup checks for a sellable key in release mode', () {
      expect(main_.contains('kReleaseMode'), isTrue);
      expect(main_.contains('PurchasesService.hasSellableKey'), isTrue,
          reason: 'nothing would notice a placeholder key otherwise');
    });

    test('the failure is reported, not just printed', () {
      // debugPrint is stripped from release output; this has to reach
      // Crashlytics to be seen at all.
      final i = main_.indexOf('kReleaseMode && !PurchasesService');
      expect(i, greaterThan(-1));
      expect(main_.substring(i, i + 400).contains('FlutterError.reportError'),
          isTrue);
    });

    test('a compile-time key overrides the gitignored .env', () {
      // CI has no .env, so String.fromEnvironment must be consulted first.
      expect(svc.contains("String.fromEnvironment('RC_GOOGLE_KEY')"), isTrue);
      expect(svc.contains("String.fromEnvironment('RC_APPLE_KEY')"), isTrue);

      final g = svc.indexOf('static String get _googleApiKey');
      final body = svc.substring(g, g + 300);
      expect(body.indexOf('_defineGoogle'), lessThan(body.indexOf('dotenv')),
          reason: 'the dart-define must win over .env, not the other way round');
    });

    test('known placeholders are rejected', () {
      final i = svc.indexOf('static bool _isValidKey');
      final body = svc.substring(i, i + 900);
      for (final word in ['demo', 'dummy', 'placeholder']) {
        expect(body.contains("'$word'"), isTrue,
            reason: '$word must not read as a sellable key');
      }
    });

    test('a real-looking key is still required to be long enough', () {
      final i = svc.indexOf('static bool _isValidKey');
      final body = svc.substring(i, i + 1200);
      expect(RegExp(r'length\s*>=?\s*\d\d').hasMatch(body), isTrue,
          reason: 'a bare "goog_" prefix must not pass as configured');
    });
  });
}
