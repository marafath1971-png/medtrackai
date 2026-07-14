# MedTrack AI — UI Gap Audit (evidence-based)

*Generated 2026-07-11. Unlike `PREMIUM_UI_UX_AUDIT.md` (aspirational), this is a code-scan of concrete violations against the app's own design system (`lib/theme/app_tokens.dart`) and iOS HIG / WCAG 2.2. Every number below is reproducible with grep.*

Scope: `lib/screens/**` — ~48k LOC across 13 screen families.

---

## ✅ Progress (2026-07-11)

- **RTL correctness (started):** converted asymmetric directional padding to `EdgeInsetsDirectional` in shared components (`unified_header.dart`, `interaction_warning_banner.dart`). The full ~100-site migration is scripted safely in `scripts/rtl_migrate.sh` — run it locally with the analyzer (`./scripts/rtl_migrate.sh` dry-run, then `--apply` → `dart format` → `flutter analyze`). Rationale: applying ~100 blind edits with no compiler available is riskier than one reviewable, git-tracked pass.
- **Reduced-motion:** guarded the continuous rotate/scale in `weekly_wellness_ring.dart` behind `MedAiA11y.reducedMotion`. (The `home_tab.dart` grep hit was a false positive — a `Tween.animate()` transition, not a looping decoration.)
- **Deferred (mechanical, low-risk, needs analyzer):** the ~800 spacing literals, 413 font sizes, 212 hex colors, 81 `Colors.*`. These are cosmetic drift, not correctness — best done as batched find-and-replace **with** `flutter analyze` running, not blind. Highest-value next batch: the 81 semantic `Colors.red/green` (theme-breaking) in the top-10 hex files.

---


## Severity 1 — Design-token drift (highest ROI, mechanical)

The token system exists and is good (`AppSpacing`, `AppRadius`, `AppTypography`, `AppColors`), but screens bypass it constantly. This is the root cause of the "visual consistency gap" the premium audit describes in prose.

| Violation | Count | Correct token |
|---|---:|---|
| `EdgeInsets.*(literal number)` | **572** | `AppSpacing.p*` |
| `SizedBox(height/width: literal)` | **871** | `AppSpacing.p*` gaps |
| `fontSize: literal` | **413** | `AppTypography.*` |
| `BorderRadius.circular(literal)` | **261** | `AppRadius.round*` |
| `Color(0x…)` hardcoded hex | **212** | `AppColors` / theme |
| `Colors.<material>` (red/green/grey…) | **81** | semantic tokens |

**Worst offenders (hex colors):**
- `onboarding/widgets/ob_video_style_widgets.dart` — 35
- `medicine/medicine_detail_screen.dart` — 15
- `onboarding/onboarding_theme.dart` — 14 (a theme file, so partly legitimate)
- `social/med_wrapped_screen.dart` — 12
- `home/widgets/settings/stats_tab.dart` — 11

**Why it matters:** dark-mode / theme-customization (`theme_customization_screen.dart` ships!) can't retint hardcoded hex. `Colors.red` for a "delete" action won't follow the theme. This is the single biggest lever on the "premium consistency" goal and it's almost entirely find-and-replace.

**Fix path:** start with the top-10 hex files + the 81 `Colors.*` calls (semantic, high visibility). The 800+ spacing literals are lower-risk cosmetic drift — batch by screen family.

---

## Severity 1 — Localization debt (ships 7 locales, incl. 2 RTL)

App ships **ar, en, es, he, ja, ko, ms**. Yet UI strings are largely hardcoded English.

- `AppLocalizations.of(context)` used in only **7** places across all screens.
- **~80** literal `Text('English')` strings in screens; hotspots:
  - `home/widgets/settings` — 18 (incl. "Delete Account" dialog, "Enjoying MedAI?")
  - `medicine` — 11
  - `settings` — 7
- Onboarding uses its own `ObL10n` layer (56 steps) — but `REDESIGN_CHANGELOG.md` confirms **onboarding strings are hardcoded English**, a known follow-up.

**RTL correctness (ar, he):**
- `EdgeInsetsDirectional` / `AlignmentDirectional` usage: **0**
- Hardcoded `EdgeInsets.only(left:/right:)`: **31**
- Hardcoded `Alignment.centerLeft/Right` etc.: **74**

Arabic/Hebrew users get left-anchored layouts. This is a correctness bug, not polish. Convert directional padding/alignment in shared components first (headers, list rows, cards) for the widest coverage.

---

## Severity 2 — Accessibility labels on non-text UI

- `Icon(`/`Image.` instances (candidates needing labels): **272**
- `semanticLabel:` provided: **11** (~4% coverage)
- `Semantics(` wrappers: 163 (decent — but many wrap layout, not icon-only buttons)

Icon-only buttons (the AI quick-log FAB, scanner controls, profile switcher, close buttons) are the priority — a VoiceOver user hears "button" with no name. Audit `home/widgets/ai_quick_log_fab.dart`, scanner overlays, and modal close buttons first.

**Tap targets:** good news — `iconSize < 44` declarations: **0**, and `AppA11y.minTapTarget = 48` exists. No systemic small-target problem found. Spot-check the 21 raw `GestureDetector`/`InkWell` in screens for wrapped-small-child cases.

---

## Severity 2 — Motion / reduced-motion (mostly healthy)

Better than the prose audit implies. Of 53 files using `.animate()`, **46 also guard `reducedMotion`** via `MedAiA11y`. Seven files animate with **no reduced-motion guard**:

- `home/home_tab.dart` ← daily UI, highest traffic — fix first
- `stats/widgets/weekly_wellness_ring.dart` (rotate+scale, unguarded)
- `stats/widgets/predictive_insight_card.dart`
- `scan/scanner_hub_screen.dart`
- `family/profile_pin_screen.dart`
- `admin/growth_dashboard_screen.dart` (internal — low priority)
- `loading/loading_screen.dart` (one-time — low priority)

44 manual `AnimationController`s — verify each has `dispose()` (not scanned line-by-line here).

---

## Severity 3 — State coverage & polish

- Empty-state references: 251, loading/`CircularProgressIndicator`: 44, error handling: 35 — coverage exists but is **uneven**. The premium audit calls this out; worth a per-screen matrix (does every list/async screen have all three of empty/loading/error?).
- deprecated `withOpacity()`: **0** — already migrated to `withValues`.

---

## Recommended order of attack

1. **RTL directional fix + `Colors.*`/hex in top-10 files** — correctness + biggest visible consistency win, mostly mechanical.
2. **Semantic labels on icon-only buttons** — accessibility compliance, ~30 real spots.
3. **l10n extraction** for settings/medicine/home literal strings — unblocks the 7 shipped locales.
4. **7 unguarded animations** — start with `home_tab.dart`.
5. **Spacing/font literals → tokens** — batch cosmetic cleanup by screen family, lowest risk.

## How to reproduce
```
grep -rnE "EdgeInsets\.(all|symmetric|only|fromLTRB)\([^)]*[0-9]" lib/screens | wc -l   # 572
grep -rn  "Color(0x" lib/screens | wc -l                                                # 212
grep -rn  "EdgeInsetsDirectional\|AlignmentDirectional" lib/screens | wc -l             # 0
grep -rn  "semanticLabel:" lib/screens | wc -l                                          # 11
```
