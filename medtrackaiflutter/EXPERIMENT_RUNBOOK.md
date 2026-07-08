# MedAI — Remote Config Experiment Runbook

*Companion to PRODUCT_AUDIT_AND_REDESIGN_BLUEPRINT.md. Everything here is already wired in code (see `lib/services/remote_config_service.dart`). Changing a value in Firebase Console → Remote Config changes the live app — no release needed.*

---

## 1. Setup (one-time, ~10 minutes)

1. Firebase Console → your project → **Remote Config** → Create configuration.
2. Add the parameters below with these defaults (they mirror the in-code defaults, so publishing them changes nothing until you edit a value).
3. Firebase Console → **A/B Testing** uses these same parameters for experiments; results segment automatically by the `onboarding_step_viewed`, `onboarding_completed`, and paywall funnel events (`view`/`attempt`/`success`/`close` via GrowthTracker) already firing in the app.

| Parameter | Type | Default | What it controls (enforcement point) |
|---|---|---|---|
| `paywall_default_plan` | string | `annual` | Which plan is pre-selected: `annual` / `monthly` / `weekly` (paywall plan selector) |
| `paywall_show_weekly_plan` | bool | `true` | Whether the weekly plan appears at all |
| `paywall_show_trial_timeline` | bool | `true` | Blinkist-style "Today / Day 2 / Day 3" timeline block |
| `paywall_headline_variant` | string | `personalized` | Reserved for headline copy tests |
| `paywall_exit_offer_enabled` | bool | `false` | Reserved — exit offer (build before enabling; iOS review gray area) |
| `trial_reminder_enabled` | bool | `true` | Whether the "trial ends tomorrow" push is scheduled on purchase |
| `onboarding_show_rating_step` | bool | `true` | Step 51 (native rating prompt) in/out of the funnel |
| `onboarding_show_att_step` | bool | `true` | Step 50 (ATT permission) in/out of the funnel |
| `onboarding_skip_enabled` | bool | `true` | Skip button on all onboarding steps |
| `free_tier_scan_limit` | number | `3` | AI scans before the paywall blocks scanning |
| `free_tier_voice_limit` | number | `3` | Voice logs before the paywall blocks logging |
| `free_tier_med_limit` | number | `5` | Medicines a free user can have in the cabinet |

Config refreshes at most hourly in release builds (instant in debug), so allow ~1h propagation.

---

## 2. First five experiments (in priority order)

Run one at a time, 50/50 split, minimum ~2 weeks or until significance. Primary metric for all: **revenue per install (D7 trial starts as leading indicator)**. Trial-structure and price-fence tests have the highest historical win rates (~60% vs ~30% for visual tweaks).

**Experiment 1 — Scan fence tightness.** `free_tier_scan_limit`: 3 vs 1. One free scan is the Lily-class pattern: the user gets the magic moment once, then pays. Watch D1 retention as the guardrail metric — if it drops >10%, the fence is too tight.

**Experiment 2 — Skip button removal.** `onboarding_skip_enabled`: true vs false. Skip buttons measurably depress trial starts; the risk is review-score damage from trapped users. Guardrail: onboarding abandonment (app close before step 20).

**Experiment 3 — Med cabinet fence.** `free_tier_med_limit`: 5 vs 2. Medisafe just moved to 2 and angered users — but their users had free unlimited for years; new installs have no anchor. Guardrail: D7 retention.

**Experiment 4 — Default plan.** `paywall_default_plan`: annual vs weekly. Annual should win on LTV in health (60.6% of category revenue), but weekly converts more people — this measures which dominates for *your* traffic mix. Metric: projected 12-month LTV per install, not conversion rate.

**Experiment 5 — ATT placement.** `onboarding_show_att_step`: true vs false (off = never asked during onboarding). ATT consent improves ad-network match rates for paid UA later, but the prompt costs some funnel completion. Only matters once you're buying installs.

---

## 3. Funnel dashboards to build (Firebase → Analytics)

1. **Onboarding funnel**: `onboarding_step_viewed` step_index 0→55 → `onboarding_completed`. Kill or rewrite any step with >8% drop-off.
2. **Money funnel**: install → `onboarding_step_viewed(0)` → paywall `view` → `attempt` → `success` (GrowthTracker events) → RevenueCat trial→paid webhook.
3. **Gate pressure**: paywall `view` events segmented by triggerSource (`scan_limit`, `unlimited_meds`, `voice_limit`, `onboarding`) — tells you which fence actually drives upgrades.

Benchmarks to beat: ≥65% of installs reach the paywall, install→trial ≥12%, trial→paid ≥30% (health category median 35%).

---

## 4. Exit offer & headline variant (now live)

Both reserved keys are now consumed by the app:

- **`paywall_exit_offer_enabled`** (default `false`): when on, dismissing the onboarding paywall shows — once — a "not ready for a year? try weekly" banner and pre-selects the weekly plan instead of closing. A second dismiss closes normally. It uses only your real store SKUs (no fake discounts), which keeps it App Review-safe, but downsell-on-dismiss is still an iOS review gray area: **enable on Android first**, watch `exit_offer_shown` → `attempt` conversion, then decide on iOS. A dedicated discounted SKU in RevenueCat (e.g. $29.99/yr) would strengthen this later.
- **`paywall_headline_variant`**: `personalized` (default) shows the onboarding-goal headline; `generic` forces the standard copy — this is your headline A/B switch.

Remaining build items (need external accounts, not code): attribution SDK (AppsFlyer/Adjust key), win-back offers (App Store Connect / Play Console configuration).
