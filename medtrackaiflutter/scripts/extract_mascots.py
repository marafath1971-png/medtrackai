#!/usr/bin/env python3
"""
Extract 30 ghost-mascot stickers from a 6x5 sheet — FACE-PRESERVING.

The sheet places each sticker on a grey/white checkerboard "transparent"
placeholder. Naive colour-keying (remove all light desaturated pixels) also
erased the ghost's OWN white body, eye-whites and highlights — leaving faceless
blobs. This version removes the checkerboard by RECONSTRUCTING it (see remove_bg):

  1. Detect the checker's distinctive mid-grey squares (luminance ~210).
  2. Solve for the checker phase, then rebuild the ideal grey/white grid.
  3. Foreground = any pixel disagreeing with the colour its cell should be.
     A white ghost body over a would-be-GREY cell disagrees -> kept. That
     captures the whole ghost, including soft outline-less bottoms that a flood
     fill or outline trace would leak through.
  4. Force mid-grey fully transparent (it is only ever checker), keep the
     largest blob, fill holes, feather 1px, then tight-crop the drop shadow.

Usage:
    python3 scripts/extract_mascots.py "images/Generated Image July 12, 2026 - 11_50PM.jpg"
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


# The checkerboard placeholder alternates a distinctive MID-GREY (luminance
# ~210) and white on a regular grid (~56px squares at full res). We reconstruct
# that ideal checker and subtract it: wherever a pixel disagrees with the colour
# its checker cell *should* be, it's foreground. Crucially, the white ghost body
# sitting over a cell that should be GREY disagrees -> detected as foreground.
# That captures the ghost whole, including soft outline-less bottoms that a
# flood fill or outline trace would leak through.
GREY_LO, GREY_HI, GREY_SAT = 190, 228, 16
WHITE_LO = 232
CHECKER_SQUARE_PX = 56.0
REF_CELL_W = 5056 / 6


def _disk(r):
    r = int(r)
    if r < 1:
        return np.ones((1, 1), bool)
    y, x = np.ogrid[-r:r + 1, -r:r + 1]
    return (x * x + y * y) <= r * r


def remove_bg(cell):
    """Return RGBA with the checkerboard removed, keeping the whole ghost."""
    rgb = np.array(cell.convert("RGB"))
    H, W = rgb.shape[:2]
    lum = rgb.mean(2)
    sat = rgb.max(2).astype(int) - rgb.min(2)
    grey = (lum > GREY_LO) & (lum < GREY_HI) & (sat < GREY_SAT)
    whitish = (lum > WHITE_LO) & (sat < GREY_SAT)
    sq = max(6.0, CHECKER_SQUARE_PX * (W / REF_CELL_W))

    # Find the checker phase that best lands grey pixels on the "even" cells.
    ii = np.arange(H)[:, None]
    jj = np.arange(W)[None, :]
    best_score, best = -1e18, (0, 0)
    step = max(2, int(sq / 12))
    for oy in range(0, int(sq), step):
        for ox in range(0, int(sq), step):
            parity = (((ii + oy) // sq).astype(int) + ((jj + ox) // sq).astype(int)) & 1
            score = grey[parity == 0].sum() - grey[parity == 1].sum()
            if score > best_score:
                best_score, best = score, (oy, ox)
    oy, ox = best
    expected_grey = ((((ii + oy) // sq).astype(int) + ((jj + ox) // sq).astype(int)) & 1) == 0

    # Background = pixel matches the colour its cell should be. Raw foreground =
    # everything else: colour, dark outline, AND white body over would-be-grey
    # cells. Checker squares are never in raw_fg, so they can't survive as halo.
    bg = (expected_grey & grey) | (~expected_grey & whitish)
    raw_fg = ~bg

    # Build a solid silhouette to recover the ambiguous white-over-white-cell
    # pixels at the ghost's soft edges, then erode away the closing's outward
    # bleed. Union back the raw foreground so thin real parts (stems, arms over
    # grey cells) are never trimmed, and fill enclosed holes.
    sil = ndimage.binary_closing(raw_fg, structure=_disk(sq * 0.8))
    sil = ndimage.binary_fill_holes(sil)
    sil = ndimage.binary_opening(sil, structure=_disk(sq * 0.4))   # drop specks
    core = ndimage.binary_erosion(sil, _disk(sq * 0.8))            # undo bleed
    keep = core | (raw_fg & sil)
    keep = ndimage.binary_fill_holes(keep)

    # Mid-grey is ONLY ever the checker — never the ghost. Force it out, which
    # also snaps any misaligned edge-checker frame into disconnected white specks
    # that the largest-blob + speckle passes below then drop.
    keep &= ~grey
    keep = ndimage.binary_opening(keep, structure=_disk(sq * 0.35))
    keep = _largest_component(keep)
    keep = ndimage.binary_fill_holes(keep)
    keep = ndimage.binary_closing(keep, structure=_disk(2))

    alpha = np.where(keep, 255, 0).astype(np.uint8)
    return np.dstack([rgb, alpha])


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
    default = "images/Generated Image July 12, 2026 - 11_50PM.jpg"
    main(argv[0] if argv else default, debug=debug)
