#!/usr/bin/env python3
"""
Extract 30 ghost-mascot stickers from a 6x5 sheet — FACE-PRESERVING.

The sheet places each sticker on a solid GREEN matte (a green screen). Keying
that is both simpler and more reliable than the old checkerboard: the ghost's
white body, eye-whites and coloured props are never as green as the matte, so a
"greenness" key keeps the whole ghost while dropping only the background. See
remove_bg:

  1. greenness(px) = G - max(R, B): high on the matte, ~0 on the ghost.
  2. Calibrate the matte's greenness from each cell's border (self-tuning to
     whatever green / JPEG colour the export used).
  3. Foreground = any pixel not clearly as green as the matte. This keeps the
     ghost whole, including soft outline-less bottoms.
  4. Clean speckle, keep the largest blob, fill holes, de-spill the green edge
     fringe, feather 1px, then tight-crop.

Usage:
    python3 scripts/extract_mascots.py "images/Generated Image July 15, 2026 - 9_41AM.jpg"
Optional:  --debug  writes a contact sheet of results to .tmp_check/mascots_qc.png

Requires pillow, numpy and scipy. On Apple Silicon install them into a native
arm64 venv (the python.org universal build otherwise pulls x86_64 wheels that
fail to load):
    arch -arm64 python3 -m venv .venv_mascot
    .venv_mascot/bin/pip install pillow numpy scipy
    .venv_mascot/bin/python scripts/extract_mascots.py --debug
"""
import sys, os
from PIL import Image, ImageFilter
import numpy as np
from scipy import ndimage

# 6 columns x 5 rows, row-major. Keep in sync with med_ai_assets.dart.
NAMES = [
    "happy_pill", "wink_pill", "cheer_stars", "sleepy_pill", "determined_pill", "love_pill",
    "doctor", "shield_guard", "search_time", "phone_love", "megaphone_alert", "hug_heart",
    "meds_bottle", "pill_water", "blister_pack", "calendar_worry", "alarm_panic", "success_check",
    "dashboard_stats", "fitness_band", "ai_chat", "family_cry", "caregiver_elder", "buddy_wave",
    "home_heart", "trophy_win", "reward_coins", "shopping_refill", "cool_shades", "meditate_calm",
]
COLS, ROWS = 6, 5
MAX_EDGE = 512  # master longest-edge; app renders 40-160px


# The sheet now places each sticker on a solid GREEN matte (green-screen). A
# green pixel has its green channel well above red and blue; the ghost (white
# body, coloured props, dark outline) never does. We measure the background's
# "greenness" from each cell's border at runtime, so the key self-calibrates to
# whatever green the export used and is robust to JPEG colour drift.
#   greenness(px) = G - max(R, B)
# Background greenness is high and uniform; foreground greenness is near zero or
# negative. Anything clearly below the background level is the ghost.
GREEN_KEY_FRAC = 0.55   # fg = greenness < GREEN_KEY_FRAC * background_greenness
GREEN_MIN_EXCESS = 25   # ...but never treat <this much green excess as background


def _disk(r):
    r = int(r)
    if r < 1:
        return np.ones((1, 1), bool)
    y, x = np.ogrid[-r:r + 1, -r:r + 1]
    return (x * x + y * y) <= r * r


def remove_bg(cell):
    """Return RGBA with the solid-green matte removed, keeping the whole ghost."""
    rgb = np.array(cell.convert("RGB")).astype(np.int16)
    H, W = rgb.shape[:2]
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    greenness = g - np.maximum(r, b)          # high on green matte, ~0 on ghost
    blob = max(3.0, min(H, W) / 24.0)         # morphology scale ~cell size

    # Calibrate the background green from the cell border, which is (almost) all
    # matte. Use a robust median so a stray sticker edge can't skew it.
    band = max(2, int(min(H, W) * 0.03))
    border = np.concatenate([
        greenness[:band, :].ravel(), greenness[-band:, :].ravel(),
        greenness[:, :band].ravel(), greenness[:, -band:].ravel(),
    ])
    bg_green = float(np.median(border))
    thresh = max(GREEN_MIN_EXCESS, bg_green * GREEN_KEY_FRAC)

    # Foreground = anything not clearly as green as the matte.
    raw_fg = greenness < thresh

    # Clean up: drop matte speckle, close the ghost solid, keep the largest blob,
    # fill interior holes (eye-whites keyed as fg stay fg anyway; this repairs any
    # green-tinted interior pixels that fell to background).
    keep = ndimage.binary_opening(raw_fg, structure=_disk(blob * 0.4))
    keep = ndimage.binary_closing(keep, structure=_disk(blob * 0.9))
    keep = _largest_component(keep)
    keep = ndimage.binary_fill_holes(keep)

    # De-spill: green fringe left on the ghost's antialiased edge. Where a kept
    # pixel is still greenish, clamp its green channel down toward max(R,B).
    spill = keep & (greenness > 0)
    if spill.any():
        gv = rgb[..., 1]
        cap = np.maximum(r, b)
        gv[spill] = np.minimum(gv[spill], cap[spill])
        rgb[..., 1] = gv

    alpha = np.where(keep, 255, 0).astype(np.uint8)
    return np.dstack([rgb.astype(np.uint8), alpha])


def _largest_component(mask):
    if not mask.any():
        return mask
    lbl, n = ndimage.label(mask)
    if n <= 1:
        return mask
    sizes = ndimage.sum(np.ones_like(lbl), lbl, index=range(1, n + 1))
    return lbl == (int(np.argmax(sizes)) + 1)


def largest_blob_only(arr):
    alpha = arr[..., 3]
    mask = alpha > 24
    if not mask.any():
        return arr
    lbl, n = ndimage.label(mask)
    if n <= 1:
        return arr
    sizes = ndimage.sum(np.ones_like(lbl), lbl, index=range(1, n + 1))
    biggest = int(np.argmax(sizes)) + 1
    keep = lbl == biggest
    out = arr.copy()
    out[..., 3] = np.where(keep, arr[..., 3], 0)
    return out


def feather(img):
    """1px alpha feather for clean anti-aliased edges."""
    a = img.split()[3].filter(ImageFilter.GaussianBlur(0.6))
    img.putalpha(a)
    return img


def tight_crop(arr, pad=8):
    alpha = arr[..., 3]
    ys, xs = np.where(alpha > 8)
    if len(xs) == 0:
        return None
    x0, x1 = max(xs.min() - pad, 0), min(xs.max() + pad + 1, arr.shape[1])
    y0, y1 = max(ys.min() - pad, 0), min(ys.max() + pad + 1, arr.shape[0])
    return arr[y0:y1, x0:x1]


def process_cell(cell):
    rgba = remove_bg(cell)
    cropped = tight_crop(rgba)
    if cropped is None:
        return None
    im = Image.fromarray(cropped, "RGBA")
    im = feather(im)
    longest = max(im.width, im.height)
    if longest > MAX_EDGE:
        s = MAX_EDGE / longest
        im = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
    return im


def main(src, debug=False):
    if not os.path.exists(src):
        print(f"ERROR: source not found: {src}")
        sys.exit(1)
    im = Image.open(src).convert("RGBA")
    W, H = im.size
    # Inset each cell slightly so the grid lines / neighbour shadows are excluded.
    cw, ch = W / COLS, H / ROWS
    inset_x, inset_y = cw * 0.02, ch * 0.02
    out_dir = "assets/mascots"
    os.makedirs(out_dir, exist_ok=True)
    made, thumbs = [], []
    for r in range(ROWS):
        for c in range(COLS):
            idx = r * COLS + c
            name = NAMES[idx]
            box = (int(c * cw + inset_x), int(r * ch + inset_y),
                   int((c + 1) * cw - inset_x), int((r + 1) * ch - inset_y))
            result = process_cell(im.crop(box))
            if result is None:
                print(f"  ! {name}: empty after keying")
                continue
            result.save(os.path.join(out_dir, f"mascot_{name}.png"))
            made.append(name)
            if debug:
                thumbs.append((name, result.copy()))
    print(f"Extracted {len(made)}/30 mascots -> {out_dir}/")

    if debug and thumbs:
        cell = 180
        cols = 6
        rows = (len(thumbs) + cols - 1) // cols
        sheet = Image.new("RGBA", (cols * cell, rows * cell), (24, 24, 26, 255))
        for i, (name, t) in enumerate(thumbs):
            t2 = t.copy()
            t2.thumbnail((cell - 16, cell - 16), Image.LANCZOS)
            gx = (i % cols) * cell + (cell - t2.width) // 2
            gy = (i // cols) * cell + (cell - t2.height) // 2
            sheet.alpha_composite(t2, (gx, gy))
        os.makedirs(".tmp_check", exist_ok=True)
        sheet.convert("RGB").save(".tmp_check/mascots_qc.png")
        print("QC sheet -> .tmp_check/mascots_qc.png")


if __name__ == "__main__":
    argv = [a for a in sys.argv[1:] if a != "--debug"]
    debug = "--debug" in sys.argv
    default = "images/Generated Image July 15, 2026 - 9_41AM.jpg"
    main(argv[0] if argv else default, debug=debug)
