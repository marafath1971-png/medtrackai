import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// App Check spans three files that cannot see each other: the client picks an
/// attestation provider (`lib/main.dart`), the platform grants the capability
/// that provider needs (`ios/Runner/Runner.entitlements`), and the backend
/// decides whether to demand a token (`functions/index.js`).
///
/// Disagreement is silent and one-sided. `enforceAppCheck: true` with an iOS
/// build that cannot attest means every callable — `geminiProxy`, and so every
/// AI path in the app — is rejected server-side, while Android keeps working.
/// That reads as a backend outage, not a missing entitlement.
String _read(String relative) {
  final f = File(relative);
  if (!f.existsSync()) fail('missing $relative');
  return f.readAsStringSync();
}

void main() {
  group('App Check', () {
    test('the backend enforces it', () {
      expect(_read('functions/index.js').contains('enforceAppCheck: true'),
          isTrue,
          reason: 'these tests exist because enforcement is on; if it was '
              'deliberately turned off, relax them rather than deleting them');
    });

    test('release builds use real attestation providers, not debug ones', () {
      final main = _read('lib/main.dart');

      expect(main.contains('AndroidPlayIntegrityProvider()'), isTrue);
      expect(main.contains('AppleAppAttestProvider()'), isTrue);
      // The debug providers must stay behind kDebugMode; shipping a debug
      // provider means anyone with the token can impersonate the app.
      expect(main.contains('kDebugMode'), isTrue,
          reason: 'debug providers must be gated on kDebugMode');
    });

    test('iOS carries the App Attest entitlement the provider requires', () {
      final ent = _read('ios/Runner/Runner.entitlements');

      // AppleAppAttestProvider cannot produce a token without this key, so
      // with enforcement on every iOS call is rejected. Android needs no
      // equivalent — Play Integrity is entitlement-free.
      expect(
          ent.contains('com.apple.developer.devicecheck.appattest-environment'),
          isTrue,
          reason: 'main.dart activates AppleAppAttestProvider() but the app '
              'has no App Attest entitlement, so iOS can never attest');
    });

    test('the App Attest environment is production', () {
      final ent = _read('ios/Runner/Runner.entitlements');
      final match = RegExp(
              r'<key>com\.apple\.developer\.devicecheck\.appattest-environment</key>\s*<string>([^<]+)</string>')
          .firstMatch(ent);

      expect(match, isNotNull, reason: 'entitlement value is unreadable');
      expect(match!.group(1), 'production',
          reason: 'App Store and TestFlight builds both need "production"; '
              'Xcode substitutes the development service for debug builds');
    });
  });
}
