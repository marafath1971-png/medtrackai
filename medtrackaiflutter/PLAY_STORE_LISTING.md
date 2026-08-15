# Play Store listing copy — MedAI

Draft for the Google Play Console listing. Every claim below is checked against what the
app actually ships (see "Claims audit" at the end).

---

## App name (30 char limit)

```
MedAI: Medication Reminder
```
*(26 chars)*

Alternatives:
- `MedAI: Med Tracker & Alarms` (27)
- `MedAI: Pill Reminder & Scan` (27)

> Avoid an em dash in the title: `MedAI — Pill Reminder & Scan` is 28 characters but
> **30 bytes**, and Play counts some fields by byte length. Use a colon.

> The manifest label is currently just `MedAI`, which is fine for the launcher, but the
> Play listing title should carry a keyword — most installs come from searches for
> "medication reminder" and "pill tracker", not the brand name.

---

## Short description (80 char limit)

```
Never miss a dose. Smart reminders, pill scanning, and care for your family.
```
*(76 chars)*

Alternatives:
- `Medication reminders that actually stick — scan, track, and never miss a dose.` (78)
- `Pill reminders, refill alerts, and shared care for the people you look after.` (76)

---

## Full description (4000 char limit)

```
Never miss a dose again.

MedAI turns medication tracking into something you actually keep up with. Set it up in
under a minute, then let calm, reliable reminders do the rest.


SMART REMINDERS THAT WORK
• Flexible schedules — daily, specific days, or custom timing
• Persistent alarms for critical medications that ring until you respond
• Refill alerts before you run out
• Adherence streaks that make consistency feel rewarding


SCAN INSTEAD OF TYPE
Point your camera at a medicine box or pill to identify it and fill in the details.
No more squinting at tiny labels or typing long drug names.
• Pill and package recognition
• Barcode scanning
• Interaction warnings when two medications may not mix well


CARE FOR YOUR FAMILY
Look after a parent, partner, or child without hovering.
• Add family members and dependents to one account
• Caregiver access with alerts if a dose is missed
• Switch between profiles in a tap


UNDERSTAND YOUR HEALTH
• Adherence stats and weekly wellness trends
• Insight cards that explain what your patterns mean
• Export a clinical PDF or CSV to bring to your doctor
• Optional Health Connect sync for steps, sleep, heart rate, and more


PRIVATE BY DESIGN
• Biometric lock (fingerprint or face) to keep your health data yours
• Export or permanently delete your data at any time
• GDPR, CCPA, and PIPEDA aligned


AVAILABLE IN 7 LANGUAGES
English, Spanish, Japanese, Korean, Malay, Arabic, and Hebrew — including full
right-to-left support.


FREE TO USE
Track up to 5 medications, with AI scans and voice logging included each month.

MED AI PRO
• Unlimited medications
• Unlimited AI scans
• Doctor-ready PDF reports
• Streak freeze protection
• Full AI-powered analysis

Subscriptions renew automatically unless cancelled at least 24 hours before the end of
the current period. Manage or cancel anytime in Google Play.


IMPORTANT
MedAI helps you keep track of medications you have already been prescribed. It does not
provide medical advice, diagnosis, or treatment, and it is not a substitute for your
doctor or pharmacist. Always follow the guidance of a qualified healthcare professional.
Never change or stop a medication based on this app alone. In an emergency, contact your
local emergency services.
```

*(~2,050 characters — comfortably under the 4,000 limit)*

---

## Screenshot plan

Play shows the first 2–3 in search results, so lead with the strongest. Minimum 2,
maximum 8; use 1080×1920 (9:16). Add a short caption band at the top of each.

| # | Screen | Caption |
|---|---|---|
| 1 | Home / today's doses | "Never miss a dose" |
| 2 | Scanner viewfinder | "Scan any medicine — no typing" |
| 3 | Adherence stats | "See your streak build" |
| 4 | Family / caregiver tab | "Care for the people you love" |
| 5 | Reminder notification | "Reminders that reach you" |
| 6 | Insights / analysis | "Understand your patterns" |
| 7 | Medicine detail | "Everything about every med" |
| 8 | Privacy / biometric lock | "Your health data stays yours" |

**Feature graphic (1024×500):** mascot on the lime `#b9ea6e→#8fd14f` gradient, tagline
"Never miss a dose." Keep text in the middle third — Play crops the sides on some layouts.

**App icon:** 512×512 PNG, no alpha. Use `assets/images/app_icon.png`.

---

## Category and tags

- **Category:** Medical *(not Health & Fitness — this is medication management)*
- **Tags:** medication reminder, pill reminder, medicine tracker, prescription manager,
  refill alert, caregiver
- **Content rating:** Everyone (expect questions about health data collection)
- **Contains ads:** No
- **In-app purchases:** Yes — declare the Pro subscription price range

---

## Claims audit

Written against the shipped code so the listing does not overpromise.

Verified present:
- 5-medication free limit, 3 AI scans, 3 voice logs — `remote_config_service.dart`
- Persistent alarms — `reminderStyle: 'persistent'`, `USE_EXACT_ALARM` permission
- Pill/package scanning, barcode — `lib/screens/scan/`, `mobile_scanner`
- Interaction warnings — `interaction_warning_sheet.dart`
- Family/caregiver, dependents — `lib/screens/family/`
- Adherence stats, insights — `lib/screens/stats/`
- PDF/CSV export — `report_service.dart`
- Health Connect — steps, heart rate, sleep, blood glucose, and blood pressure are all
  genuinely read in `providers/controllers/health_controller.dart:48-53`, matching the
  manifest permissions. (`os_health_service.dart` separately handles NUTRITION/WATER
  writes — do not mistake that file for the whole integration.)
- Biometric lock — `biometric_service.dart`, `USE_BIOMETRIC`
- 7 locales incl. RTL — `lib/l10n/app_{en,es,ja,ko,ms,ar,he}.arb`
- Pro features — `premium_paywall_overlay.dart`

Deliberately excluded:
- **"HIPAA compliant."** The paywall says "Advanced HIPAA privacy mode"
  (`premium_paywall_overlay.dart:94`), but HIPAA binds covered entities — providers,
  insurers, and their business associates — not a direct-to-consumer app. Claiming it in
  a store listing is a misleading-claims risk and invites scrutiny. The privacy screen
  already uses the correct, defensible phrasing: "HIPAA-equivalent security practices."
  **Recommend changing the paywall string to match.**
- **"Voice logging" as a headline feature.** It exists and is metered, but ships behind a
  limit, and `RECORD_AUDIO` still needs a Play justification. Mentioned only in the free
  tier line. If voice is cut from v1, remove that clause and the permission.
- **Any diagnostic or advisory phrasing** ("know if your meds are safe", "AI health
  advice"). Play's health policy and the medical disclaimer both require the app to read
  as a tracker, not a clinician.
- **The "500,000+ people" figure** used in onboarding. Do not put it in the listing unless
  it is literally true — unverifiable install claims are a policy problem.

---

## Before publishing

- [ ] **Fix the HIPAA string** in `premium_paywall_overlay.dart:94` — change
      "Advanced HIPAA privacy mode" to match the privacy screen's "HIPAA-equivalent
      security practices" or simply "Advanced privacy mode".
- [ ] **Decide on `RECORD_AUDIO`** — keep and justify voice logging, or remove it for v1.
- [ ] Confirm the localized listing for each of the 7 shipped locales, or restrict the
      listing to English so users are not shown a translated listing for an
      English-only-looking store page
- [ ] Subscription products created in Play Console with the same names used above
- [ ] Privacy policy URL live at `https://medai.app/privacy`
- [ ] Screenshots captured from a release build, not debug
- [ ] Re-read the full description once the photos and paywall strings are final
