import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:medai/core/utils/invite_link.dart';
import 'package:medai/models/constants.dart';

/// A deep link needs four separate files to agree, and none of them can import
/// the others: the Dart builder, the Android manifest, the iOS entitlement,
/// and the two hosted association files. When they disagree nothing errors —
/// the link quietly opens a browser, and the caregiver being invited (who by
/// definition does not have the app yet) never gets in.
///
/// That is what shipped. `assetlinks.json` claimed `com.medai.app` while every
/// build of this app has been `com.medtracker.medtrackaiflutter`, the Apple
/// `appID` was the literal string `TEAMID.com.medai.app`, and there was no
/// intent-filter or associated-domains entitlement at all.
///
/// These read the real files rather than restating their contents, so editing
/// one side without the other fails here instead of in the store.
/// Returns the skip reason when [isPlaceholder], or null to run the test.
///
/// The check goes live automatically the moment the real value lands — there
/// is no second edit to forget.
Object? _placeholderSkip(bool isPlaceholder, String reason) =>
    isPlaceholder ? reason : null;

List<String> _assetlinksFingerprints() {
  final json =
      jsonDecode(_read('public/.well-known/assetlinks.json')) as List<dynamic>;
  final target =
      (json.first as Map<String, dynamic>)['target'] as Map<String, dynamic>;
  return (target['sha256_cert_fingerprints'] as List<dynamic>).cast<String>();
}

String _aasaAppId() {
  final aasa =
      jsonDecode(_read('public/.well-known/apple-app-site-association'))
          as Map<String, dynamic>;
  final details =
      ((aasa['applinks'] as Map<String, dynamic>)['details'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
  return details.first['appID'] as String;
}

String _read(String relative) {
  final f = File(relative);
  if (!f.existsSync()) {
    fail('missing $relative — deep links cannot verify without it');
  }
  return f.readAsStringSync();
}

void main() {
  group('Android App Links', () {
    late String manifest;

    setUp(() => manifest =
        _read('android/app/src/main/AndroidManifest.xml'));

    test('an autoVerify intent-filter exists for the invite host', () {
      expect(manifest.contains('android:autoVerify="true"'), isTrue,
          reason: 'without autoVerify Android never checks assetlinks.json, '
              'so the link opens a browser');
      expect(manifest.contains('android:host="$kInviteHostname"'), isTrue,
          reason: 'the manifest host must match kInviteHostname');
    });

    test('every path LinkService handles is routed', () {
      // LinkService._handleUri switches on these first segments; a prefix the
      // manifest omits never reaches the app at all.
      for (final prefix in ['/j', '/join', '/r', '/ref']) {
        expect(manifest.contains('android:pathPrefix="$prefix"'), isTrue,
            reason: 'LinkService parses $prefix but the manifest drops it');
      }
    });

    test('assetlinks names the package this app actually builds as', () {
      final json = jsonDecode(_read('public/.well-known/assetlinks.json'))
          as List<dynamic>;
      final target = (json.first as Map<String, dynamic>)['target']
          as Map<String, dynamic>;

      expect(target['package_name'], kAndroidApplicationId,
          reason: 'this named com.medai.app while the app ships as '
              '$kAndroidApplicationId, so verification could never succeed');
    });

    test('the signing fingerprint is not a placeholder', () {
      final json = jsonDecode(_read('public/.well-known/assetlinks.json'))
          as List<dynamic>;
      final target = (json.first as Map<String, dynamic>)['target']
          as Map<String, dynamic>;
      final prints =
          (target['sha256_cert_fingerprints'] as List<dynamic>).cast<String>();

      expect(prints, isNotEmpty);
      for (final p in prints) {
        expect(RegExp(r'^[0-9A-F]{2}(:[0-9A-F]{2}){31}$').hasMatch(p), isTrue,
            reason: 'a SHA-256 fingerprint is 32 colon-separated hex bytes');
      }
    },
        // Skipped, not failing: the value needs the upload keystore, which is
        // yours alone. The skip reason prints on every run, so it stays
        // visible instead of rotting into a red test everyone ignores. Delete
        // this line once the fingerprint is in and the check goes live.
        skip: _placeholderSkip(
            _assetlinksFingerprints().any((p) => p.startsWith('REPLACE_WITH_')),
            'assetlinks carries a placeholder fingerprint — run `keytool -list '
            '-v -keystore <upload.jks>` and paste the SHA-256, or take the one '
            'Play App Signing generates'));
  });

  group('iOS Universal Links', () {
    test('the associated-domains entitlement covers the invite host', () {
      final ent = _read('ios/Runner/Runner.entitlements');

      expect(ent.contains('com.apple.developer.associated-domains'), isTrue,
          reason: 'without this key iOS never fetches the association file');
      expect(ent.contains('applinks:$kInviteHostname'), isTrue);
    });

    test('the entitlements file is actually wired into the build', () {
      // An entitlements file Xcode never reads is inert. Runner.entitlements
      // sat unreferenced by project.pbxproj, so neither associated-domains nor
      // App Attest reached the binary — the file looked right and did nothing.
      final pbx = _read('ios/Runner.xcodeproj/project.pbxproj');

      expect(pbx.contains('CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;'),
          isTrue,
          reason: 'project.pbxproj does not reference Runner.entitlements, so '
              'every key in it is ignored at build time');

      // Debug, Release and Profile: a release-only wiring still breaks
      // TestFlight, and a debug-only one breaks the App Store build.
      expect(
          RegExp(r'CODE_SIGN_ENTITLEMENTS = Runner/Runner\.entitlements;')
              .allMatches(pbx)
              .length,
          3,
          reason: 'all three Runner configurations must carry the entitlements '
              'path, or attestation silently differs between build types');
    });

    test('the association file names this bundle id', () {
      final aasa = jsonDecode(
              _read('public/.well-known/apple-app-site-association'))
          as Map<String, dynamic>;
      final details = ((aasa['applinks'] as Map<String, dynamic>)['details']
              as List<dynamic>)
          .cast<Map<String, dynamic>>();

      expect(details, isNotEmpty);
      final appId = details.first['appID'] as String;

      expect(appId.endsWith('.$kAndroidApplicationId'), isTrue,
          reason: 'appID must be <TeamID>.$kAndroidApplicationId; it read '
              'TEAMID.com.medai.app, where both halves were wrong');
    });

    test('the team id is filled in', () {
      final aasa = jsonDecode(
              _read('public/.well-known/apple-app-site-association'))
          as Map<String, dynamic>;
      final details = ((aasa['applinks'] as Map<String, dynamic>)['details']
              as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final appId = details.first['appID'] as String;
      final teamId = appId.split('.').first;

      expect(RegExp(r'^[A-Z0-9]{10}$').hasMatch(teamId), isTrue,
          reason: 'an Apple Team ID is 10 alphanumeric characters');
    },
        // Skipped for the same reason as the Android fingerprint: the value
        // comes from your Apple Developer membership page.
        skip: _placeholderSkip(_aasaAppId().startsWith('REPLACE_WITH_'),
            'apple-app-site-association carries a placeholder team id — copy '
            'it from the Apple Developer membership page'));

    test('every path LinkService handles is claimed', () {
      final aasa = jsonDecode(
              _read('public/.well-known/apple-app-site-association'))
          as Map<String, dynamic>;
      final details = ((aasa['applinks'] as Map<String, dynamic>)['details']
              as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final paths = (details.first['paths'] as List<dynamic>).cast<String>();

      for (final p in ['/j', '/join']) {
        expect(paths.any((x) => x == p || x == '$p/*'), isTrue,
            reason: 'invites arrive on $p');
      }
      expect(paths.any((x) => x.startsWith('/r')), isTrue,
          reason: 'referral links arrive on /r');
    });
  });

  group('the links the app actually builds are the ones it claims', () {
    test('an invite link is covered by the Android intent-filter', () {
      final uri = Uri.parse(inviteJoinUrl('AB3K9P'));
      final manifest = _read('android/app/src/main/AndroidManifest.xml');

      expect(uri.scheme, 'https');
      expect(uri.host, kInviteHostname);
      expect(manifest.contains('android:pathPrefix="/${uri.pathSegments.first}"'),
          isTrue,
          reason: 'inviteJoinUrl builds /${uri.pathSegments.first} but the '
              'manifest does not route it');
    });

    test('the legal URLs sit on the same verified host', () {
      // Not deep links, but they share the domain: if it moves, these move too.
      for (final url in [kPrivacyPolicyUrl, kTermsOfServiceUrl]) {
        expect(Uri.parse(url).host, kInviteHostname,
            reason: 'a policy URL on an unowned domain fails Play review');
      }
    });
  });
}
