import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Two catch blocks discarded failures that changed what the user gets.
///
/// **The deferred paywall.** When the value-first experiment is on, onboarding
/// writes a `pending_activation_paywall` marker and the shell shows the offer
/// after the first medicine is added. `_maybeShowActivationPaywall` returns
/// early unless that marker reads back true — so if the SharedPreferences
/// write threw, the user never saw a paywall at all. The catch comment claimed
/// it "falls back to gates"; nothing did.
///
/// **Cloud sync.** The medicine and history repositories fall back to local
/// data when the Firestore read fails, which is right. But they logged
/// nothing, so a sync failing while the device reports itself online — expired
/// token, tightened rules, quota — is indistinguishable from working
/// normally, and the user's records quietly stop reaching the cloud.
void main() {
  group('the deferred paywall is not dropped on a storage failure', () {
    late String src;

    setUpAll(() {
      src = File('lib/screens/onboarding/onboarding_flow.dart').readAsStringSync();
    });

    test('a failed defer falls through to showing the paywall', () {
      // The guard is the `deferred` flag: without it, the else-branch was
      // skipped whenever deferPaywall was on, whether or not the write worked.
      expect(src.contains('var deferred = false;'), isTrue);
      expect(src.contains('if (!deferred && mounted && !skipPaywall'), isTrue,
          reason: 'the offer must still appear when it could not be deferred');
    });

    test('the failure is logged rather than swallowed', () {
      final idx = src.indexOf("prefs.setBool('pending_activation_paywall'");
      expect(idx, greaterThan(-1));

      final tail = src.substring(idx, (idx + 900).clamp(0, src.length));
      expect(tail.contains('appLogger.w'), isTrue);
    });

    test('the misleading comment is gone', () {
      expect(src.contains('falls back to gates'), isFalse,
          reason: 'it did not fall back to anything');
    });
  });

  group('cloud sync failures are visible', () {
    test('both repository fallbacks log', () {
      final src = File('lib/data/repositories/medication_repository_impl.dart')
          .readAsStringSync();

      // Previously "// Fallback to local if offline" and "// Offline".
      expect(src.contains('Cloud medicine fetch failed'), isTrue);
      expect(src.contains('Cloud history fetch failed'), isTrue);
    });

    test('falling back to local is still the behaviour', () {
      // The fix is about visibility, not about failing harder: a user offline
      // must keep seeing their medicines.
      final src = File('lib/data/repositories/medication_repository_impl.dart')
          .readAsStringSync();

      expect(src.contains('rethrow'), isFalse,
          reason: 'a cloud outage must not take the local list down with it');
    });
  });
}
