# Moving MedAI to a new Firebase project

The app currently points at **medai-3ce9c**, which belongs to
`natashahossen71@gmail.com`. The Firebase CLI on this machine is authenticated
as `arafathossain455@gmail.com` and cannot see it, which is why two rules
deploys silently went nowhere.

A new project is a valid answer to that. It is not the cheap one: the account
switch is three commands, while this is a console migration with several steps
only the project owner can perform.

## What is lost

Creating a new project abandons everything in medai-3ce9c:

- **Auth users** — every signed-up account, including the one on the test
  device (`PWvn5fZw…`). Users must sign up again.
- **Firestore data** — medicines, adherence history, symptoms, caregiver
  records. Not recoverable without exporting from the old project first,
  which needs access to the old account anyway.
- **The registered App Check debug token** — must be re-added.
- **Storage objects** — profile photos, scanned medicine images.

If any of that matters, export it *before* switching, which requires signing
in as the owning account — the same login that would fix the problem outright.

## Step 1 — create the project (owner only)

The CLI is blocked from creating cloud projects here, so this is done by you:

```bash
firebase projects:create medai-prod --display-name "MedAI"
```

Or in the console: <https://console.firebase.google.com> → Add project.

Use an account you will still control when the app ships.

## Step 2 — register both apps

The bundle id must match exactly, or nothing will connect:

```
com.medtracker.medtrackaiflutter
```

Register an **Android** app and an **iOS** app under that id.

## Step 3 — regenerate config

```bash
flutterfire configure --project=medai-prod
```

This rewrites all three of:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`

Do not hand-edit them.

## Step 4 — enable the services this app actually uses

All of these are off by default on a new project, and each failure is silent
in a different way:

| Service | Where | Symptom if missed |
|---|---|---|
| Authentication (Google + Email) | Auth → Sign-in method | sign-in fails |
| Cloud Firestore | Firestore → Create database | every read/write denied |
| Storage | Storage → Get started | photo upload fails |
| App Check | App Check → Apps | see step 6 |
| Crashlytics | Crashlytics | no crash reports |
| Remote Config | Remote Config | flags fall back to code defaults |
| Cloud Messaging | Cloud Messaging | no push |

## Step 5 — SHA fingerprints (Android sign-in)

Google sign-in fails without these. Get them:

```bash
cd android && ./gradlew signingReport
```

Add **both** the debug SHA-1 and the release SHA-1 under Project settings →
Your apps → Android → Add fingerprint, then re-download
`google-services.json`.

## Step 6 — App Check

Enforcement rejects unattested clients with `PERMISSION_DENIED`, which is
indistinguishable from a security-rules failure. That ambiguity cost most of a
debugging session on the caregiver invite.

1. Register **Play Integrity** (Android) and **App Attest** (iOS).
2. For debug builds, add a debug token under App Check → Apps → Manage debug
   tokens, then run with:

   ```bash
   flutter run --dart-define=APP_CHECK_DEBUG_TOKEN=<that-uuid>
   ```

3. Leave enforcement **off** until the app works end to end, then turn it on.

`main.dart` warns at startup when a debug build has no token.

## Step 7 — deploy rules and indexes

`.firebaserc` pins the project; update it if the id differs:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

Confirm it prints **Deploy complete!** and names the intended project.

## Step 8 — verify before trusting it

In order, because each depends on the last:

1. Sign up a new account — proves Auth + SHA fingerprints.
2. Add a medicine — proves Firestore write.
3. Add a caregiver and tap Generate QR code — proves the invite rules fix.
4. Scan a box — proves Storage and the Gemini path.

## Unrelated to Firebase

RevenueCat is a separate service and is not affected by any of this. The
placeholder key still means nobody can pay; see the release guard in
`main.dart` and `purchases_service.dart`.
