import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// App Check enforcement denies every Firestore request when the client has no
/// valid attestation, and the error is PERMISSION_DENIED — indistinguishable
/// from a security-rules bug. That cost a long debugging detour on the
/// caregiver invite, so the misconfiguration now announces itself.
void main() {
  late String main_;

  setUpAll(() => main_ = File('lib/main.dart').readAsStringSync());

  test('the debug token is not hardcoded', () {
    // It was committed in source: only usable against debug builds, but
    // anyone with the repo could pass App Check on this project with it.
    expect(RegExp(r"debugToken:\s*'[0-9A-Fa-f-]{8,}'").hasMatch(main_), isFalse,
        reason: 'the debug token must come from the build, not the repo');
    expect(main_.contains("String.fromEnvironment('APP_CHECK_DEBUG_TOKEN')"),
        isTrue);
  });

  test('a missing debug token is reported, not silent', () {
    // Silence here reads as a rules bug for as long as it takes to check
    // App Check, which is not an obvious place to look.
    expect(main_.contains('APP CHECK: no debug token'), isTrue);
    expect(main_.contains('PERMISSION_DENIED'), isTrue,
        reason: 'the warning should name the symptom it explains');
  });

  test('production still uses real attestation providers', () {
    // The debug provider must never be the release path.
    expect(main_.contains('AndroidPlayIntegrityProvider()'), isTrue);
    expect(main_.contains('AppleAppAttestProvider()'), isTrue);

    final i = main_.indexOf('AndroidDebugProvider');
    final before = main_.substring((i - 200).clamp(0, main_.length), i);
    expect(before.contains('kDebugMode'), isTrue,
        reason: 'debug attestation must be gated on debug builds');
  });

  test('the deploy target is pinned', () {
    // No .firebaserc meant `firebase deploy` had no default project, so two
    // rules deploys silently went nowhere near this app.
    final rc = File('.firebaserc');
    expect(rc.existsSync(), isTrue);
    // The id itself is pinned by firebase_project_consistency_test, which
    // compares .firebaserc against what the app actually connects to. Naming
    // a literal here just breaks on every project move.
    expect(rc.readAsStringSync().contains('"default"'), isTrue);
  });
}
