# Scan flow — physical device test

Pixel 7a (Android 17), 2026-08-16, release APK built with `--dart-define=DEV_PREVIEW=true`.
Verified from logs and the accessibility tree only — no screenshots were taken.

## Works

| Step | Evidence |
|---|---|
| Camera permission | `android.permission.CAMERA: granted=true` |
| Camera acquisition | `Active Camera Clients: [(Camera ID: 0 … Client Package Name: com.medtracker.medtrackaiflutter)]` |
| Autofocus / preview | `af_mode=ContinuousPicture`, frames streaming through the HAL |
| Scanner UI | Semantics tree lists Scan Meds, Barcode, Search, Voice, flash, library, close |
| Mode switching | Barcode mode entered; prompt changed to "Aim at barcode" |
| ML Kit barcode engine | `DynamiteModule: Selected local version of com.google.mlkit.dynamite.barcode` |
| Biometric lock | Fingerprint auth completed and unlocked the shell |
| Stability | ~45 min of live use, one PID throughout, **no Flutter exceptions, no RenderFlex overflows, no crash** |

## Not verified

- **No barcode was decoded** during the session and no result screen appeared.
- **AI recognition never returned a result**, for the reason below.

## Blocker: App Check rejects this build

Repeating in logs (9 occurrences during one scan attempt):

```
W FirebaseContextProvider: Error getting App Check token.
  Error: com.google.firebase.FirebaseException: Too many attempts.
```

Cause: `lib/main.dart:64-69` activates App Check with `AndroidPlayIntegrityProvider()`
in release builds. Play Integrity requires the app to be registered in Play Console
with a matching signing certificate. This APK is **debug-signed** (no keystore exists
yet — see `PLAY_STORE_RELEASE.md`), so attestation fails and Firebase backs off.

That matters for scan specifically because AI recognition is proxied through Firebase:

```dart
// lib/services/gemini_service.dart:124
final result = await FirebaseFunctions.instance
    .httpsCallable('geminiProxy')
    .call({...});
```

App Check gates Firebase Functions, so with no valid token the `geminiProxy` call is
rejected. **AI medicine recognition cannot work on an unregistered build** — this is
expected behaviour, not an app defect.

Barcode scanning runs fully on-device via ML Kit and does *not* depend on Firebase, so
it should work regardless; it simply did not get a successful read in this session
(possibly no barcode in frame, focus, or lighting).

## To finish verifying

1. Create the upload keystore and register the app in Play Console (`PLAY_STORE_RELEASE.md` §1).
2. Add the release SHA-256 to Firebase App Check, or enable a debug token for test builds.
3. Re-run: barcode read → result screen → "Add to my meds".

Until then AI scan cannot be exercised on device, and the emulator cannot substitute —
its camera renders a synthetic colour-block test pattern.

## Note for future device testing

`adb shell uiautomator dump` reads Flutter's **semantics tree** and returns every
control label plus exact bounds as text. It is more precise than screenshots for
locating controls (the Scan FAB is at `[446,2117][634,2264]`, centre `540,2190`) and
cannot capture notification content, so prefer it on a personal device.
