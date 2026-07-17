# DESIGN.md — MedTrack AI

> Single source of truth for how this app **looks** and **feels**. Token + rule + rationale live together so any agent (or human) can make the next decision on-brand and on-emotion, even for a case this file never explicitly covers.
>
> Companion to `AGENTS.md`/code: that says *how to build*; this says *how it should look and feel*.

---

## 1. Product & Emotional North Star

MedTrack AI helps people take the right medicine at the right time, understand what it does to their body, and stay safe — with special care for children, pregnancy, supplements, and skincare.

**Core job (never bury this under features):** _Scan a medicine → understand it (details + warnings) → track it → see how it affects your body → get reminded → loop in caregivers & AI._

**The feeling we engineer** (every screen must earn at least one):

| Emotion | What the user must believe | How we build it (concrete) |
|---|---|---|
| **Hope** | "Things get better from here." | Forward-looking copy, progress that only accrues, sunrise/lime accent on wins, mascot encouragement. |
| **Trust** | "This app is safe and knows what it's doing." | Clear warnings, cited safety info, calm color for danger (never gore-red panic), consistent layout, no dark patterns. |
| **Worth it (pre-pay)** | "This is valuable before I even pay." | Deliver a real win in onboarding (a completed scan, a real insight) before any paywall. |
| **Success / Manifestation** | "I am becoming the person who takes care of themselves." | Streaks, identity language ("You're a 12-day consistent tracker"), milestone moments, shareable wins. |
| **Belonging** | "This was made for me." | Personalized onboarding, niche modes (child/pregnancy/supplement/skincare), name usage, mascot as companion. |
| **Pride / Shareability** | "I want to show this." | Beautiful share cards, milestone celebrations, referral built into peak-emotion moments. |

**Rule of thumb:** if a screen doesn't move the user toward hope, trust, or a felt sense of progress, it's decoration — cut or redesign it.

---

## 2. Brand Direction (from reference set)

Bright, optimistic, premium health-tracker. Pure-white / warm-cream canvas, one confident **lime-green** signature, soft pastel category tints, large rounded "bento" cards, calendar strips, progress rings. Friendly mascot as emotional guide. Never clinical, never cold, never alarming.

---

## 3. Color System

### 3.1 THE decision: a **two-accent duo**, split strictly by domain

The codebase currently declares three different "only accent" colors (sage `#4A9E86`, orange `#FF6B35`, and the lime reference palette). This is drift. It resolves to a **deliberate duo** — never three, never ad-hoc.

**LIME = daily life, progress, success.** Home, dashboard, streaks, wins, primary CTAs, celebration, share cards.
```
lime / primaryDaily   #B4E869  hero, primary CTA fills, active states, streaks
limeDeep              #8FD14F  higher-contrast lime (text-on-light, pressed)
limeInk               #2E3D1B  text/icons on lime surfaces
```

**SAGE = clinical, safety, intelligence.** Scan, medicine detail, warnings, caregiver, AI clinical guidance.
```
sage / primaryClinical #4A9E86  clinical CTAs, scan accents, AI/safety highlights
sageDeep               #3D8A72  pressed/ink variant
```

**The rule that prevents drift:** every surface picks lime **or** sage by *what it is about*, never by taste. A CTA on the home tab is lime; a "Scan medicine" or "View interactions" CTA is sage. When a screen mixes domains (e.g. a home card that opens a safety warning), the card is lime and the safety element inside is sage. Danger/emergency is always red `#FF3B30` — it is **not** an accent and never uses lime or sage.

**Orange `#FF6B35` is RETIRED** — do not use for new work; migrate existing usages to sage (clinical) or lime (daily).

> **Migration note:** the three stale "only accent" comments in `app_theme.dart` (~L42, ~L467) and `app_tokens.dart` must be reconciled to this duo. Until then, treat this file as authoritative.

### 3.2 Surfaces & neutrals

```
canvas (light)   #FFF8F2  warm cream    | canvas (dark)   #0B132B  deep slate
card (light)     #FFFFFF                | card (dark)     #1C2541  midnight navy
fill (light)     #F1F3F5                | fill (dark)     #283353
inkStrong        #1A1D26  headings      | inkSoft         #9AA0A6  captions
```
Always resolve surface/text via `context.L` (theme extension) — never hardcode `Colors.white/black` in screens. Light/dark parity is mandatory.

### 3.3 Category pastel tints (bento cards)

```
mint  #E4F5E7   sky  #D9ECF7   pink #FCE4E6   sun #FFF3D1   lilac #EDE7F9
```

### 3.4 Semantic — safety is calm, not scary

```
success  #10B981   warning  #F59E0B   danger  #EF4444   info  #0A84FF
```
Danger conveys *seriousness*, not panic. Icon-badge fills use ~12% alpha via `AppColors.badgeFill(ink)` — never scatter raw alpha values. **Child-safety / pregnancy warnings** get the highest visual priority (dedicated warning card, top of med detail), but stay calm and instructive.

---

## 4. Type Scale

Font: **Outfit** (UI), **Space Grotesk** (numbers/mono). Use the `AppTypography.*` ramp — never ad-hoc `fontSize`.

```
displayXL 72 / displayL 64 / displayM 48 / displayS 36
headline L 28 / M 24 / S 20
title L 18 / M 16
body L 17 / M 15 / small 12
label L 14 / M 12 / small 11 / caption 11 / sectionLabel 11
monoNumber (Space Grotesk) — stats, counts, doses
```
Numbers that represent progress/streaks/doses use `monoNumber` for a confident, "data you can trust" feel.

---

## 5. Space, Radius, Motion

**Spacing** (`AppSpacing`): 4·8·12·16·20·24·32·40·48·64·80. Screen padding 24, shell gutter 20, card gap 12, bottom buffer 120 (floating nav). Use tokens; no raw `EdgeInsets` magic numbers in screens.

**Radius** (`AppRadius`): xs8 · s12 · m16 · l24 · xl28 · squircle32 · max999. Bento/hero cards use l–squircle. Pills use max.

**Motion** (`AppDurations`/`AppCurves`): micro 150 · fast 220 · medium 320 · exit 180 (asymmetric: exits snappier than entrances). Default curve `emilOut`. Spring/elastic reserved for **celebrations & onboarding only** — never on tabs, lists, or settings. Respect reduced-motion (`MedAiA11y.reducedMotion`).

---

## 6. Accessibility (non-negotiable)

- Min tap target 48 (44 compact). Text contrast ≥ 4.5:1.
- Live regions for status (offline banner, toasts) via `Semantics(liveRegion: true)`.
- Every icon-only control has a `Semantics` label.
- All animation gated behind reduced-motion checks.
- Full light/dark parity.

---

## 7. Component Language

- **Bento cards** — rounded (l–squircle), soft shadow, pastel tint or white, icon badge (12% fill) + title + value. The primary information unit.
- **Med card (home)** — after tracking, surfaces *emergency & important info inline*: next dose, warnings, body-impact hint, quick actions (taken / snooze / details). This is the app's most important component; it must feel reassuring and glanceable.
- **Progress ring / week strip** — accrual-only, celebratory, lime.
- **Status banner** — calm offline/error strip, live region, retry + dismiss.
- **Feedback** — route everything through `AppFeedback` (brand toast) / `AppStatusBanner`; no raw `ScaffoldMessenger.showSnackBar` in screens.
- **Mascot** — emotional companion; appears at hero/onboarding/celebration moments, never nags.
- **CTA** — primary = lime fill + limeInk text; secondary = fill + ink. One primary CTA per screen.

---

## 8. Flow Principles

- **Onboarding delivers a real win before the paywall** (a completed scan or a genuine insight) so value is felt pre-pay.
- **Paywall** appears at a peak-value / peak-emotion moment, is honest, and frames premium as "invest in the person you're becoming."
- **Share & referral** are offered at celebration moments (streaks, milestones, wrapped) — never as cold interruptions.
- **The scan → detail → track → body-impact loop is the spine.** Every tab should make returning to it effortless.

---

## 9. Drift Watchlist (audit-enforced)

Do not merge new code that adds to these (baseline counts from audit 2026-07-17):
- Raw `Color(0x…)` hex in screens/widgets — **181** (target ↓)
- Hardcoded `fontSize` — **442** (target ↓)
- Direct `Colors.white/black` — **456** (target ↓)
- Ad-hoc `Duration(...)` outside tokens — **104** (target ↓)
- `withOpacity` — **0** ✅ (keep at zero; use `withValues`)

Prefer tokens (`AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppDurations`, `context.L`) in every new/edited screen.
