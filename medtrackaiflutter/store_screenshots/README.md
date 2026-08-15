# Store screenshots

Captured 2026-08-15 from an Android emulator (Pixel 3a, API 34) at **1080x2400**,
Play's recommended phone screenshot size — no scaling or cropping applied.

| File | Screen | Suggested caption |
|---|---|---|
| `01_home.png` | Today's doses, progress ring, streak | "Never miss a dose" |
| `02_trends.png` | Adherence trend, streak, weekly stats | "See your streak build" |
| `03_alarms.png` | Active reminders, upcoming dose | "Reminders that reach you" |
| `04_circle.png` | Family / caregiver circle | "Care for the people you love" |

## Why an emulator, not the Pixel 7a

Capture was attempted on the physical device first. It works, but the frame
includes everything on screen: a real WhatsApp message from a named contact
appeared mid-capture, and every shot carried personal notification icons in the
status bar. Those files were deleted rather than shipped into a public listing.
The emulator has no personal accounts, so this cannot happen.

## Not yet captured

- **Scanner viewfinder.** The emulator's camera is a synthetic colour-block test
  pattern, so the scan screen is unusable as a screenshot. Capture this one on a
  real device pointed at an actual medicine box — it is the single most
  compelling shot in the set and worth doing by hand.
- **Medicine detail, insights, and biometric lock** from the listing plan.

## Notes

- These use seeded demo data (profile "Alex", Metformin / Vitamin D /
  Lisinopril / Atorvastatin). Built with `--dart-define=DEV_PREVIEW=true`.
- The status bar renders grey rather than matching the cream background. Cosmetic,
  but a designer may want to crop the bar or set a matching status-bar colour
  before upload.
- Play requires 2-8 phone screenshots; four are here, so the minimum is met.

## Reproducing

```bash
flutter build apk --release --target-platform android-arm64 --dart-define=DEV_PREVIEW=true
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-release.apk
adb -s emulator-5554 exec-out screencap -p > store_screenshots/NAME.png
```
