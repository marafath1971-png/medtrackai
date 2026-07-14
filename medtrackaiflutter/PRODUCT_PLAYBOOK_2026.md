# MedTrack AI — Product Playbook: Psychology, Retention, Virality & AI-Feel
*July 2026. Builds on `GROWTH_STRATEGY_2026.md` (competitive/pricing/niche/ASO/compliance) — does not repeat it. This doc = the behavioral + product-design layer, mapped to what's already shipped this session.*

> Scope note: the "Phase 1–4 scheduling app" part of the brief is a template for a different product (meeting scheduling / task prioritization). Ignored. The transferable *principles* are applied to the medication app below.

---

## 1. What actually makes top AI consumer apps win (it's not features)

| App | The one mechanic that prints money | Transferable principle |
|---|---|---|
| **Cal AI** | Photo → instant calorie breakdown. Zero typing. Value in <5s. | **One-tap to "aha"**; kill setup friction |
| **Duolingo** | Streaks + streak freezes + loss aversion + a guilt-tripping owl | **Loss aversion > reward**; forgiveness keeps the streak alive |
| **Finch** | A pet that needs *you* to do self-care; it's sad if you don't | **Emotional attachment**; the app "needs" you back |
| **Yuka** | Scan product → a single color-coded score (red/yellow/green) | **One number, instant judgment**; complexity hidden |
| **Headway** | Daily bite-sized summaries + progress bar + "you're in top X%" | **Progress made visible**; small daily wins |
| **Remini** | Free result, *then* paywall on the enhanced version | **Value first, wall second** |
| **ChatGPT/Character AI** | Feels like it *remembers* and *understands* you | **AI memory + context** = perceived intelligence |

**The through-line:** users pay for and return to apps that (a) deliver value in one action, (b) make progress visible, (c) create something to lose, and (d) feel personal. Not feature count.

---

## 2. The 7 principles → mapped to MedTrack (✅ = shipped this session)

**1. One-tap to value (Cal AI).** Scan → what it is/how it works/side effects, no typing.
→ You have this. ✅ We also added a *manual* one-tap add for the no-camera case, and ✅ made the scan result honest (confidence + disclaimer) so the "aha" is trustworthy, not a liability.

**2. Loss aversion beats rewards (Duolingo).** People protect a streak harder than they chase a badge.
→ Streaks + auto-granted streak freezes already exist. **Gap:** the freeze button is invisible in the streak modal (noted in the deep audit). *Next lazy win: wire the existing `onFreeze` callback to a visible button — ~5 lines.*

**3. Something to lose + someone watching (Finch + Duolingo).** Accountability is retention.
→ ✅ We made caregiver alerts real (missed-dose push) + ✅ passive detection. A caregiver watching *is* the accountability loop. This is your Finch-pet equivalent, but with real stakes.

**4. Value first, paywall second (Remini).**
→ ✅ We moved the paywall to fire *after* the first med (the aha), not before. This is the single biggest conversion fix and it's done.

**5. Make progress visible (Headway).**
→ Adherence ring + 7-day sparkline exist and now show *real* data. ✅ We added the doctor-report card so progress becomes a shareable artifact. **Gap:** no "you're in the top X%" — and honestly, *don't* fake it (compliance risk + the audit already caught fabricated percentile copy). Use real streak tiers instead.

**6. Virality = a reason for two people (Duolingo family / Finch friends).**
→ ✅ We wired the referral loop (give-a-month) + the caregiver invite *is* inherently 2-sided (patient + carer = 2 accounts). Un-paywalled the invite. **Gap:** deep-link association for `medai.app` isn't configured — links don't auto-open the app yet (owner action, noted).

**7. AI that feels like it remembers (ChatGPT).**
→ Partial. Scan/insight are one-shot. **Next real win: personalized reminder copy + insights keyed to the user's actual meds/adherence** — infra exists (`getHealthInsight` cloud function, onboarding profile). Low effort, high "feels intelligent" payoff.

---

## 3. Prioritized roadmap (highest impact first)

Every row: why it matters / complexity / impact. Skipping the essays — the mapping above is the "why."

| # | Move | Lever | Cx | Impact | Status |
|---|---|---|---|---|---|
| 1 | **Compile + deploy the 9 stacked change-sets** | everything | Low | **Critical** | ⛔ blocked on you |
| 2 | Un-hardcode `AppState.isPremium` → real entitlement | revenue | Low | **High** | pending |
| 3 | Configure App Links for `medai.app` | virality | Low | **High** | pending (native config) |
| 4 | Visible streak-freeze button in streak modal | retention (loss aversion) | Low | Med | ✅ **shipped** |
| 5 | Personalized reminder/insight copy from user's meds | AI-feel + retention | Med | High | infra exists |
| 6 | Vitals/symptom journaling (BP/glucose/mood) | retention + ASO | Med | High | partial (`wellness_controller`) |
| 7 | "Top X% / tier" progress moment — **real** tiers only | motivation | Low | Med | streak tiers exist |
| 8 | Weekly recap push → deep-link to Wrapped | re-engagement | Med | Med | Wrapped exists, unwired |

Items 4–8 are all **wiring existing code**, consistent with everything this session. None needs a rewrite.

---

## 4. The thing a world-class PM says here, not another feature

You've shipped **9 feature/backend change-sets I could not compile** (no Flutter/Firebase toolchain in my env). The research is clear that execution quality — crash-free rate, reminders that actually fire — now outweighs feature count in both retention *and* store ranking. A 10th unverified change is negative EV.

**The highest-impact next action is not code. It is:**
```
flutter pub get && flutter analyze
firebase deploy --only functions
```
Paste me any errors; I'll fix fast. Then we un-hardcode `isPremium` (item 2) and the whole monetization stack goes live at once.

**Redesign "everything" / "refactor the codebase"?** No. The audit found the app is *under-wired, not under-built* — a full redesign would throw away working code to solve a problem you don't have. We keep wiring high-impact loops one at a time, compiling between. That's the path to $100K MRR, not a rewrite.

---

## 5. Security finding (from Cal AI's 2026 breach)

Cal AI's cautionary tale in 2026 wasn't just deceptive paywalls (Apple briefly pulled it) — it was a **data breach exposing 3.2M+ user records via an unauthenticated Firebase database.** Since MedTrack is on Firebase, I audited `firestore.rules` + `storage.rules` against exactly that failure mode.

**Verdict: you're NOT exposed.** ✅ Auth required on every path; ✅ owner-scoped reads/writes; ✅ caregiver access gated behind an active-caregiver check; ✅ 24h invite-code expiry enforced in-rules; ✅ default-deny catch-all (`match /{document=**} { allow ... : if false }`); ✅ storage locked to owner + image-only + 5MB. This is genuinely well-built and is the single highest-stakes thing in the project — already handled.

**One nuance to watch:** the new caregiver Cloud Functions I added run with admin privileges and resolve recipients server-side (no client-supplied targets) — that's the correct pattern and consistent with these rules. The pre-existing `sendMissedDoseAlert` callable is the one exception (accepts a client target) — lock it down or remove it, as previously flagged.
