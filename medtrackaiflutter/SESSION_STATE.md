# Where the app stands

Written at the end of a long fix session. Everything below is committed; the
tree is clean and the suite is green (415 tests, analyzer clean).

## Launch blockers — all need your accounts

| # | Blocker | Why it blocks |
|---|---------|---------------|
| 1 | **RevenueCat key** | `.env` still holds `demo_purchases_key`. `PurchasesService` correctly rejects it, so `getAvailablePackages()` returns `[]` and the paywall shows "not set up in this build". **Nobody can pay.** Replace with a real `goog_…` key from the RevenueCat dashboard. |
| 2 | **Upload keystore** | Never generate this for you — it is permanent and yours alone. |
| 3 | **8 replacement photos** | `assets/photos/` ships stock images. Each onboarding hero now uses a distinct, subject-matched one, so swapping files at the same paths is all that is needed. |
| 4 | **Privacy policy URL** | Must be live at `https://medai.app/privacy` before Play review. |

Cleared this session: 16 KB page alignment (verified on device) and the
fabricated claims that were a Play policy risk.

## Verified on the Pixel

- Name search, photo scan, voice — all three AI paths returned results
- `Time zone set to Asia/Dhaka` — the zone now resolves, and re-resolves on resume
- No crashes, no ANR, zero 16 KB warnings
- `USE_EXACT_ALARM` and `POST_NOTIFICATIONS` both granted

## NOT verified — the one test still outstanding

**Scan a medicine, then confirm the reminder fires.**

This matters because it is exactly the test that exposed the worst bug of the
session: a medicine added by scanning saved correctly, with its schedule, and
armed no alarm at all (`dumpsys alarm` showed zero). Fixed in 6d7ff73, but the
build carrying that fix was never installed — the device dropped off during
`adb install` and has not been reachable since.

To check it yourself:

    adb shell dumpsys alarm | grep -c medtrackaiflutter

Anything above 0 after adding a medicine means reminders are armed.

Also unverified visually: dark mode in Settings (dc94011 fixed white-on-white
text there, and it has never been seen rendered).

## Known-good but unfinished

- `settings_kit.dart` — shared section/row/toggle widgets, written and
  committed but not yet applied. The settings duplication that motivated it is
  resolved; this is now purely a restyle.
- `ob_conversion.dart` — mascot-based onboarding components, not yet wired into
  the 56-step flow.
- The onboarding funnel is still 56 steps. Only 14 of those steps collect an
  answer the app ever reads; 5 configure anything. Cutting it is the largest
  remaining conversion lever, and was explicitly deferred.

## The bug pattern worth remembering

Most of what was found this session had one shape: **two halves that are each
correct in isolation.** A white card and themed text. A saved preference with
no consumer. A save path that skips the scheduler. None were caught by the
analyzer, the tests, or review — only by running the app and checking what the
device actually did.

The guards added this session encode that: they compare pairs rather than
checking either half alone.
