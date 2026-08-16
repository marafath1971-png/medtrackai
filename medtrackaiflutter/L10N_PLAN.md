# Localization plan

## Where things stand

The app ships 7 locales — `en`, `es`, `ar`, `he`, `ja`, `ko`, `ms`, including two RTL —
with **176 keys**, all translated. The infrastructure works.

The gap is coverage: **~1,552 distinct user-facing strings are still hardcoded** in
`lib/screens` and `lib/widgets`. So a user switching to Japanese or Arabic still sees a
mostly-English app.

Check progress at any time:

```bash
dart tool/l10n_status.dart               # per-locale completion
dart tool/l10n_status.dart --untranslated # keys still showing English
dart tool/l10n_status.dart --hardcoded    # strings not yet extracted, by frequency
```

## Why this is not a quick job

The 169 pre-existing keys cover onboarding, reports, and clinical modes — **not** the
daily-use screens. Wiring up the ~98 unused keys would not change what a user actually
sees most, because home, medicine detail, and alarms had no keys at all.

Every string on those screens needs a **new** key, and each new key needs translating
into 6 more languages. At ~1,550 strings this is a translation project measured in weeks,
not an afternoon of refactoring.

## Done so far

`home_tab.dart` — the most-viewed screen — is extracted and wired:

| Key | English |
|---|---|
| `homeNextDose` | Next dose |
| `homeSchedule` | Schedule |
| `homeDosesLeft` | Doses left |
| `homeYourMedicines` | Your medicines |
| `homeAddMeds` | Add meds |
| `homeAllClear` | All clear |
| `homeFirstPending` | First pending |

The other 6 locales carry these keys with **English placeholder values** so the app never
crashes or shows a blank string. `tool/l10n_status.dart --untranslated` lists exactly
which ones still need real translations.

`test/widgets/l10n_home_keys_test.dart` asserts all 7 keys resolve non-empty in every
shipped locale, so a missing or malformed ARB entry fails CI rather than shipping.

## Suggested order

Work by user impact, not file size:

1. **home_tab** — done
2. **medicine_detail_screen** — second most-visited
3. **alarms_tab** — reminders are the core loop
4. **add_medication_screen** — first-run critical path
5. **scanner_hub / scan results**
6. **family_tab and caregiver flows**
7. **settings**
8. Everything else

## Conventions

- Key prefix = screen: `homeNextDose`, `medDetailRefill`, `alarmsActiveCount`.
- Add an `@key` block with a `description` explaining *where* the string appears —
  translators need the context to choose register and length.
- **Keep punctuation out of the value.** A Latin comma is wrong in `ja` and `ar`; let the
  layout add separators. (This already bit `home_header.dart` — see commit `15c6374`.)
- Use placeholders rather than concatenation, so word order can change:
  `"hiUser": "Hi, {name} 👋"`.
- After editing any ARB: `flutter gen-l10n`, then `flutter analyze`.

## Before shipping more locales

Decide whether to ship partially-translated languages at all. A confidently English app
often reads better than one that switches language mid-screen. If v1 goes English-only,
restrict the Play listing to English and re-enable locales as each reaches full coverage —
`tool/l10n_status.dart` gives the number to gate on.
