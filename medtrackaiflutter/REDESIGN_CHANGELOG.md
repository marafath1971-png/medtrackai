# Redesign Implementation — Changelog & QA Checklist

*Everything implemented from PRODUCT_AUDIT_AND_REDESIGN_BLUEPRINT.md. Status: syntax-verified, **not yet compiler-verified** — run `flutter pub get && flutter analyze` before building.*

---

## What changed

### Onboarding (blueprint §6)
- `onboarding_flow.dart`: 40 → **56 steps** following the Eato-style spec; per-step analytics (`onboarding_step_viewed` / `onboarding_completed`); native in-app review at step 51; ATT prompt at step 50 (late, never at launch); Remote-Config step disabling + skip-button gating; paywall headline personalized from the goal answer; first-med method persisted for post-auth activation.
- NEW `widgets/ob_eato_widgets.dart`: year wheel picker, weight ruler with unit toggle + feedback chip, dual wake/sleep sliders, social-proof banner, payoff bars, privacy shield hero.

### Paywall (blueprint §5)
- Annual-first plan sort + default selection; trial-days badge from the real RevenueCat intro offer; per-week price breakdown on annual; personalized headline param; **trial reminder push actually scheduled** on purchase (day before billing); `subscription_start` analytics event now fired on success (was never called); exit-offer downsell to weekly on dismiss (Remote Config, default OFF); weekly plan hideable; trial timeline toggleable.

### Dashboard & Home (blueprint §4, §3.3)
- NEW `dashboard/widgets/adherence_ring_hero.dart`: animated adherence ring + 7-day sparkline + forgiveness-first copy + 100% haptic; wired as dashboard hero.
- `home_tab.dart` decomposed 1,477 → ~460 lines; sections extracted to `home/widgets/` (ring hero, dose group, day toggle, emergency card, quick-log FAB, share CTA); day-part boundaries centralized in `home/dose_grouping.dart`. **Bug fixed**: "next dose" highlight was computed but never passed — now wired.

### Remote Config (blueprint §3.1 — the top revenue gap)
- `firebase_remote_config` added to pubspec; NEW `services/remote_config_service.dart` (12 keys, shipped defaults); non-blocking init in `main.dart`. See EXPERIMENT_RUNBOOK.md for the full key table and first five experiments.

### Revenue leaks closed (found during implementation)
1. **Pill scanner had no scan gate** and `profile.scansUsed` was never incremented → free users had unlimited AI scans. Gated + counted.
2. **Supplement scanner was an unmetered bypass** (same Gemini API, no gate, no counter). Gated + counted.
3. **Med-count limit was never enforced** → `canAddMedicine` getter + gates at all 5 add-med call sites.
4. **`logSubscriptionStart` never called** → Firebase A/B tests had no conversion goal. Now fired.

### Data honesty fixes
- Analytics screen: trend chart showed **hardcoded fake bars** for every user → now real last-7-days from dose history; ring showed adherence×10 fake counts → real today counts.
- Monthly Wrapped: dose total counted skipped/missed entries → only taken; fabricated "Top 5% of users" → honest tiered copy (90%/70% thresholds).

### Retention
- Streak freezes **auto-granted at milestones** ≥7 days (cap 5) — the Duolingo forgiveness mechanic, granted before they're needed.
- First-med activation: onboarding choice deep-links to scanner/search on first home load with an empty cabinet.

---

## Verify before release (manual QA)

1. `flutter pub get` — if `firebase_remote_config ^6.1.0` conflicts, report the error (needs version aligned to your firebase_core 4.x).
2. `flutter analyze` — fix list goes back to Claude.
3. **Onboarding**: complete all 56 steps; check back-navigation; verify rating prompt (step 51) and ATT (step 50) appear once; confirm paywall headline matches your chosen goal; after sign-in, confirm the app opens the scanner (if you chose "Scan it" at step 48) when the cabinet is empty.
4. **Paywall**: annual pre-selected with trial badge + per-week price; buy a sandbox trial → confirm the "trial ends tomorrow" notification is scheduled (day before billing); dismiss the paywall with `paywall_exit_offer_enabled=true` → weekly downsell appears once.
5. **Gates (free account)**: use all 3 scans → 4th blocked with paywall (pill AND supplement scanner); add meds to the limit (5) → 6th blocked from every entry point; 3 voice logs → 4th blocked.
6. **Dashboard/Home**: ring matches real today doses; 7-day bars match history; 100% day triggers haptic celebration; "next dose" highlight appears on the first untaken dose.
7. **Streaks**: hit a 7-day milestone → streak freeze count increases by 1.
8. **kDevPreview**: `lib/main.dart` has `kDevPreview = true` — **must be false for release** (pre-existing flag, unchanged by this work).
9. **iOS permissions (audited ✅)**: `ios/Runner/Info.plist` already declares every usage string the new flow touches — including `NSUserTrackingUsageDescription` for the ATT prompt at onboarding step 50, plus camera/mic/speech/FaceID/Health/photos. No plist changes needed. The Podfile sets no permission-stripping macros (permission_handler default = all handlers compiled), which matches current behavior; `pod install` runs automatically on first iOS build.
10. **Android permissions (audited ✅)**: `AndroidManifest.xml` declares `POST_NOTIFICATIONS` (Android 13+ requirement for the notification primer at step 49 and the trial reminder), `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM` (dose alarms + trial reminder fire on time), `RECEIVE_BOOT_COMPLETED` + boot receiver (scheduled reminders survive reboot), `USE_FULL_SCREEN_INTENT` (alarm-style dose alerts), plus camera/mic/biometric/Health Connect. No manifest changes needed.

## Not done (needs external inputs)
- Attribution SDK (needs AppsFlyer/Adjust key) · discounted exit-offer SKU (RevenueCat dashboard) · Apple win-back offers (App Store Connect) · onboarding strings are hardcoded English while the app ships 8 locales — l10n extraction is a follow-up task.
