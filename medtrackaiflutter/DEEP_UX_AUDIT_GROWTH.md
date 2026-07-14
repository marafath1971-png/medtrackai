# MedTrack AI — Deep UX Audit & Path to Millions

*2026-07-11. Evidence-based analysis of the four core loops — Scan→Understand, Track→Adhere, Remind, Caregiver — plus the growth funnel (onboarding, activation, monetization, referral). Every finding cites real code. This supersedes the cosmetic token audit in `UI_GAP_AUDIT.md`.*

---

## ✅ Shipped so far (2026-07-11)

**9. Monetization switched ON — un-hardcoded `isPremium` (activates everything above)** — the whole paywall stack this session was **dormant** because `AppState.isPremium` hard-returned `true`. Restored it to `profile?.isPremium ?? false` (the profile is written on purchase/restore, which already worked). Critically, added `_reconcilePremium()` — called at launch from `loadFromStorage` — that syncs the cached flag against RevenueCat's *real* entitlement (`PurchasesService.isPremium()`): catches a **lapsed sub** (cached true → real false, closing a revenue leak) and a **cross-device active sub** (false → true). Fail-safe: never revokes premium on an inconclusive/offline check. Dev-preview still works (it seeds `isPremium:true` on its demo profile). File: `app_state.dart`. **This is the switch that turns the value-first paywall, PDF gate, scan quota, and med limits from dormant → live.**

**8. Persistent / escalating reminders — "ring until answered" (research P0, Pillo's differentiator)** — the #1 user-cited need. The reminder engine already had full-screen intent + alarm category + a +2h caregiver escalation, but fired one notification per dose that could be ignored silently. Added Android **FLAG_INSISTENT** (`additionalFlags: Int32List.fromList([4])`) which loops the alarm sound until the user acts on the notification — opt-in via a new `persistent` param on `scheduleWeeklyReminder`/`scheduleAll`, only active with sound on. Driven by `profile.reminderStyle == 'persistent'` at the app_state schedule call sites. New **"Persistent Alarms — ring until you respond"** settings toggle. Also fixed a latent bug: `saveProfile` never rescheduled, so the existing Sound toggle silently didn't take effect — added a public `refreshNotifications()` that both toggles now call. Files: `notification_service.dart`, `app_state.dart`, `app_tab.dart`. (Android-primary; iOS can't loop a notification sound — that's an OS limit, would need a critical-alert entitlement.)

**7. Doctor-ready PDF report — real premium gate + surfaced (retention/upsell hook)** — research flagged this as the #1 P0 addition (MyTherapy's proven hook). The PDF generator already existed (`ExportService`, full clinical layout) but was buried in settings with a **fake** premium gate (toast said "requires Premium" but nothing enforced it). Fixes: `exportAdherenceReport` + `exportAdherenceReportForMember` now actually return `false` when `!isPremium` so the paywall fires; added a prominent **"Share with your doctor"** card on the analytics dashboard (`_DoctorReportCard` + `_shareDoctorReport`, paywalled via `PremiumPaywallOverlay`, triggerSource `doctor_report`); made the `profile_tab` call site premium-aware too. Files: `export_service.dart`, `analytics_dashboard_screen.dart`, `profile_tab.dart`. Dormant paywall until `isPremium` un-hardcoded, but the gate + surfacing are ready.

**1. Discoverable manual "Add medicine" path** — new `lib/core/utils/manual_add_medicine.dart` helper wired to the home empty state ("Or enter it manually") and the scanner search ("Can't find it? Add manually"). Unblocks activation for offline / no-barcode / privacy-averse users. Respects the free-tier gate. New analytics: `GrowthTracker.trackManualAddStarted(source:)`.

**2. Value-first paywall (deferred to post-activation)** — behind Remote Config flag `paywall_after_activation` (default on). The onboarding paywall no longer fires before auth/before any med; instead it fires the moment the user adds their first *real* med (the aha), with the same goal-personalized headline. Files: `remote_config_service.dart` (flag), `onboarding_flow.dart` (`_complete` defers + persists goal), `app_shell.dart` (`_maybeShowActivationPaywall`). Feature-gate paywalls remain the safety net for users who never activate. Dormant until `AppState.isPremium` is un-hardcoded — so no regression risk today.

**⚠️ Not yet compiler-verified** — no Flutter toolchain in the authoring env. Run `flutter pub get && flutter analyze` before building.

**3. Referral loop wired end-to-end** — new `lib/services/referral_service.dart` owns a stable per-user code (secure charset), pending-inbound storage, and one-per-user redemption. Wired: `onReferralDetected` deep-link handler (`app_state.dart`), redemption on first app load (`app_shell.dart._redeemPendingReferral`), a **manual "Have an invite code?"** field at auth (`auth_screen.dart`) so the loop closes even without universal-link infra, and the settings row upgraded to "Invite friends — give a free month" sharing the real code + `/r/<code>` link (`shareReferral` rewritten). Analytics: `referral_sent` / `referral_redeemed`.

  - **Reward grant is intentionally NOT auto-applied** — redemption records attribution + fires the conversion event, but the actual free-month premium grant is left as a documented hook (in `ReferralService`) because a purely client-side grant with no backend is trivially abusable. Wire it to real entitlements when monetization goes live.
  - **Known infra gap (pre-existing):** there is **no deep-link association** configured — no `https://medai.app` intent-filter (Android) or associated-domains (iOS). So `/r/<code>` links won't auto-open the app until that's set up (same limitation the family `/j/` invite already has). The manual code field is the working path until then. **Action item: configure App Links / Universal Links for `medai.app`.**

**4. Scan trust fix (hero result honesty)** — the main scan result no longer overclaims. `ProductAnalysis` gained `identified` + `confidence` fields (safe defaults: `identified=true` for old history, `confidence='low'` so a missing value never reads as confident). The Gemini `analyzeProductInsight` prompt now requires honest self-assessment (set `identified=false`/`confidence=low` when guessing; don't fabricate a drug from a barcode number). In `product_analysis_screen.dart`: the unconditional **"AI verified" badge is replaced** with an honest "AI estimate · {confidence} confidence" / "Not confirmed" label; a **low-confidence/not-identified warning banner** with a "Retake or search again" action appears above the details; and a **persistent medical disclaimer** now closes every result. Files: `product_analysis.dart`, `gemini_service.dart`, `product_analysis_screen.dart`. Reduces app-store-rejection + trust risk. Ships immediately (client-side).

**5. Caregiver alerts + nudges made real (backend + client)** — *audit correction: a `functions/` backend already existed (Node 20, `firebase-functions` v6); the "no backend" claim was wrong.* The gap was that the client never called it and the alerts were console logs. Added two **secure** callables to `functions/index.js`: `alertMyCaregivers` (patient calls it; server resolves the caregiver list from the patient's own subcollection and fans out FCM — client can't target arbitrary users) and `nudgePatient` (caregiver calls it; server verifies the monitoring link before pushing). Wired the client: `social_controller.notifyCaregiversOfMissedDose` now calls `alertMyCaregivers` (was a fake loop); `nudgePatient` now calls the function (was an unread Firestore write) with a direct-write fallback. Added an FCM **foreground handler** + token-refresh listener in `app_state._initPushNotifications` and `NotificationService.showRemoteAlert` so alerts display in-app. `node --check` passes. **Requires `firebase deploy --only functions` by the owner.**

  - **Security note:** the pre-existing `sendMissedDoseAlert` callable lets any authed user push any message to any uid (spoofing hole). The new callables avoid this by never accepting a client-supplied target. Consider removing/locking down `sendMissedDoseAlert`.

**6. Passive missed-dose detection (scheduled) — catches SILENT misses** — the piece that alerts caregivers when a patient just forgets and never opens the app. New `onSchedule` function `detectMissedDoses` in `functions/index.js` runs hourly and, for each patient who has active caregivers, computes the patient's LOCAL time from a stored `utcOffsetMinutes`, finds today's **critical**-med doses that are >90 min overdue with no taken/skipped entry in the day's `entries` array, dedupes per dose (marker doc in the `missedDoseAlerts` collection), and reuses the secure caregiver fan-out to push. Client change: `saveFcmToken` now also writes `utcOffsetMinutes` (refreshed on every token save, so travel/DST stay current) — `firestore_datasource.dart`. `node --check` passes.

  - **Timezone was the crux:** no tz was stored (only `country`); running on UTC would fire "your dad missed his heart meds" at 3am his time. The function **skips any patient with no stored offset** rather than guess — safety over coverage. Existing users get covered once their client saves a token post-update.
  - **Reads the correct `entries` array** (the client's source of truth), not the `doses` array the older `takeDose` writes — avoids false alerts.
  - **Defensive by design:** critical meds only, caregivers-required, 90-min grace, daytime guard, per-dose dedup. Tune the grace window to taste.
  - **Scale caveat:** v1 iterates all users hourly (fine to low-thousands). At scale, gate the scan by a "has active caregivers" index or shard by offset. **Requires `firebase deploy --only functions`.**

---



## The one-sentence verdict

Your app is **built to a high standard but wired for a paid-acquisition business, not a word-of-mouth one** — the features that create millions of users (viral invites, referral loops, activation-before-paywall) are *already coded but disconnected, stubbed, or placed after the paywall*. Fixing "wire it up" is far cheaper than "build it," which is the good news.

## The three patterns behind almost every gap

1. **Built-but-not-connected.** The manual "add medicine" screen, the missed-dose help sheet, the quick-log FAB, the share-invite service, the referral deep-link handler, the streak-freeze button, three home-screen growth cards, and the live-monitoring streams **all exist in the code and are never called.** This is the dominant pattern.
2. **Inverted value curve.** The user is asked for everything (56 onboarding steps, a paywall, an auth wall) *before* experiencing a single scan or reminder — the "aha" is literally the last thing that happens.
3. **Promises without a backend.** There is no server (`functions/` doesn't exist). So caregiver missed-dose alerts, nudges, and remote monitoring — the entire caregiver value prop — are console logs or unread Firestore fields.

---

## P0 — These block growth to millions (fix first)

### Growth funnel
- **Value comes last.** 56 onboarding steps → paywall → auth → *then* first scan. The magic moment sits behind your two highest-friction gates. Move a real "add your first med / one free scan + confetti" step *into* onboarding before the paywall — your own blueprint (`PRODUCT_AUDIT_AND_REDESIGN_BLUEPRINT.md:229`) already specced this; it was never built.
- **Paywall before any value.** `onboarding_flow.dart:157-178` shows the paywall before the user has run a single scan. Gate it on a completed aha instead.
- **No referral loop at all — k-factor ≈ 0.** `shareReferral()` exists with zero callers; `onReferralDetected` is parsed then dropped (`link_service.dart:18`, never assigned in `app_state.dart`). "Share your streak" cards carry a bare URL — no code, no incentive, no attribution. This is the single highest-leverage gap for reaching millions.

### Caregiver (your strongest network-effect feature — currently hollow)
- **Missed-dose alerts are fake.** `notifyCaregiversOfMissedDose` (`social_controller.dart:224`) only writes log lines. The whole reason a caregiver installs — "I'll know if Mom misses her heart med" — does not work. Needs a Cloud Function + FCM (tokens are already saved).
- **"Nudge" is a no-op** — writes `lastNudgeAt` that the patient app never reads (`monitoring_widgets.dart:164` → `firestore_datasource.dart:371`).
- **Remote patients get zero missed-dose detection** — the only scanner iterates *local* profiles, never `monitoredPatients` (`app_state.dart:500-557`).
- **No shareable invite.** Inviting requires two phones in the same room scanning a QR (`add_cg_flow.dart:328-585`). A daughter in another city cannot invite her father. `ShareService` + deep-link handler already exist — only the *send* button is missing. ~1-day fix.

### Scan (your hero feature)
- **The hero result has no confidence, no "not identified" state, and stamps every result "AI verified"** (`product_analysis_screen.dart:498`). Scan a candy wrapper → authoritative "Highly Safe · 82 · AI verified" medical card. App-store-rejection and trust risk. The honest widgets (`ConfidenceMeter`, `ScanEmptyState`, pharmacist disclaimer) exist but only in the *other*, secondary scan pipeline.
- **Camera mode sends a screenshot of the viewfinder, not a real photo** (`scanner_hub_screen.dart:126`, `_captureScreen`), feeding the AI the worst-quality image on the most-used path — directly degrading the accuracy everything is judged on.

### Track
- **No discoverable manual "add medicine."** Every med must go through the AI scanner first; the one blank-form path is buried inside a *failed* voice-log fallback (`ai_quick_log_sheet.dart:793`). Offline users, repackaged pills, privacy-averse users are blocked at activation.
- **Snooze is a no-op stub** (`medication_controller.dart:671`) — in-app snooze gives haptic feedback and does nothing; the dose stays overdue.
- **The entire missed-dose experience is dead code.** `MissedDoseProtocolSheet` has zero call sites — the highest-anxiety, highest-churn moment (a missed dose) triggers nothing. There's no way to skip a dose from the home screen at all.

---

## P1 — Hurts growth/retention (fix next)

- **Your viral loop is paywalled.** Sending a caregiver invite is gated behind premium (`family_tab.dart:184`). Never paywall the invite — monetize advanced monitoring instead.
- **"Monitoring" isn't live.** Caregiver views use one-shot `FutureBuilder` on stale snapshots; real-time `*Stream` methods exist and are unused (`user_repository_impl.dart:236`). UI-swap fix.
- **Two divergent scan pipelines / two result screens** — same product scanned two ways looks like two different apps. Converge on one.
- **Streak-freeze button is missing from the streak modal** (`streak_modal.dart` renders only "Share"); the Duolingo-style forgiveness mechanic is 80% invisible.
- **Re-open guilt bug:** `checkDailyReentry` counts a no-log day as "missed everything" using total med count, not doses scheduled that weekday (`app_state.dart:852`) — punishes fragile new users.
- **Every dose toggle reschedules ALL notifications** (`app_state.dart:345`) — ~84+ alarm calls per checkbox tap for a 6-med user; battery drain + dropped-reminder risk.
- **The AI Quick-Log FAB is built and mounted nowhere.** No fast global "I took something" button.
- **iOS reminders may arrive silent** — the permission helper that requests sound/badge scopes (`notification_service.dart:80`) is never called; onboarding uses a weaker request.
- **~26 interrogation steps before value** (weight, birth year, sleep) with "payoffs" that are marketing slides, not the product. A/B a ~15-step variant.
- **Three home-screen growth cards** (`ShareMilestoneCta`, `TrialCountdownCard`, `CompleteProfileCard`) built, referenced nowhere.
- **Wrapped/recap has no push trigger** — your most shareable retention artifact is only reachable by manual navigation.

---

## P2 — Polish & trust

Adherence shows "100%" before the first dose (dishonest, can only go down); PRN/tapering schedules can't be represented; contradictory social-proof numbers ("500,000" vs "50K+"); PIN stored plaintext with no lockout; no "what can my caregiver see / revoke" panel; scan flow has no offline handling; fabricated "9-step scanning" theater decoupled from the real request; "Contact Support" is a fake toast. (Full detail in the per-flow findings.)

---

## What's genuinely strong (don't touch)

The reminder *engine* is above category standard — exact alarms, full-screen intents, iOS time-sensitive interruptions, boot persistence, Take/Snooze/Skip notification actions. The one-tap "take" interaction with haptics and animation is exactly the right friction. Accessibility is first-class throughout (Semantics labels, reduced-motion gating, min tap targets) — rare and valuable for a mass-market medical audience. The secondary scan result view (`ScanResultDetailView`) is excellent "understand" design and should be the template both pipelines converge on. Guest mode exists, onboarding precedes auth, and per-step funnel analytics + Remote-Config experiment infra are already in place.

---

## Recommended sequencing

**Phase 1 — Un-break the value curve (weeks, mostly wiring):**
1. Move first-scan/first-med activation *into* onboarding, before the paywall (P0 funnel).
2. Wire the manual add-medicine entry point, the missed-dose sheet, and the quick-log FAB (all built already).
3. Add real confidence + "not identified" state + honest disclaimer to the hero scan result; kill "AI verified"; use a real photo capture.

**Phase 2 — Turn on the viral loops:**
4. Stand up Cloud Functions + FCM so caregiver alerts and nudges actually fire.
5. Add "Share invite" (link + SMS, URL-encoded QR) and un-paywall the invite.
6. Wire the referral loop end-to-end (deep-link handler → reward → coded share cards) and surface the streak-share CTA.

**Phase 3 — Retention polish:**
7. Streak-freeze button, re-open guilt fix, per-toggle reschedule fix, Wrapped push, honest empty-state adherence.

The through-line: **Phase 1 and most of Phase 2 are connecting things you already built, not building new ones.** That's an unusually cheap path to a dramatically better growth profile.

---

## How this was produced
Four parallel deep-reads of the actual codebase (scan flow, track+remind flow, caregiver flow, growth funnel), each instructed to cite `file:line` evidence and rate severity by growth impact. Full per-flow reports with every citation are available on request.
