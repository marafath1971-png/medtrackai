import 'package:flutter_test/flutter_test.dart';
import 'package:medai/main.dart';
import 'package:medai/domain/entities/enums.dart';

/// The cold-start auth handoff.
///
/// Observed on a Pixel 7a signed in as "arafat": the home header greeted
/// "Alex" — a stale LOCAL profile — while the profile screen showed the real
/// account. Anything keyed to the uid failed as signed-out, so "Generate QR
/// code" bounced back to Home instead of ever reaching step 2 of the
/// add-caregiver flow.
///
/// Cause: loadProfile() runs at bootstrap, BEFORE Firebase has restored the
/// stored session, so UserRepositoryImpl.getProfile() sees no auth and falls
/// back to the local profile. Firebase then restores the session and
/// authStateChanges emits the real uid — but the reload was gated two ways
/// that both failed:
///
///   1. `_lastKnownUid` started as null, which equals the null Firebase emits
///      before restoring. First emission looked like "no change".
///   2. The reload only ran `if (phase == AppPhase.app)`.
void main() {
  group('shouldReloadForAuthChange', () {
    test('a restored session after a null first emission reloads', () {
      // The exact device sequence: sentinel -> null -> real uid.
      expect(
        shouldReloadForAuthChange(
            previousUid: kNoUidSeenYet,
            currentUid: null,
            phase: AppPhase.loading),
        isFalse,
        reason: 'the signed-out cold start already loaded from bootstrap',
      );
      expect(
        shouldReloadForAuthChange(
            previousUid: null, currentUid: 'uid-arafat', phase: AppPhase.app),
        isTrue,
        reason: 'gaining a uid must re-resolve the profile from the cloud',
      );
    });

    test('gaining a uid reloads even outside AppPhase.app', () {
      // The phase guard is what let the stale local profile survive: on a slow
      // restore the app is still loading when the uid lands.
      for (final phase in AppPhase.values) {
        expect(
          shouldReloadForAuthChange(
              previousUid: null, currentUid: 'uid-arafat', phase: phase),
          isTrue,
          reason: 'a real uid must reload in $phase, not only in app',
        );
      }
    });

    test('switching accounts reloads', () {
      expect(
        shouldReloadForAuthChange(
            previousUid: 'uid-a', currentUid: 'uid-b', phase: AppPhase.app),
        isTrue,
      );
    });

    test('an unchanged uid does not reload', () {
      expect(
        shouldReloadForAuthChange(
            previousUid: 'uid-a', currentUid: 'uid-a', phase: AppPhase.app),
        isFalse,
        reason: 'every rebuild would otherwise refetch the whole profile',
      );
      expect(
        shouldReloadForAuthChange(
            previousUid: null, currentUid: null, phase: AppPhase.auth),
        isFalse,
      );
    });

    test('signing out of a running app reloads', () {
      expect(
        shouldReloadForAuthChange(
            previousUid: 'uid-a', currentUid: null, phase: AppPhase.app),
        isTrue,
        reason: 'the signed-in profile must not linger after sign-out',
      );
    });
  });
}
