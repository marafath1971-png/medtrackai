---
name: medai-flutter-design
description: MedAI Flutter UI and motion standards — Emil Kowalski + Apple HIG adapted for this app. Use when building or reviewing screens, animations, gestures, typography, glass surfaces, or component polish in medtrackaiflutter.
---

# MedAI Flutter Design Engineering

Apply [emil-design-eng](../emil-design-eng/SKILL.md) and [apple-design](../apple-design/SKILL.md) to this Flutter codebase.

## App context

- **Product:** MedAI — intelligent medication tracker (dose timeline, AI scan, analytics, family circle)
- **Stack:** Flutter, Provider, go_router, flutter_animate, spring physics in `AnimatedPressable`
- **Aesthetic:** Sage `#4A9E86` + lime hero `#B4E869` on cream `#FFF8F2`; glass floating nav; Apple HIG settings
- **Font:** Outfit via `AppTypography`

## Flutter mapping (CSS → Dart)

| Web (Emil) | Flutter (MedAI) |
| --- | --- |
| `transform: scale(0.97)` on `:active` | `AnimatedPressable(scaleFactor: 0.97)` — already default |
| `ease-out` custom cubic-bezier | `AppCurves.emilOut` / `AppCurves.expressive` |
| `prefers-reduced-motion` | `MedAiA11y.reducedMotion(context)` + `MedAiA11y.motion()` |
| Spring (damping 1.0, response 0.4) | `SpringDescription(mass: 1, stiffness: 700, damping: 35)` in `AnimatedPressable` |
| `transform-origin` on popover | `Alignment` on `ScaleTransition` / `Transform.scale(alignment: ...)` |
| Never `scale(0)` entry | `scaleXY(begin: 0.95)` + `fadeIn` — never below 0.9 |
| Tab switch 100+/day | **No animation** or ≤200ms fade only — use `_fadeTabPage` in router |
| Modal/sheet enter | 200–350ms `AppCurves.emilOut`; exit **faster** (150–200ms) |
| Stagger 30–80ms | `delay: (index * 50).ms` in `entranceCard(index)` |
| GPU-only | Animate `Transform` + `Opacity` only — never `width`/`height`/`padding` |
| Glass toolbar | `BackdropFilter` + semi-transparent `L.card` in `app_shell.dart` |
| Haptic on press | `HapticEngine` — same frame as visual feedback |

## Token source of truth

- **Durations:** `lib/theme/app_tokens.dart` → `AppDurations`
- **Curves:** `lib/theme/app_tokens.dart` → `AppCurves`
- **Motion presets:** `MotionPresets` extension on `Widget` in same file
- **Press feedback:** `lib/widgets/common/animated_pressable.dart`
- **A11y motion:** `lib/theme/med_ai_ui.dart` → `MedAiA11y`

## Duration budget (UI)

| Element | Duration |
| --- | --- |
| Button press | 100–160ms (spring) |
| Tab fade | 150–200ms |
| Tooltip / small popover | 125–200ms |
| Modal / settings sheet | 250–350ms enter, 150–200ms exit |
| Celebration / onboarding | up to 500ms — rare only |

## Review checklist (Flutter)

When reviewing UI in this repo, flag:

- `Curves.easeIn` or `easeInOut` on **enter/exit** UI (use `AppCurves.emilOut`)
- `ElasticOutCurve` on frequent interactions (tabs, list rows, settings rows)
- `scaleXY(begin: < 0.9)` or `scale(0)` entrances
- `AnimatedSwitcher` / route transitions >300ms on tabs
- Animating layout properties (`AnimatedContainer` on width/height for lists)
- Missing `MedAiA11y.reducedMotion` guard on movement
- Modal exit same duration as enter (exit should be snappier)
- `flutter_animate` on every list item without stagger cap

## Screen-specific notes

- **Home / Dashboard:** cream/lime surfaces; hero progress uses `easeOutCubic` — good
- **Settings modal:** bottom sheet 90% height; tab content swap via `KeyedSubtree` — no nested Navigator
- **App shell nav:** glass island; center Scan FAB; swipe tabs — keep tab change instant-feeling
- **Dose rows:** `AnimatedPressable` + haptic on take — keep press on pointer-down

## Related skills

- [emil-design-eng](../emil-design-eng/SKILL.md) — core philosophy
- [apple-design](../apple-design/SKILL.md) — springs, gestures, materials
- [review-animations](../review-animations/SKILL.md) — strict motion review
- [animation-vocabulary](../animation-vocabulary/SKILL.md) — naming effects
