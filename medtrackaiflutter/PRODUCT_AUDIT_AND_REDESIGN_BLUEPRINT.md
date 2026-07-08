# MedAI — Full Product Audit & $1M MRR Redesign Blueprint

*Prepared July 5, 2026 · Based on a deep audit of the codebase (224+ Dart files, ~50k LOC) plus market research on top-grossing AI/health apps of 2025–2026.*

---

## 1. Executive Summary

Your app is far more mature than most apps that attempt this journey. You already have: a 40-step onboarding funnel, RevenueCat subscriptions, Gemini-powered pill scanning, a family/caregiver system, streaks and "Med Wrapped" gamification, 8 languages, Live Activities, biometric security, and a genuinely modern design system (glassmorphism, haptics, WCAG 2.2 AA).

**The gap between MedAI today and a $1M MRR app is not features. It is conversion infrastructure, monetization architecture, and finishing what's half-built.** Specifically:

| Dimension | Today | Top-grossing standard |
|---|---|---|
| Paywall model | Soft overlay, monthly/annual | Hard paywall as "plan reveal," annual-led, trial-badged plan, exit offers |
| A/B testing | None (no Remote Config) | 50+ paywall experiments (18.7x revenue vs. 1 experiment) |
| Attribution | None (no AppsFlyer/Adjust) | Paid UA from day one, measured CAC |
| Onboarding analytics | 1 completion event | Per-screen funnel events, drop-off dashboards |
| Retention mechanics | Streaks (punitive reset) | Forgiveness-first streaks + freezes (+10% retention), widgets (+60% commitment) |
| Feature completion | Voice 50%, Social 40%, Health-write disabled | Shipped or cut |
| Test coverage | ~5–10% | 40%+ on money paths |

**Key market facts driving this blueprint** (all sourced in §11):

- Hard paywalls convert 10.7% install→paid vs 2.1% freemium — **8x revenue per install at day 60** — with nearly identical 1-year retention.
- Health & Fitness has the **highest trial→paid conversion of any category: 35%**.
- Health & Fitness is the only category where **annual plans dominate (60.6% of revenue)** — lead with annual, not weekly.
- AI-powered apps earn **41% more revenue per payer** than non-AI apps.
- Apple **banned the free-trial toggle paywall** (Guideline 3.1.2) and pulled Cal AI in April 2026 for pricing display violations — the compliant pattern is a trial-badged plan + Blinkist-style trial timeline (+23% trial starts).
- Medisafe just hard-gated its free tier at 2 medications and triggered user backlash — **a market opening for a better-designed paid competitor is live right now.**

---

## 2. What You Already Have (Strengths Audit)

**Architecture.** Offline-first (SharedPreferences + Firestore sync), Provider with 5 domain controllers, go_router with 40 routes, clean domain/data separation with repositories and entities, Result types, hardened timeouts. This is a solid foundation — do not rewrite it.

**Feature inventory (39 screens).** Dose timeline home, iOS-grade theming (`design_2026.dart`, 616 lines of tokens), AI pill scanner (Gemini 2.5 Flash vision), JAHIS QR parsing (Japan), supplement analysis + product chat, drug-interaction checks, voice assistant (STT+TTS), family circle with caregiver monitoring and PIN-locked child profiles, trophy case, Monthly Wrapped (Spotify-style shareable), inventory forecasting, PDF clinical export, Shabbat-aware alarms, HealthKit/Google Fit read, biometric lock, in-app review prompts, deep links + Siri Shortcuts, growth admin dashboard.

**Monetization plumbing.** RevenueCat (`purchases_service.dart`), single `premium` entitlement, paywall variants (onboarding + feature-gate), paywall funnel events (view/attempt/success/close), free tier caps (5 meds, limited scans).

**Polish.** flutter_animate + Rive + Lottie + confetti, spring-physics transitions, reduced-motion support, haptic engine, shimmer loaders, `MedAiGlass` frosted surfaces, dynamic accent colors, 8 locales (en, ar, es, he, ja, ko, ms).

This puts you in roughly the top 5% of indie health apps on raw capability. The rest of this document is about converting capability into revenue.

---

## 3. Gap Analysis — What's Incomplete or Missing

### 3.1 Critical revenue blockers (fix first)

1. **No Remote Config / A/B testing framework.** `firebase_remote_config` is absent from pubspec. You cannot change pricing, paywall copy, or onboarding order without an app release. Apps running 50+ paywall experiments earn 18.7x more than apps running one. This is the single highest-leverage gap.
2. **No attribution SDK** (AppsFlyer/Adjust/Branch). You cannot run paid UA profitably because you can't measure CAC by channel. Every studio in the $25M+/mo class (Codeway, AIBY, Bending Spoons) runs paid ads from day zero — with attribution.
3. **No product analytics beyond Firebase Analytics.** No Mixpanel/Amplitude means no retention cohorts, no per-screen onboarding funnel, no LTV curves. You have `growth_tracker.dart` for paywall events — extend it, but pipe into a real analytics stack.
4. **Paywall is a soft overlay.** Top health apps convert 5x better with a hard(-ish) paywall placed as the climax of onboarding. Your paywall also predates Apple's 2026 toggle ban — it must be rebuilt compliant (see §5).
5. **No exit offers, no win-back flows.** 67–75% of cancellations are voluntary (addressable); win-back within 10–15 minutes of cancellation lifts reactivation ~25%. Billing-error churn (32% of Play Store cancels) needs grace periods enabled in RevenueCat.
6. **No localized pricing.** Europe prices 29–39% above North America; Germany's health annual pricing is 4.4x Turkey's. One global price leaves money on the table in rich geos and blocks conversion in poor ones.

### 3.2 Incomplete features (finish or cut)

| Feature | Done | Action |
|---|---|---|
| Voice assistant | ~50% (STT works, NLP is keyword-level) | Finish with Gemini function-calling ("log my metformin") — it's a marketable AI differentiator |
| Med Buddies / social feed | ~40% (invites work, feed missing) | Cut the feed for now; keep caregiver circle. Social feeds don't drive health-app revenue |
| OS Health write | Disabled (Apple API limits) | Keep read-only; surface HealthKit data in dashboard instead |
| Supplement interaction scanner | ~70% | Finish — interaction warnings are a premium-gate feature users pay for (Medisafe gates this) |
| AI Protector Insights | ~60% | Finish — caregiver AI insights justify a family-plan tier |

### 3.3 Code health debt (slows every future experiment)

- **God files:** `home_tab.dart` (1,476 lines), `app_state.dart` (1,282), `router.dart` (~1,000), `onboarding_flow.dart` (958, a 40-case switch). Refactor onboarding into a polymorphic `OnboardingStep` model **before** rebuilding the funnel — you'll be reordering screens weekly during A/B testing, and a switch statement makes that miserable.
- **Silent error swallowing:** `.catchError((_) {})` on Firestore writes (e.g., `medication_repository_impl.dart:58`) hides sync failures — for a medication app this is a safety issue, not just a quality issue. Log + retry queue + user-facing sync status.
- **Business logic in UI:** dose-grouping time boundaries duplicated across 3 screens; severity thresholds computed in build methods. Extract `DoseGroupingService`, promote magic numbers (severity ≥ 8, 5-med cap, 30-day window) to constants.
- **Tests:** 4 files. Minimum bar: unit tests on purchase flow, entitlement gating, dose scheduling, streak math — the code paths where bugs cost money or health.

---

## 4. UI/UX Redesign Direction (2026)

You already own the right ingredients (glass surfaces, tokens, haptics, Rive/Lottie). The redesign is about *composition and restraint*, not new tech.

**Visual language: surgical Liquid Glass.** iOS 26's liquid glass is the defining 2026 aesthetic — but the winning apps use it only on floating layers: the tab bar, contextual sheets, the paywall card, the dose-action overlay. Never put glass behind medication data (legibility + frame-rate). Your `MedAiGlass` component is the right primitive; audit every usage against this rule.

**Dashboard: one hero metric, iOS Activity-ring style.** Rebuild `dashboard_tab.dart` around a single large **adherence ring** (today's doses taken/total) with an animated fill and a haptic "ring-close" celebration — ring/milestone visuals drive ~27% higher ongoing participation, and goal-completion animations make users 33% more likely to keep daily tracking. Below the ring: a 7-day sparkline row, a streak flame (Rive, interactive), and 2–3 big-number stat cards (adherence %, current streak, on-time rate). Neutral base, your sage-green accent only. Progressive disclosure: tap the ring → full analytics. Avoid the Samsung Health failure mode: no bento-box of ten competing pastel cards.

**Tone: forgiveness-first, not guilt-first.** The 2026 Apple Design Award direction (Gentler Streak) frames misses as recoverable, not failures. For a med app this is also clinically right. Concretely: auto-grant streak freezes at milestones (before they're needed — Duolingo's freeze mechanic lifts long-term retention 10%), a "streak repair" flow instead of silent reset, and copy like "Life happens — your 47-day streak is protected" instead of red warning banners.

**Motion system rules.** Rive for anything interactive or state-driven (streak flame, adherence ring, the onboarding "analyzing" sequence, mascot if you add one — Rive files are ~10–15x smaller with built-in state machines). Lottie for one-shot decorative illustrations (onboarding education screens, empty states). Every gesture pairs with a haptic. Keep your reduced-motion support — it's an award-judging criterion now.

**Typography & spacing.** Keep Outfit; increase the size contrast between hero numbers (48–64pt) and labels (13pt) on the dashboard — the "big number" pattern is how Bevel, Rise, and Gentler Streak read as premium.

---

## 5. Monetization Architecture (Hard Paywall, Apple-Compliant)

**Placement.** One paywall moment: the climax of onboarding, framed as the *delivery of the user's personalized plan* — not an interruption. Secondary paywalls remain at feature gates (scan limit, PDF export, interactions, family plan).

**Structure (2026-compliant):**

1. **No trial toggle.** Apple rejects it under Guideline 3.1.2. Instead: 3 plans where one is badged "3-day free trial included."
2. **Annual-led pricing** (health is the one category where annual wins — 60.6% of revenue):
   - **Annual $39.99/yr** — anchor, trial-badged, "SAVE 67%", price also shown as **$0.77/week** (daily/weekly breakdown reduces sticker shock — the Lily pattern)
   - Monthly $9.99/mo — the decoy that makes annual look obvious (health monthly median is $9.70)
   - Weekly $4.99/wk — surfaced by Remote Config only in price-sensitive geos (weekly is 55.5% of global sub revenue, but don't lead with it in the US/EU for health)
   - Don't underprice: expensive annual health plans earn 4.5x more per user than cheap ones.
3. **Blinkist trial timeline** on the paywall: "Today — full access unlocked · Day 2 — we remind you before billing · Day 3 — trial ends." This pattern lifted Blinkist trial starts +23% and cut complaints 55%. **The reminder notification must actually fire** — build it.
4. **Personalized headline** from onboarding answers: "Your plan to hit 95% adherence, Sarah" beats generic "Go Premium."
5. **Social proof block:** laurels (users count, rating), 2–3 rotating testimonials.
6. **Exit offer** on dismiss: a cheaper offer (e.g., $29.99/yr) via RevenueCat's native Exit Offers — test on Android first (iOS App Review gray area).
7. **Win-back:** trigger an offer within 10–15 minutes of cancellation; adopt Apple's native win-back offers; enable grace periods for billing errors.
8. **Everything Remote-Config-driven:** prices, plan order, headline, trial length, exit-offer discount. Target a cadence of 2+ paywall experiments per month. Trial-structure experiments have a 59.6% LTV win rate — 2x visual tweaks.

**Free tier (what remains free):** track up to 2 medications with reminders (matching Medisafe's new gate, so you're never worse than the incumbent), 3 AI scans total, basic history. Premium: unlimited meds, unlimited AI scans, interactions, family circle, PDF export, streak freezes, Wrapped sharing, widgets themes.

**New SKU to add:** **Family Plan (~$59.99/yr)** — your caregiver system is already built and no competitor packages it well. Also consider lifetime ($99.99) as an exit-offer-only SKU.

---

## 6. The 55-Screen Onboarding Funnel (Full Spec — Eato Visual Language)

Modeled directly on the Eato onboarding (your reference PDF) — the same funnel family as Cal AI ($50M/yr run-rate) and Noom ($750M/yr, up to 113 screens) — mapped onto MedAI's real features. Core psychology: sunk cost, endowed progress (progress bar starts ~5% filled), micro-commitments, instant feedback after every input, recurring personalization payoffs, and an "analyzing" climax so the paywall feels like a delivery, not a demand. Longer flows that build problem-awareness *outconvert* short ones (Rise cut worst drop-off to 19% with a longer redesign; progress indicators alone boost completion up to 28%).

### 6.1 Visual style guide (extracted from the Eato reference)

Your design tokens already contain `eatoNavy` (#1A2238) and cream (#FFF8F2) — this style is your codebase's native language. Codify it:

- **Canvas:** warm cream background; content on white radius-16/24 cards. No glass in onboarding — flat, warm, friendly.
- **CTA:** one full-width navy pill button ("Continue") pinned to the bottom of every screen. Never two competing CTAs (except Yes/No quote cards).
- **Header:** back chevron left, thin amber progress bar top-center (segmented by phase, pre-filled ~5% at start).
- **Selection cards:** white rounded cards, leading emoji-style icon in a colored squircle, 1-line label + optional 1-line sublabel. Selected state = cream fill + 2px amber border + haptic tick + 150ms scale pulse.
- **Big-input moments:** oversized data entry — wheel picker for birth year (physics + haptic detents), ruler slider for numbers with center hairline and a 48–64pt live value. These screens feel like instruments, not forms.
- **Instant-feedback chips:** after any numeric input, a card slides up beneath it: colored badge ("Realistic Target" / "Neutral") + reassurance copy + a "Source of recommendations" link. Evidence + empathy after every disclosure.
- **Quote cards ("Do you relate?"):** pastel full-card flat illustration + italic first-person quote + dual No/Yes navy buttons.
- **Comparison split-cards:** purple "old way" card vs yellow "MedAI way" card with a green check seal on the winner.
- **Chapter interstitials:** full-bleed saturated yellow/orange screens with a bold flat illustration marking section changes ("Let's know more about…").
- **Social-proof banner:** amber callout that appears after certain answers — "75% of users answered the same way."
- **Motion rules:** every screen enters with 300ms fade+rise; charts draw in over ~800ms (Rive); celebrations use fireworks/confetti Lottie; illustrations have a subtle idle loop; every selection has a haptic. Reduced-motion drops all of it to instant.

**Build rule:** every screen = one `OnboardingStep` object (id, type, analytics event, Remote-Config-orderable). Every screen fires `onboarding_step_viewed` + `onboarding_step_completed`. Answers persist to the profile and feed the plan reveal + paywall copy.

### 6.2 Screen-by-screen

**Phase A — Hook (1–5)**

| # | Screen | Type | Spec & motion |
|---|---|---|---|
| 1 | Laurel welcome | Brand | Laurel wreath badge (Rive draw-in) around "A Perfect Med Routine — Guaranteed In Our App" + thumbs-up pop. Copy: "Let's start with some questions to get your personalized plan!" CTA "Get Started." No sign-in — auth moves to the very end (Cal AI pattern). |
| 2 | Demo interstitial | Full-bleed | Eato-style bold yellow screen, flat illustration of a hand holding a phone scanning a pill; 6s silent loop: scan → identified → reminder set. The "wow" before any questions. |
| 3 | Attribution | Question | "How did you hear about MedAI?" TikTok / Instagram / App Store / Friend / Doctor / Other. |
| 4 | Primary goal | Question | "What is your primary goal?" — Never miss a dose / Manage family meds / Understand my medications / Track a condition. Icon cards. **Personalizes the paywall headline.** |
| 5 | Long-term results graph | Education | "MedAI creates **long-term** adherence" — amber area chart of "Your adherence" rising vs dashed "willpower alone" curve that rebounds down (the Eato weight-curve screen, 1:1). Caption: "76% of MedAI users maintain 90%+ adherence after 6 months." Chart draws in 800ms. |

**Phase B — Your profile, with instant feedback (6–17)**

| # | Screen | Type | Spec & motion |
|---|---|---|---|
| 6 | Who is this for? | Question | Myself / A parent / My child / Several family members. Routes caregivers toward the family-plan pitch. |
| 7 | Gender | Question | With Eato-style why-copy under the title: "Medication effects and dosing can differ by sex — this helps our AI personalize safety info." Male / Female / Non-binary / Skip. |
| 8 | Birth year | Big input | Wheel picker with physics + haptic detents (Eato birthyear screen). "Enter your birth year to improve interaction checks." |
| 9 | Weight | Big input | Ruler slider + kg/lbs toggle, 56pt live value. Why-copy: "Some dosages and interaction risks are weight-sensitive." |
| 10 | Instant feedback | Feedback chip | Slides up under the ruler: badge + "Got it — our AI will flag anything dose-sensitive for you." + "Source of recommendations" link. (Eato BMI-chip pattern.) |
| 11 | Conditions | Multi-select | Common conditions + "prefer not to say," with why-copy: "So the AI checks interactions relevant to you." |
| 12 | Reassurance | Trust | "Thank you for sharing. Your health data is encrypted and never sold." Shield Lottie. Reassurance after vulnerable questions measurably increases completion. |
| 13 | Med count | Big input | Oversized stepper/wheel: "How many medications & supplements do you take?" |
| 14 | Payoff #1 | Personalized | Amber banner screen: "**75% of users** with {3+} meds responded the same way" + "People like you improve adherence **23% in 2 weeks** with MedAI." First proof that answering matters. |
| 15 | Supplements? | Yes/No | "Do you also take vitamins or supplements?" |
| 16 | Interaction education | Full-bleed | Bold orange screen, flat illustration of colliding pills: "4 in 10 supplement users have a hidden interaction risk — most never know." Premium-hook setup. |
| 17 | Allergies | Multi-select | Eato food-restrictions analog: Penicillin / Sulfa / NSAIDs / Aspirin / None — feeds the AI safety profile you already store. |

**Phase C — Habits & empathy (18–29)**

| # | Screen | Type | Spec & motion |
|---|---|---|---|
| 18 | Miss frequency | Question | "How often do you miss a dose?" Never / Sometimes / Often / All the time. On select: social-proof banner "75% of users answered the same way." |
| 19 | Empathy stat | Education | "7 in 10 people miss doses. It's not willpower — it's systems." Normalizes shame; positions MedAI as the system. |
| 20 | Miss triggers | Multi-select | Eato "snack triggers" analog: Busy mornings / Asleep / Away from home / I just forget / Side effects / Something else. |
| 21 | Hardest time | Question | Morning / Midday / Evening / Night — feeds smart-reminder defaults. |
| 22 | Work schedule | Question | Eato screen 1:1: Flexible / Nine to five / Shifts / Caregiver at home / Retired / Between jobs. |
| 23 | Wake & sleep | Big input | Two sliders. "We'll time reminders to your real day." |
| 24 | Relate #1 | Quote card | Mirror illustration + "I always panic wondering if I already took my pill." No / Yes. |
| 25 | Relate #2 | Quote card | "My routine falls apart the moment my schedule changes." No / Yes. |
| 26 | Relate #3 | Quote card | "I worry about mixing my meds and supplements." No / Yes. |
| 27 | Relate #4 | Quote card | "I feel guilty when I let my routine slip for a few days." No / Yes. (4-in-a-row relate sequence is the Eato pattern — each Yes is a micro-commitment.) |
| 28 | Payoff bars | Personalized | Eato "lose twice as much" analog: two bars, "Without MedAI" small vs "With MedAI" tall — "78% of users report less medication anxiety within 3 weeks." Bars grow in with spring physics. |
| 29 | Split card | Comparison | "Generic alarms" (purple: only rings, ignores your life, easy to swipe away) vs "Your MedAI Plan" (yellow + green seal: timed to your day, escalates if missed, learns your patterns). |

**Phase D — Feature education (30–41)**

| # | Screen | Type | Spec & motion |
|---|---|---|---|
| 30 | Chapter interstitial | Full-bleed | Bold yellow: "Let's see how MedAI does the heavy lifting." (Eato fork-and-spoon analog — pill + phone illustration.) |
| 31 | Knowledge quiz | Question | "Do you know exactly what's in every pill you take?" I know all of them / I often check / Not really. |
| 32 | Feature: AI Scanner | Showcase | Phone mockup with camera view of a pill + floating AI chips (name · dosage · form · maker) — the Eato food-scan screen 1:1. Chips pop in sequentially. |
| 33 | Split card | Comparison | "Manual logging" (purple: type everything, takes forever) vs "MedAI AI Tracker" (yellow + green seal: point camera, done in a second). |
| 34 | Feature: All scan modes | Showcase | "Not only barcode — direct pill scanning" (Eato copy 1:1): barcode, prescription QR (JAHIS — a Japan differentiator no competitor has), photo, voice. |
| 35 | Record quiz | Question | "Do you keep a record of your doses?" Every dose / When I remember / Not at all. |
| 36 | Knowledge quiz | Question | "Do you know how missed doses affect your treatment?" Yes / Somewhat / Not sure. |
| 37 | Education | Chart | Adherence-cliff chart: "Missing just 2 doses a week can cut some treatments' effectiveness by up to 40%." + "Source of recommendations" link. Dark stat → resolution next screen. |
| 38 | AI brain diagram | Showcase | Eato brain screen 1:1: central brain illustration with 4 orbiting chips — Gemini Vision · Interaction Engine · Smart Reminders · Learning Model. "MedAI's AI makes staying on track painless." |
| 39 | Feature: Family Circle | Showcase | Caregiver live-adherence view + nudge button. Emphasized on the caregiver path from #6. |
| 40 | Feature: Streaks & Wrapped | Showcase | Streak flame (Rive, reacts to touch) + a Monthly Wrapped share card. "Staying on track, made addictive — the good kind." |
| 41 | Testimonial | Social proof | Eato testimonial card 1:1: user photo, ★★★★★, amber "98% adherence" tag, quote: "I haven't missed a dose in 4 months. My doctor noticed." |

**Phase E — Motivation & projection (42–49)**

| # | Screen | Type | Spec & motion |
|---|---|---|---|
| 42 | Chapter interstitial | Full-bleed | Eato screen 1:1: orange mountains + paper plane. "Let's focus on what's driving you. Research shows keeping motivation front of mind drives lasting change." |
| 43 | Motivation | Question | "What motivates you most?" Feeling in control / Protecting my health / Peace of mind for my family / Proving I can stick to it. |
| 44 | What matters | Question | "When it comes to your health, what's most important?" More energy / Independence / Being there for family / Living longer. |
| 45 | Potential curve | Payoff | Eato "crush your goal" screen 1:1: rising curve with emoji milestones at 3 days 🙂 → 7 days 😃 → 30 days 🤩 → GOAL. "Habits are hardest the first week — after 7 days, your routine locks in." |
| 46 | Last time on track | Question | "When were you last fully on top of your meds?" <1 year ago / 1–2 years / 3+ years / Never / I'm on top now. |
| 47 | **Adherence projection** | Payoff (hero) | Animated Rive chart: "Your adherence: ~{61%} today → **94%** by {Aug 2}." The Noom recurring-payoff — the single most important pre-paywall screen; re-shown on the paywall. |
| 48 | Commitment | Micro-commit | "Can you give MedAI 30 seconds a day?" — "Yes, I'm in" / "I'll try." |
| 49 | Personal summary | Payoff | Eato BMI-summary screen 1:1: card with adherence-risk gauge (colored scale + your marker), med count, level tag ("Beginner routine"), hardest time, target adherence, allergies noted. "Personal summary based on your answers" + source link. |

**Phase F — Proof & permissions (50–52)**

| # | Screen | Type | Spec & motion |
|---|---|---|---|
| 50 | Laurels + rating | System | Laurel badge + 2–3 rotating testimonials, then native SKStoreReviewController at the motivation peak (Cal AI & AIBY pattern; only 3 iOS prompts/year — this placement earns it). |
| 51 | Notification primer | Pre-permission | One benefit, not a list: "Users with reminders take **93%** of doses on time." Enable reminders / Not now → system prompt only on Yes. Primers lift opt-in 2–3x. |
| 52 | Health sync + ATT | Pre-permission | Apple Health / Google Fit connect (optional, skippable), then ATT prompt — after value is established, not at first launch (the Lily teardown's exact criticism). |

**Phase G — Activation, analysis, reveal (53–55)**

| # | Screen | Type | Spec & motion |
|---|---|---|---|
| 53 | **Add your first med** | Activation | Search-as-you-type or "Scan it" (one free AI scan — the magic moment), then confirm its reminder time with a smart default from #21–23. Confetti tick: "Your first reminder is live." Session-1 activation makes users 2–3x more likely to subscribe. |
| 54 | **Building your plan…** | Analyzing | 4–6s, per-section progress bars with checkmarks: "Analyzing your schedule ✓ · Checking interactions ✓ · Calibrating reminders ✓ · Building your plan ✓" — never a spinner. Dramatizes work done on the user's behalf. |
| 55 | **Plan reveal → Paywall** | Monetization | "{Name}, your personalized plan is ready" — their med, their reminder time, their 94% projection from #47, their goal from #4. CTA "See my plan" slides the §5 paywall up as a sheet (annual-led, trial-badged, trial timeline, personalized headline, exit offer on dismiss). After purchase/trial: fireworks Lottie (Eato celebration screen) + Apple/Google sign-in to save the plan, landing on Home with their dose front and center. |

**Funnel benchmarks to hold yourself to:** ≥65% reach the paywall (screen 55), install→trial ≥12% (NA median 14.5%), trial→paid ≥30% (health median 35%), per-screen drop-off <4% average (instrument every screen; kill or rewrite anything above 8%). With 55 screens, Remote-Config ordering is non-negotiable — you will prune and reorder weekly based on the funnel dashboard.

---

## 7. Feature Roadmap — Impressive Features & Micro-Features

### 7.1 New headline features (revenue/retention drivers)

1. **Home-screen & lock-screen widgets** (highest-impact missing feature). Next-dose card + adherence ring on the lock screen; small/medium home widgets. Duolingo's streak widget raised user commitment ~60%. You already ship Live Activities — widgets are the natural sibling. Premium: widget themes.
2. **Apple Watch app + complications.** Dose check-off from the wrist; corner complication with next-dose countdown. Med adherence is *the* wearable-native use case.
3. **AI Med Assistant (finish the voice + chat you started).** Merge `product_chat` + voice assistant into one Gemini-powered assistant with function calling: "log my metformin," "what happens if I miss a dose of lisinopril?", "when's my next refill?" AI apps monetize 41% better — but only when the AI is a daily habit, not a demo.
4. **Smart refill radar.** You have inventory forecasting — add bottle-photo pill counting (Gemini vision), pharmacy-day reminders, and a "running low in 6 days" push. Refill friction is the #1 stated reason for real-world non-adherence.
5. **Family Plan tier.** Package the caregiver circle you already built: shared dashboard, missed-dose alerts to caregivers, AI Protector Insights (finish the 60%). Price ~$59.99/yr. No major competitor packages this well.
6. **Adherence Report for doctors.** Upgrade the PDF export into a shareable monthly "clinical report" (adherence %, timing heatmap, symptoms log) — a genuinely premium-feeling artifact that also markets the app inside clinics.
7. **Streak system v2 (forgiveness-first).** Auto-granted freezes at 7/30/100-day milestones, streak-repair flow, softened streak rule (any dose logged keeps the streak alive — Duolingo's softening added +3.3% D14 retention). 7-day streakers are 2.4x more likely to return next day; combine with milestones for 40–60% higher DAU.

### 7.2 Micro-features & app behaviors (the "2026 feel")

- **Triple-fire reminders** (Medisafe pattern, clinically validated): unanswered dose reminder re-fires 3x every 10 minutes with escalating copy; mHealth reminder systems improve adherence 17–23% vs control.
- **Notification copy variants** rotated via Remote Config; personalized with med name + streak ("Day 47 🔥 — metformin time").
- **Haptic dose check-off** — the ring-fill haptic on marking a dose taken is your signature micro-interaction; pair with a subtle Rive pulse.
- **"Why this med matters" cards** — one-line Gemini-generated education per med shown occasionally in the timeline; pairing reminders with education produces durable adherence (not just prompted compliance).
- **Trial-reminder push that actually fires** on day 2 of the trial (the promise on your paywall timeline — also cuts refund complaints ~55%).
- **Contextual review prompts** after streak milestones and a perfect week (3–5x higher conversion than random prompts); never Google's banned "enjoying the app?" pre-screen.
- **Custom pull-to-refresh** (pill-drop Rive animation), motion-designed empty states, skeleton shimmers everywhere content loads (you have the components — enforce usage).
- **Win-back push + email** within 15 minutes of cancellation with a discounted annual offer.
- **Referral loop:** give-a-month/get-a-month, promo-code field in onboarding screen 3 area (Cal AI's referral field sits inside onboarding), share cards from Wrapped with referral deep links.
- **Sync status pill** — quiet indicator that data is synced (fixes the silent `.catchError` trust gap).
- **Time-zone-safe scheduling** and DST audit on the alarm engine (top complaint category for reminder apps).

---

## 8. Growth Engine (What to Instrument Before You Spend $1 on Ads)

**Analytics stack to add:** `firebase_remote_config` (experiments + config), Amplitude or Mixpanel (cohorts, funnels, LTV), AppsFlyer or Adjust (attribution + SKAN), and keep Crashlytics/Performance. Define the canonical funnel: install → onboarding_step_N → trial_start → activation (first dose logged) → D1/D7/D30 retention → paid → renewal.

**ASO 2026:** Apple now OCR-indexes screenshot text and auto-generates App Store Tags — put "AI pill identifier," "medication reminder," "pill tracker" *inside* screenshot captions. Intent-phrase keywords ("AI pill reminder") beat the generic "AI" token. Maintain review velocity via the contextual prompts above; a 4.0+ rating is the ASO floor and 3→4 stars nearly doubles conversion. New pre-store layer: users ask ChatGPT/Gemini for app recommendations — publish comparison/FAQ content that LLMs can cite.

**Paid UA:** the entire $1M+/mo class buys installs from day one (TikTok + Meta + Apple Search Ads). Creative angle that wins in this category: POV demo of scan-to-reminder magic moment + caregiver emotional angle ("I always know Mom took her meds"). Start at $50–100/day only after attribution + paywall experiments are live, targeting payback < 6 months.

**Localization leverage:** you ship 8 languages already — add localized *pricing* and localized screenshots; Japan (you already parse JAHIS codes!) and Germany are high-ARPU, underserved med-app markets.

---

## 9. The Path to $1M MRR (Honest Math)

At health-category ARPU (~$40/yr ≈ $3.30/mo), $1M MRR ≈ **~300k paying subscribers**. Funnel math at category benchmarks (12% install→trial, 35% trial→paid ≈ 4.2% install→paid): roughly **7–8M lifetime quality installs**, i.e., ~2M installs/year for 3–4 years or faster with paid UA. Context: only 4.6% of new apps reach even $10K MRR within two years; the top 25% of subscription apps grew 80% YoY. The playbook works, but it is an execution game measured in experiments per month.

Staged targets:

| Stage | MRR | What gets you there |
|---|---|---|
| 1 (months 1–3) | $10k | Rebuilt funnel + hard paywall + annual pricing on existing organic traffic; 2 paywall experiments/mo |
| 2 (months 4–9) | $100k | Paid UA at proven CAC, widgets + streaks v2 retention lift, localized pricing, family plan |
| 3 (months 10–24) | $1M | Scale winning channels, win-back + exit offers compounding, Japan/DACH localization, 50+ cumulative experiments |

---

## 10. 90-Day Execution Roadmap

**Phase 1 — Monetization infrastructure (weeks 1–4).** Add Remote Config + Amplitude + AppsFlyer; instrument the full funnel; rebuild the paywall (annual-led, trial-badged, timeline, personalized headline, exit offer); enable grace periods + win-back; ship free-tier gate at 2 meds / 3 scans. *Do this before touching onboarding — otherwise you can't measure the redesign.*

**Phase 2 — Onboarding rebuild (weeks 5–8).** Refactor `onboarding_flow.dart` into polymorphic, Remote-Config-ordered steps; implement the 55-screen Eato-style spec (§6) with per-screen events; permission primers; mid-flow rating prompt; activation moment (first med + one free scan); analyzing → plan reveal → paywall.

**Phase 3 — Retention & polish (weeks 9–12).** Dashboard redesign around the adherence ring (§4); lock-screen/home widgets; streaks v2 with freezes + repair; triple-fire reminders; finish the AI assistant; fix silent error swallowing + sync status; unit tests on purchase/entitlement/scheduling/streak paths; decompose `home_tab.dart`.

Then: watch the funnel dashboards, run 2+ experiments per month, and scale paid UA only when install→paid × ARPU > CAC with 6-month payback.

---

## 11. Sources

Paywall & pricing: [RevenueCat State of Subscription Apps](https://www.revenuecat.com/state-of-subscription-apps/) · [Adapty State of In-App Subscriptions](https://adapty.io/state-of-in-app-subscriptions/) · [Adapty health & fitness benchmarks](https://adapty.io/blog/health-fitness-app-subscription-benchmarks/) · [Toggle-paywall ban](https://adapty.io/blog/your-toggle-paywall-is-about-to-get-rejected/) · [RevenueCat on the toggle ban](https://www.revenuecat.com/blog/growth/r-i-p-toggle-paywall-we-hardly-knew-ye/) · [Blinkist trial timeline case study](https://growth.design/case-studies/trial-paywall-challenge) · [RevenueCat Exit Offers](https://www.revenuecat.com/blog/engineering/exit-offers-in-revenuecat-paywalls/) · [Apple win-back offers](https://www.revenuecat.com/blog/growth/guide-to-apple-win-back-offers/) · [Superwall paywall patterns](https://superwall.com/blog/5-paywall-patterns-used-by-million-dollar-apps)

Onboarding science: [Noom 113-screen teardown](https://growthwaves.substack.com/p/the-113-screen-onboarding-that-doesnt) · [RevenueCat web-to-app funnel](https://www.revenuecat.com/blog/growth/web-to-app-onboarding-funnel/) · [RISE "too short" onboarding](https://www.revenuecat.com/blog/growth/why-your-onboarding-experience-might-be-too-short/) · [Cal AI flow teardown](https://screensdesign.com/showcase/cal-ai-calorie-tracker) · [Progress bar psychology](https://userpilot.com/blog/progress-bar-psychology/) · [Push opt-in primers](https://www.pushwoosh.com/blog/increase-push-notifications-opt-in/)

Comps & studios: [Lily teardown (ScreensDesign)](https://screensdesign.com/showcase/ai-plant-identifiercare-lily) · [Codeway case study](https://blog.sparrowapps.io/p/how-codeway-built-a-25m-month-app-empire) · [AIBY case study](https://thegrowthhackinglab.com/case-studies/aiby-app-studio-100-million/) · [Cal AI (CNBC)](https://www.cnbc.com/2025/09/06/cal-ai-how-a-teenage-ceo-built-a-fast-growing-calorie-tracking-app.html) · [Medisafe free-tier change](https://pillo.care/blog/medisafe-no-longer-free-best-free-alternatives) · [Flo statistics](https://www.businessofapps.com/data/flo-statistics/) · [Bevel Series A](https://techcrunch.com/2025/10/30/bevel-raises-10m-series-a-from-general-catalyst-for-its-ai-health-companion/)

Retention & clinical: [Duolingo streak mechanics](https://duolingo.deconstructoroffun.com/mechanics/streaks) · [Streak widget impact](https://sensortower.com/blog/duolingo-streak-feature-app-engagement-growth) · [mHealth adherence meta-analysis (JMIR)](https://www.jmir.org/2025/1/e60822) · [Reminder-latency study](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8512193/) · [420-app reminder analysis](https://pmc.ncbi.nlm.nih.gov/articles/PMC5878368/)

UI/UX 2026: [Liquid Glass design](https://openforge.io/what-is-ios-liquid-glass-design/) · [Rive vs Lottie](https://rive.app/blog/rive-as-a-lottie-alternative) · [Health dashboard patterns](https://basishealth.io/blog/personalized-health-dashboards-design-guide-and-best-practices) · [Apple Design Awards](https://developer.apple.com/design/awards/) · [ASO 2026 guide](https://www.applaunchflow.com/blog/aso-2026-guide)


