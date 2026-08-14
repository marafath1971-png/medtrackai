# Photo sourcing brief

Replaces the generic medical stock currently bundled in `assets/photos/`.

## Licensing rule (non-negotiable for Play Store)

Download **only** from these, all free for commercial use with no attribution required:

- <https://unsplash.com> — best for warm lifestyle shots
- <https://pexels.com> — good for people and home scenes
- <https://pixabay.com> — fallback

**Never** save images from Google Images or Pinterest. Those are search engines; the
images belong to photographers, agencies, and brands. Google Play requires you to own or
be licensed for all app content, and an IP complaint results in **suspension**, not a
warning. This risk is higher for a health app, which also gets a stricter policy review.

Avoid, even from the allowed sites:
- recognisable faces in a clinical/patient context (privacy + model-release issues)
- real hospital names, staff badges, brand logos, readable medicine brand names
- surgery, needles, blood, hospital beds — clinically intimidating and off-brand

## Visual direction

The app's design language is cream + lime (`#fbfbfc` ground, `#b9ea6e→#8fd14f` hero, pastel
mint/sky/sun/pink). Photos should sit next to that without fighting it:

- bright, soft, natural daylight — not clinical fluorescent
- warm neutrals, wood, linen, plants, home kitchens and bedside tables
- calm and everyday, not "hospital"
- shallow depth of field, generous empty space for text overlay
- **landscape** for heroes, square-ish for gallery tiles

## What each slot needs

Slot names map to `lib/core/constants/premium_photos.dart`.

| Slot | File | Used by | What it should show | Search terms |
|---|---|---|---|---|
| `welcome` | `ob_welcome.jpg` | onboarding hero | calm morning routine, sunlit table, glass of water | "morning light table", "calm morning routine" |
| `know` | `ob_know.jpg` | "know your medicine" | hands holding a pill bottle, reading a label, soft focus | "reading medicine label", "hands pill bottle" |
| `family` | `ob_family.jpg` | family/caregiver step | **two generations at home together, warm, no clinician** | "adult child elderly parent home", "family tea together" |
| `thrive` | `ob_thrive.jpg` | thriving/outcome step | someone active and well — walking, gardening, cooking | "senior walking park", "woman gardening morning" |
| `routine` | `ob_routine.jpg` | routine-building step | pill organiser on a bedside table, morning habit | "weekly pill organizer", "bedside table morning" |
| `community` | `ob_community.jpg` | community/social proof | small group of friends, relaxed, outdoors | "friends laughing outdoors", "community group" |
| `scan` | `ob_scan.jpg` | scan intro | **phone camera over a pill or box on a table** | "phone scanning object", "smartphone camera table" |
| `scanHow` | `ob_scan_how.jpg` | "how it works" | close-up hand holding phone over medicine packet | "hand holding phone close up", "phone macro object" |
| `scanFeature` | `ob_scan_feature.jpg` | scan hero | **pill blister + phone, clean desk, bright** — not surgery | "medicine box phone desk", "flat lay medication phone" |
| `rank` | `ob_rank.jpg` | plan/rank reveal | aspirational calm — sunrise, open window, journal | "sunrise window calm", "journal morning light" |
| `finish` | `ob_finish.jpg` | onboarding finish | quiet win — someone smiling at home, relaxed | "relaxed woman home smiling", "happy morning home" |
| `homeMorning` | `home_morning.jpg` | home hope strip | soft morning still life, mug and light | "morning coffee light", "sunlit kitchen still life" |
| `gallery[0..7]` | `gallery_01..08.jpg` | onboarding mosaic | 8 small tiles: hands, water glass, plants, walking shoes, fruit, sunlight, notebook, mug | vary — these are texture, keep them abstract and warm |

### Current photos that are actively wrong

Fix these first — they are the reason the imagery feels off:

1. **`ob_scan_feature.jpg`** — a surgical team looking down at the viewer from an operating
   theatre. Intimidating and unrelated to scanning.
2. **`ob_family.jpg`** — a clinician giving an **injection**, with a visible hospital badge
   and staff name tag. Not family caregiving, and carries real IP/privacy exposure.
3. **`ob_scan.jpg`** — a plastic anatomical brain model. Nothing to do with scanning a pill.

## Specs

- Landscape heroes: **1600×1200** or wider, gallery tiles ~**800×800**
- Save as `.jpg`, quality ~82 — the current set totals 5.4 MB, keep it near that
- Keep the **exact existing filenames** and drop them into `assets/photos/`. Nothing else
  needs to change: `premium_photos.dart` already maps one unique file per role, and no
  file is reused across screens.

To resize/compress after downloading:

```bash
sips -Z 1600 ~/Downloads/photo.jpg --out assets/photos/ob_scan.jpg
```

## After replacing

```bash
flutter clean && flutter run
```

Check the app size did not balloon, and confirm each onboarding step visually.
