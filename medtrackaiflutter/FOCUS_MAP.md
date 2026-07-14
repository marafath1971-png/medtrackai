# MedTrack AI — Focus Map (the framework, applied to your actual code)

*Ran your app through the Core Function → Loop → Accessory → Surface Area → Retention gates. This is the concrete output: keep / demote / cut, per screen family.*

## Gate results (measured, not guessed)
- **Core Function** — ⚠️ two jobs bolted together (scan-to-understand + track-to-adhere). Pick a lead.
- **Core Loop** — ✅ scan→result and log→streak are both <30s. Strongest area.
- **Surface Area (primary)** — ✅ **PASS**: 4 tabs + Scan = 5. Don't touch the bottom nav.
- **Surface Area (depth)** — ❌ 66 routes / ~99 screen files. This is the real bloat.
- **Retention Hook** — ✅ streaks + freezes (freeze button now surfaced).

## The lead-job decision (resolves the Core Function gate)
**Lead = "Never miss a dose, together."** Adherence + caregiver is the paying, viral job (research: adult-child caregiver is the payer + viral node). **Scan is the hook, not a co-equal product** — it's how you acquire and how a med gets added, feeding the adherence loop. One sentence: *"Scan your meds, never miss a dose, and let family keep watch."*

## Screen families → keep / demote / cut

**CORE LOOP (keep prominent — these ARE the product):**
- `home` — the daily log→adhere surface. The loop lives here.
- `scan` + `analysis` — the acquisition hook + understand payoff.
- `alarms` — reminders = the adherence engine.
- `medicine` — detail/edit, the unit of the loop.
- `family` (Circle) — the caregiver growth+retention engine.

**SUPPORTING (keep, but one layer down — serve the loop indirectly):**
- `dashboard`/`stats` — progress visibility (Headway principle). Trends tab is fine; the *sub*-screens (inventory, analytics deep-dives) stay demoted.
- `onboarding`, `paywall`, `auth`, `settings`, `loading`, `security` — plumbing. Necessary, never prominent.

**ACCESSORY (demote hard or cut — fails "does it serve the loop?"):**
- `social` (med_buddies, leaderboards) — social-comparison ≠ core adherence. Demote deep into stats; don't build more.
- `stats/monthly_wrapped`, `trophy_case`, `med_wrapped` — delightful, but accessory. Keep as a *seasonal push* (re-engagement), not a nav destination.
- `visualizer` (impact_visualizer) — cool, off-loop. Demote.
- `focus` (focus_mode) — off-loop. Demote or cut.
- `admin` (growth_dashboard) — internal tool, should never ship to users. Gate behind a dev flag.

## What to DO with this (the safe version of "trim to 5–7")
1. **Don't delete working code.** Demote = move off the bottom nav / bury one layer down. You keep the revenue features (caregiver, PDF, referral) — they're core or supporting, not accessory.
2. **Stop adding accessory features.** Before building anything new, ask: *does it serve scan→understand or log→adhere?* If no, don't. (This is the gate that matters going forward.)
3. **The bottom nav is already right** — leave Home / Trends / Alarms / Circle + Scan alone.
4. **Gate `admin/growth_dashboard`** behind `kDevPreview` or a build flag so it can't ship to users.

## What this framework does NOT cover (so don't stop here)
Zero on monetization, activation, or growth loops — the things that make $100K MRR. A perfectly-focused app with no paywall makes $0. The session's revenue work (value-first paywall, referral, caregiver alerts, `isPremium` live) is the other half. **This map = focus discipline. The revenue engine still has to ship (compile + deploy).**
