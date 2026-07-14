# MedTrack AI — Cal AI Design Language Spec
*The verifiable pattern. Applied to 2-3 reference screens, then propagated. Grounded in your real tokens (`app_theme.dart`, `app_tokens.dart`).*

## The core diagnosis (from your screenshots)
Your app isn't ugly — it's **loud**. Cal AI's premium feel = **restraint**. The gap, concretely:
- **Rainbow icon chips** (orange/red/pink/purple squares in Settings "Your Info", Home). Cal AI uses one neutral chip.
- **Colored category pills** (`adherence` green / `optimization` purple / `safety` pink). Cal AI: no colored tags, or one muted grey.
- **Accent overuse** — green hero + green pills + green icons + green nav. Cal AI: mostly black/white/grey, accent used on **~1 thing per screen**.
- **Not enough whitespace / number hierarchy.** Cal AI leads with huge bold numbers and lots of air.

## The 6 rules (this IS the Cal AI look)

> CALIBRATED against Cal AI's real App Store screenshots (2026). Key correction:
> Cal AI is NOT pure monochrome — it uses color in exactly TWO places: **data
> viz** (macro rings, charts) and **the streak** (orange flame). Base is
> black/white/grey; decoration gets zero color. And critically: **their primary
> action/FAB/active-nav is BLACK, not a brand color.** That's the biggest gap
> vs MedTrack (green everywhere).
>
> BRAND NOTE: Do NOT literally copy their monochrome — that throws away
> MedTrack's green identity to imitate theirs. Copy the DISCIPLINE, not the
> palette: keep green, but reserve it for the 1 primary action + data viz +
> streak per screen. Green on decoration/chips/categories = the thing to kill.
1. **Monochrome-first.** Black text (`L.text`), grey sub (`L.sub`), white cards (`L.card`), off-white bg (`L.bg`). That's 90% of every screen.
2. **One accent, once per screen.** `L.accent` on the single primary action or key metric — never on decoration, chips, or multiple elements at once.
3. **Kill category colors.** Insight/category pills → neutral: `L.fill` background, `L.sub` text. No green/purple/pink tags.
4. **Neutral icon chips.** The colored rounded squares → `L.fill` (light grey) bg with `L.text` or `L.sub` icon. Same chip everywhere. Color only to signal true status (red=danger, amber=warning) — never for category/decoration.
5. **Big numbers, thin dividers, more air.** Metrics in `displaySmall`/`headlineLarge` bold. Rows separated by hairline `L.border` dividers or pure spacing, not heavy cards-in-cards. Bump section padding to `AppSpacing.p24`.
6. **Flatten depth.** Reduce nested colored cards. One card level, low-noise shadow, `AppRadius.l` (24). Glass only on nav chrome (already correct per your tokens).

## Token mapping (use these — they exist)
| Purpose | Token | Never use for this |
|---|---|---|
| Text | `L.text` (navy/white) | — |
| Secondary text | `L.sub` | — |
| Card | `L.card` | colored fills |
| Screen bg | `L.bg` | — |
| Neutral chip / pill bg | `L.fill` | `accent`/`purple`/`pink` |
| Hairline divider | `L.border` | heavy shadows |
| THE accent (1×/screen) | `L.accent` | chips, icons, decoration |
| Danger only | `L.red` | categories |
| Warning only | `L.amber` | categories |

## What NOT to touch (already Cal-AI-correct)
- Glass tokens (`glass` = no color tint — good).
- Bottom nav (Home/Trends/Scan/Alarms/Circle — 5 items, clean).
- Typography scale (Outfit, good weights).
- The green **hero** cards (Alarms upcoming-dose) — these are fine as the ONE accent moment per screen. Don't make everything green; keep the hero, neutralize the rest.

## Reference screens (built as the pattern)
1. **Settings icon chips** ✅ DONE — `iosSettingsIconColor` (ios_settings_style.dart) was a per-emoji rainbow (🎯→orange, 🩺→red, 🎂→pink, 🧬→purple). Now MONOCHROME by default; red only for delete/logout. **Central fix — propagates to every settings row app-wide** (My Profile, Your Info, App Settings, Data & Privacy).
2. **AI insight category pills** ✅ DONE — `dashboard_widgets.dart:319` was lime-green (adherence) / purple (optimization) / red (safety). Now neutral `L.sub` for everything except real safety warnings (kept red). De-noises the Home + Trends insight lists.
3. **Home dose/stat surface** — TODO: apply air + number hierarchy (not yet touched; needs care, compile between).

## Remaining rainbow to hunt (per screen family, compile between — NOT blind)
- `dashboard_ref_cards.dart` — hardcoded pastel gradients (`0xFFFFB8D9` pink, `0xFFFFC8A8` peach, etc.). Replace with `L.fill`/`L.card` neutrals.
- Any other `AppColors.pastel*` / hardcoded hex in dashboard + home stat cards (token audit counted 212 hardcoded hex app-wide).
- Category/status chips in stats_tab, trend_drilldown_sheet, clinical_report_modal.

## Mascots (AFTER the de-noise, per your instruction)
- **Small.** 32–48px in-line, not hero-sized. A Cal-AI app uses a mascot as a *garnish*, not a billboard.
- Placement: empty states, celebration moments, one per screen max.
- Motion: subtle — a gentle scale-in/fade on appear, respect reduced-motion. No looping bounce on daily UI.
- Already wired: home empty (home_heart), family empty (caregiver_elder). Resize those down to ~48px once palette is calm.

## Propagation plan (after references verified)
Once you compile + screenshot the 3 reference screens and confirm the look: the rest is find-and-replace of the same patterns (colored chip → `_NeutralChip`, category color → `L.fill`), done per screen family, compiling between. NOT a blind 99-screen rewrite.
