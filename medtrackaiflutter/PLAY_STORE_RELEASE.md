# Play Store release checklist

Status as of 2026-08-15. Package: `com.medtracker.medtrackaiflutter`, version `1.0.0+1`.

## 1. Signing key — YOU must do this

The upload keystore is **permanent**: if it is lost, you can never publish an update to
this app again. It is created with passwords you choose, so generate it yourself rather
than having it created for you.

```bash
keytool -genkey -v -keystore ~/medtrackai-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Then write `android/key.properties` (already gitignored):

```
storePassword=<your password>
keyPassword=<your password>
keyAlias=upload
storeFile=/Users/<you>/medtrackai-upload.jks
```

**Back up the `.jks` file and passwords** somewhere durable (password manager + offline
copy). Consider enrolling in Play App Signing so Google holds the app signing key and
this one is only the upload key — that makes key loss recoverable.

`android/app/build.gradle.kts` is already wired: it reads `key.properties` and falls back
to **debug signing** when the file is absent. A debug-signed bundle is rejected by Play,
so this file must exist before you build the release you intend to upload.

## 2. Build the bundle

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab` — this is what you upload.
Release builds already have minify + resource shrinking enabled.

Verify it is signed with your key, not the debug key:

```bash
jarsigner -verify -verbose:summary build/app/outputs/bundle/release/app-release.aab
```

A correct build prints your own `CN=`. **A build made without `key.properties` prints
`CN=Android Debug`** — that bundle is rejected by Play. This was confirmed on the
2026-08-15 build, which came out debug-signed because the keystore did not exist yet.

### About the bundle size

The `.aab` is ~119 MB, but **that is not the size users download.** Roughly 92 MB of it
is `BUNDLE-METADATA/` — a 55 MB ProGuard mapping file plus ~85 MB of native debug symbols
that Play uses for crash deobfuscation and never ships to devices.

Actual per-device install content:

| Component | Size |
|---|---|
| shared (dex + assets + res) | ~37 MB |
| native libs, arm64-v8a | ~33 MB |
| native libs, armeabi-v7a | ~30 MB |
| native libs, x86_64 | ~36 MB |

So a typical arm64 phone pulls ~70 MB uncompressed, less after Play's compression. That is
normal for a Flutter app carrying Firebase, ML barcode scanning, and Rive. Play's limit is
150 MB, so there is comfortable headroom.

Optional trims if you want it smaller:
- **Drop `x86_64`** (~36 MB) — it only serves emulators and some Chromebooks:
  `flutter build appbundle --release --target-platform android-arm,android-arm64`
- `assets/mascots` is 7.6 MB and `assets/photos` 5.4 MB; compressing those is the main
  asset-side win.

## 3. Play Console declarations this app specifically needs

These are the ones most likely to cause a rejection here:

- **`SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`** — requires an exact-alarm declaration.
  Medication reminders are an accepted justification; say so explicitly.
- **Health Connect permissions** (steps, heart rate, sleep, blood glucose, blood
  pressure) — triggers Play's health-data review. You must declare each data type, its
  purpose, and confirm you do not sell it.
- **`CAMERA`** — justify as medication/pill scanning.
- **`RECORD_AUDIO`** — justify as voice logging. If the voice feature is not shipping in
  v1, **remove this permission**; unjustified mic access is a common rejection.
- **Data safety form** — must match reality: what you collect (health data, account
  info), whether it is encrypted in transit, and whether users can request deletion. The
  app has Firebase auth + Firestore, so answer accordingly.
- **Privacy policy URL** — currently `https://medai.app/privacy` (`lib/models/constants.dart`).
  **This must be live and publicly reachable before submission** or the listing is rejected.

## 4. Store listing assets needed

- App icon 512×512 PNG
- Feature graphic 1024×500
- At least 2 phone screenshots (4–8 recommended), 16:9 or 9:16
- Short description (80 chars) and full description (4000 chars)
- Content rating questionnaire
- Target audience declaration — if under 13 is included, extra Families policy applies

## 5. Known gaps to fix before launch

- [ ] **No adaptive icon.** `mipmap-anydpi-v26/` is missing, so on Android 8+ the launcher
      icon renders in a plain white circle instead of being properly masked. Add
      `ic_launcher_foreground` + background and an `anydpi-v26` XML.
- [ ] **Photo assets** — see `PHOTO_SOURCING_BRIEF.md`. Three bundled photos are wrong for
      their screens, and one shows a clinician with a visible hospital badge, which is an
      IP/privacy risk in a published app.
- [ ] **Version bump** — `pubspec.yaml` is still `1.0.0+1`. Each upload needs a unique,
      increasing `versionCode` (the `+N`).
- [ ] **Verify the privacy policy URL resolves.**
- [ ] **Decide on `RECORD_AUDIO`** — keep and justify, or remove for v1.

## 6. Recommended rollout

Upload to **internal testing** first, install on a real device from Play, and confirm
notifications, exact alarms, and the scan flow work from a store build (not just a local
one). Then promote to closed → open → production.
