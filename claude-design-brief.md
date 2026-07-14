# Medai — Design Brief for claude.ai/design

Paste this into claude.ai/design, then request ONE screen at a time (see the list at the bottom).
Upload the reference assets listed at the end alongside this brief.

---

## What you're designing

**Medai** — a premium, consumer-facing AI-powered **Medication Insight & Habit-building** mobile app (iOS-first, phone screens). Users scan any pill/medicine/supplement to instantly understand it, then track doses as a sleek, rewarding daily habit. Think **Cal AI's polish + Duolingo's motivation + Medisafe's medical trust.**

## Aesthetic direction

- **Premium dark-mode first.** High-end, calm, clinical-but-warm. Apple Human Interface quality — generous spacing, soft depth, subtle micro-animation cues.
- **Rounded, soft-depth cards** on deep near-black backgrounds. Gentle shadows/glows, not flat.
- **Feel:** trustworthy medical + delightful habit app. Not sterile, not childish.

## Exact color palette (use these)

- Primary green: `#4A9E86`, deep `#3A7D6A`
- Mint accent / glow: `#6CF2D2`
- Backgrounds (dark): `#1A2621` (deep green-black), `#1C1C1E` (near-black), pure `#000000` for OLED sections
- Success: `#00C853` / `#8FD14F`
- Warning / low-stock: `#FF9F0A` / `#FFB340`
- Danger / severe side-effect: `#FF3B30` / `#FF453A`
- Info: `#0A84FF`
- Accent purple (gamification/premium): `#BF5AF2` / `#8B7BF2`
- Text: white `#FFFFFF` primary, muted grays for secondary

Typography: clean modern sans (SF Pro / Inter feel), bold expressive numerals for streaks & stats.

## Target user (design for them)

30–55 professionals managing prescriptions + 55+ users/caregivers with complex schedules. Moderate-to-high tech literacy, expect beautiful low-friction interactions (scanning over manual entry). Premium subscribers.

## Core features to reflect in screens

- **AI Scanner & Insight Hub:** scan pill/supplement → what it is, how it affects the body, when/how/why to take, side-effect severity levels, personalized allergy risk, supplement-interaction warnings.
- **Gamification:** streaks (3-day shield, 100-day crown), milestones, haptic reward moments, **"Med Wrapped"** (Spotify-Wrapped-style adherence summary for social sharing).
- **Caregiver / multi-profile:** PIN-protected profile switching for dependents.
- **Smart notifications:** gentle nudges → firm reminders, with health tips.
- **Low-stock alerts, adherence logs** for doctor visits.

---

## Screens to request (one at a time)

1. **Scanner** — camera view scanning a pill/label, AI detection overlay
2. **Insight Hub / Analysis** — scanned med result: identity, how-it-works, dosage timing, side-effect severity, allergy risk
3. **Home / Dashboard** — today's doses, streak header, low-stock card, quick-log
4. **Stats** — adherence charts, trends, doctor-ready log
5. **Med Wrapped (Social)** — shareable year/month adherence story cards
6. **Alarms / Schedule** — dose reminders, schedule setup
7. **Family / Caregiver** — PIN-protected profile switcher, dependent schedules
8. **Onboarding** — premium first-run flow
9. **Paywall** — premium subscription upsell
10. **Focus** — single-dose focused reminder moment

Suggested prompt per screen:
> "Design the **[screen name]** for Medai, a premium dark-mode medication insight app. Use the palette and aesthetic from the brief. Mobile phone screen. [1–2 lines of what this screen must show]."

---

## Reference assets to upload (already in this repo)

- `unique_screens_hd.pdf` — existing screen designs
- `video_screenshots_contact_sheet.pdf` — frames of the app in motion
- `cal ai onboarding/` — Cal AI onboarding frames (aesthetic reference)
- Existing mockups: `medicine-calai-v2 (1).jsx`

## After you have mockups

Bring them back here and I'll reimplement the ones you like as real Flutter screens in `medtrackaiflutter/lib/screens/`, using the existing theme tokens in `lib/theme/`.
