# Play Console — Data Safety answers

Draft answers for the Data Safety form, checked against the shipped code. Play compares
these against observed app behaviour, so every "no" below needs to stay true.

Verify each line before submitting — if a feature changes, this form must change with it.

## Does your app collect or share any of the required user data types?

**Yes.** The app signs users in and syncs their data to Firebase.

---

## Personal info

| Type | Collected | Shared | Purpose | Optional? |
|---|---|---|---|---|
| Name | Yes | No | App functionality (profile, caregiver display) | Required |
| Email address | Yes | No | Account management (Firebase Auth) | Required |
| User IDs | Yes | No | App functionality, analytics | Required |

Source: `domain/entities/user_profile.dart`, `services/auth_service.dart`,
Firestore `users` collection.

## Health and fitness

| Type | Collected | Shared | Purpose | Optional? |
|---|---|---|---|---|
| Health info | Yes | No | App functionality (the core medication log) | Required |

Covers medications, doses, adherence history, symptoms, and any Health Connect data the
user opts into. Firestore collections: `medicines`, `history`, `caregivers`,
`dependents`. Health Connect reads (steps, heart rate, sleep, blood glucose, blood
pressure) are handled in `providers/controllers/health_controller.dart:48-53` and are
**opt-in via the system permission prompt**.

## App activity

| Type | Collected | Shared | Purpose | Optional? |
|---|---|---|---|---|
| App interactions | Yes | No | Analytics | Required |

Firebase Analytics events only — e.g. `medicine_scan`, `subscription_start`,
`care_invite_sent` (`services/analytics_service.dart`). Keyed to the anonymous Firebase
UID via `setUserId`, not to a name or email.

## App info and performance

| Type | Collected | Shared | Purpose | Optional? |
|---|---|---|---|---|
| Crash logs | Yes | No | Diagnostics | Required |
| Diagnostics | Yes | No | Diagnostics | Required |

Firebase Crashlytics (`main.dart:84-88`).

## Photos

| Type | Collected | Shared | Purpose | Optional? |
|---|---|---|---|---|
| Photos | Yes | No | App functionality (medicine scanning) | Optional |

Scan images are sent to the `geminiProxy` Cloud Function for recognition
(`services/gemini_service.dart:124`). **Declare this** — it is a network transfer, even
though the image is not retained in a user-visible gallery. Confirm with your backend
whether the function persists the image; if it does, that changes the retention answer.

## Audio — NOT collected

**Answer "no" to audio recordings.** Voice logging uses on-device speech-to-text:
`services/voice_service.dart` calls `SpeechToText.listen()` and keeps only the
transcribed text. No audio file is written and no audio leaves the device. The resulting
text is covered under Health info.

---

## Security practices

| Question | Answer | Basis |
|---|---|---|
| Is data encrypted in transit? | **Yes** | Firebase SDKs use TLS throughout |
| Can users request data deletion? | **Yes** | Settings → Data & Privacy → Delete All Data; `deleteAccount()` in `auth_controller.dart` |
| Do you follow the Families policy? | Only if you target under-13 | Decide your target audience first |
| Independent security review? | **No** | None has been done |

## Data types deliberately answered "no"

Confirm each still holds at submission:

- **Audio recordings** — on-device transcription only (see above)
- **Precise or approximate location** — no location permission in the manifest
- **Contacts** — no contacts permission; caregivers are added by name and invite code
- **Financial info** — purchases go through Google Play / RevenueCat; the app never
  handles card details
- **Messages, calendar, files** — no such permissions
- **Data shared with third parties** — Firebase and RevenueCat are processors, not
  third-party recipients under Play's definition. Do **not** tick "shared" for them.

## Before you submit

- [ ] Confirm whether `geminiProxy` retains scan images server-side
- [ ] Match these answers to `https://medai.app/privacy` — Play cross-checks them
- [ ] Decide the target audience; under-13 pulls in the Families policy
- [ ] Re-check after any feature change; a stale form is a compliance problem
