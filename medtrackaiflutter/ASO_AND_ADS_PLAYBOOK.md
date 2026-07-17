# MedAI — ASO & Paid UA Playbook

*Companion to the blueprint (§8) and experiment runbook. Everything here is copy-paste ready for App Store Connect / Play Console / TikTok Ads. 2026 rules applied: Apple OCR-indexes screenshot text; intent phrases beat the generic "AI" token; review velocity is a ranking input.*

---

## 1. App Store listing (iOS)

**Title (30 chars max)** — brand + highest-volume intent phrase:
- `MedAI: Pill Identifier & Meds` (29)
- Alt test: `MedAI — Medication Reminder AI` (30)

**Subtitle (30 chars)** — second keyword cluster, no title repeats:
- `Med tracker, refill & family` (28)
- Alt test: `Scan pills, never miss a dose` (29)

**Keyword field (100 chars, no spaces after commas, no title/subtitle repeats):**
`pill,identifier,medication,reminder,tracker,drug,interaction,supplement,refill,caregiver,adherence` (99)

**Promotional text (170 chars, updatable without review):**
`Point your camera at any pill and know exactly what it is. Smart reminders, interaction warnings, and family care — your complete medication companion.` (152)

**Description opener (first 3 lines carry the weight):**
> Never miss a dose again. MedAI identifies any pill with one photo, builds reminders around your real day, and warns you before risky drug interactions — for you and the people you care for.
>
> Trusted by people managing everything from daily vitamins to complex multi-medication routines.

Then bullet the features in this order (mirrors paywall value ladder): AI pill scanner → smart reminders → interaction checker → family circle → streaks & Wrapped → doctor-ready PDF reports.

---

## 2. Screenshot captions (OCR-indexed — these are keywords now)

8 screenshots, portrait, caption at top in ≥40pt. Order = conversion story:

| # | Screen shown | Caption (OCR keyword target) |
|---|---|---|
| 1 | Pill scanner mid-scan with AI chips | **"Identify any pill instantly"** |
| 2 | Home dose timeline | **"Medication reminders that fit your day"** |
| 3 | Adherence ring at 94% | **"Watch your adherence climb"** |
| 4 | Interaction warning card | **"Catch drug interactions early"** |
| 5 | Family circle dashboard | **"Know Mom took her meds — from anywhere"** |
| 6 | Streak flame + freeze | **"Streaks that forgive real life"** |
| 7 | Monthly Wrapped share card | **"Your month, wrapped"** |
| 8 | Paywall-free trust shot (privacy shield) | **"Private. Encrypted. Never sold."** |

Play Console: reuse captions; feature graphic = screenshot 1's composition.

---

## 2b. Google Play listing (Android)

**Package / applicationId (shipped):** `com.medtracker.medtrackaiflutter`  
**Canonical URLs in app:** `kPlayStoreUrl`, `kPrivacyPolicyUrl`, `kTermsOfServiceUrl` in `lib/models/constants.dart` (`https://medai.app/…`).

**Title (30 chars max):**
- `MedAI: Pill Identifier & Meds` (29)

**Short description (80 chars max):**
- `Scan any pill, never miss a dose. Reminders, interactions & family care.` (72)
- Alt: `AI pill ID, smart med reminders, interaction alerts & caregiver circle.` (70)

**Full description (copy-paste):**
```
Never miss a dose again. MedAI identifies any pill with one photo, builds reminders around your real day, and warns you before risky drug interactions — for you and the people you care for.

• AI pill identifier — point your camera and know the med
• Smart medication reminders that fit your schedule
• Drug interaction warnings before you combine meds
• Family / caregiver circle — know doses were taken
• Adherence streaks, Trends, and monthly Wrapped
• Doctor-ready PDF / CSV export of your history

Private by design. Your medication data is encrypted and never sold.

Questions? support@medai.app
Privacy: https://medai.app/privacy
Terms: https://medai.app/terms
```

**Graphics checklist**
| Asset | Spec | Status in repo |
|---|---|---|
| High-res icon | 512×512 PNG | Source `assets/images/app_icon.png` is **1024×1024** — export/crop 512 for Play Console |
| Feature graphic | 1024×500 | **Not in repo** — compose from scanner hero + lime accent `#D9FF66` |
| Phone screenshots | 2–8, portrait | Capture from Pixel using caption order in §2 |
| 7" / 10" tablet | Optional | Skip for v1 unless tablet layout is QA’d |

**Content rating:** IARC questionnaire — health/medication reminder (not a medical device; no diagnosis). Answer “no” to violence/sexual/etc.; disclose health-related info collection.

### Data Safety form (align with shipped SDKs)

Declare based on current `pubspec` / permissions:

| Data type | Collected? | Shared? | Purpose | Notes |
|---|---|---|---|---|
| Email / account ID | Yes | No* | App functionality, account management | Firebase Auth |
| App interactions / analytics | Yes | No* | Analytics | Firebase Analytics |
| Crash logs | Yes | No* | App functionality / stability | Crashlytics |
| Photos / camera (pill scans) | Yes (ephemeral / user-initiated) | No* | App functionality | Camera permission; processed via AI (Gemini) |
| Health & fitness (optional) | Yes if user connects | No* | App functionality | `health` package / Health Connect |
| Purchase history | Yes | With RevenueCat* | App functionality | `purchases_flutter` |
| Approximate location | No | — | — | Do not declare unless added later |

\* “Shared” = with a third party for a purpose other than processing under your instructions. Firebase / RevenueCat / Gemini as service processors usually go under **Data processors** / “service providers”, not “shared for advertising”. Confirm in Play Console UI against current policy text.  
**Advertising ID:** only if you enable ads — currently no AdMob dependency.  
**Encryption in transit:** Yes. **Users can request deletion:** Yes (in-app delete account / settings Data tab).

**Permissions called out in manifest today:** `INTERNET`, `CAMERA`, `RECEIVE_BOOT_COMPLETED`, `POST_NOTIFICATIONS` (+ Health Connect when user opts in).

---

## 3. Review velocity engine (already coded)

The in-app prompt fires contextually (onboarding motivation peak + milestone moments). Support it manually: respond to every review ≤48h (a ranking input), and never buy reviews. Floor target: 4.5★. The 3-prompts-per-year iOS budget is already respected in code.

---

## 4. Paid UA creative briefs (TikTok-first, then Meta)

Budget rule from the blueprint: **do not scale spend until attribution SDK is live** — run only $20–50/day creative tests with App Store Connect referral tags until then.

**Creative 1 — "What IS this pill?" (hook: curiosity)**
POV, 15s: hand finds a loose pill in a drawer → "wait, what is this?" → phone scans → name/dose/warnings pop in → "oh. that's my mom's blood pressure med." Text overlay: *the app every household needs*. CTA: identify any pill free.

**Creative 2 — "I always know Mom took her meds" (hook: caregiver guilt/relief)**
15–20s: adult child glances at phone during work day → family circle shows green checkmark "Mom · 9:00 AM ✓" → exhale → cut to phone call, both smiling. VO: "I stopped calling to nag. Now I just know." Runs to 35–55 demo.

**Creative 3 — "Day 47" (hook: streak pride)**
10s: rapid-fire daily check-off montage with ring closing + haptic sound design → streak flame hits 47 → Wrapped card shared to story. Runs to 16–28 demo. This creative doubles as organic content — post the template.

**Creative 4 — "The pharmacist reaction" (hook: authority)**
Duet/greenscreen format: pharmacist-creator reacts to the interaction checker catching a real supplement-drug conflict. Whitelist the creator for Spark Ads.

Kill rule: pause any creative with CPI above 2× the best performer after $100 spend. Winning angle historically in this category: caregiver emotion > utility demo > streak pride.

---

## 5. Launch-week checklist

1. Analyzer/tests green → release build with `kDevPreview = false`.
2. Remote Config parameters published (runbook §1) — no experiments live in week 1; collect a clean baseline.
3. App Store product page: listing above + 8 captioned screenshots.
4. Soft-launch geo first (e.g., Canada/Australia) at 500–1k installs to validate funnel benchmarks (≥65% reach paywall, ≥12% install→trial) before the home-market push.
5. Start Experiment 1 (scan fence 3 vs 1) only after ~2k baseline installs.
