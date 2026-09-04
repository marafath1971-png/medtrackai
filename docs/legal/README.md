# Hosted legal pages

`privacy.html` and `terms.html` are **generated** from the in-app screens:

- `lib/screens/settings/privacy_policy_screen.dart`
- `lib/screens/settings/terms_of_service_screen.dart`

The Dart screens are the source of truth. Edit those, then regenerate — do not
hand-edit the HTML, or the app and the hosted page start making two different
promises about the same data, which is the compliance problem rather than a
formatting one. `test/legal/policy_parity_test.dart` fails if they drift.

## Why these exist

Play requires a **publicly reachable** privacy policy URL for any app handling
health data, and this app requests health, camera, microphone and activity
permissions. The app already points at `https://medai.app/privacy`, but that
domain is currently **parked** — every path returns HTTP 200 and redirects to a
registrar sales page. An automated check sees 200 and passes; a human reviewer
sees a domain for sale.

## To go live

1. Host both files at the paths already compiled into the app:
   - `https://medai.app/privacy`
   - `https://medai.app/terms`
2. Confirm they return the real content, not the `/lander` redirect.
3. Paste the privacy URL into the Play Console listing.

Any static host works (GitHub Pages, Cloudflare Pages, Firebase Hosting). If
the domain changes, update `kPrivacyPolicyUrl` / `kTermsOfServiceUrl` in
`lib/models/constants.dart` — they are referenced from the paywall, the auth
screen, settings and both policy screens.
