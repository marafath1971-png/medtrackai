#!/usr/bin/env python3
"""
Extract 30 ghost-mascot stickers from a 6x5 sheet.

- Removes the grey/white checkerboard "transparent" background -> true alpha.
- Auto-crops each sticker to its tight bounding box (keeps soft drop shadow).
- Exports @1x/@2x/@3x PNGs named by MEANING (see NAMES) into assets/mascots/.

Usage:
    python3 scripts/extract_mascots.py assets/raw/ghost_stickers.png
"""
import sys, os
from PIL import Image
import numpy as np

# 6 columns x 5 rows, row-major. VERIFIED cell-by-cell against a grid-labeled
# render of the sheet. Each maps to the app feature it serves — see
# MedAiAssets.mascotFor(). Keep in sync with the constants in med_ai_assets.dart.
NAMES = [
    # row 0
    "happy_pill", "wink_pill", "cheer_stars", "sleepy_pill", "determined_pill", "love_pill",
    # row 1
    "doctor", "shield_guard", "search_time", "phone_love", "megaphone_alert", "hug_heart",
    # row 2
    "meds_bottle", "pill_water", "blister_pack", "calendar_worry", "alarm_panic", "success_check",
    # row 3
    "dashboard_stats", "fitness_band", "ai_chat", "family_cry", "caregiver_elder", "buddy_wave",
    # row 4
    "home_heart", "trophy_win", "reward_coins", "shopping_refill", "cool_shades", "meditate_calm",
]
COLS, ROWS = 6, 5

def load_rgba(path):
    im = Image.open(path).convert("RGBA")
    return im

def checker_to_alpha(cell):
    """Make the grey/white checkerboard fully transparent.
    The checkerboard is near-grey (R~=G~=B) and light. Real art has color OR
    dark outlines, so we key out light, low-saturation pixels."""
    a = np.array(cell).astype(np.int16)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    mx = np.maximum(np.maximum(r, g), b)
    mn = np.minimum(np.minimum(r, g), b)
    sat = mx - mn                      # low for grey/white
    light = mx                          # high for the checker squares
    # checker = light AND desaturated. Keep everything else.
    is_bg = (sat < 18) & (light > 170)
    out = a.copy()
    out[..., 3] = np.where(is_bg, 0, 255)
    return out.astype(np.uint8), is_bg

def largest_blob_only(arr):
    """Keep only the dominant connected component of the alpha mask, dropping
    stray slivers of a neighbor sticker's drop-shadow caught by the grid slice.
    Dependency-free: iterative flood fill over a downsampled mask for speed,
    then map the kept region back to full res."""
    alpha = arr[..., 3]
    mask = alpha > 24
    if not mask.any():
        return arr
    H, W = mask.shape
    # Downsample the mask ~4x for a fast component search (edges don't need
    # full precision to pick the biggest blob).
    step = max(1, min(H, W) // 256)
    sm = mask[::step, ::step]
    sh, sw = sm.shape
    seen = np.zeros_like(sm, dtype=bool)
    best_size, best_seed = 0, None
    from collections import deque
    for sy in range(sh):
        for sx in range(sw):
            if sm[sy, sx] and not seen[sy, sx]:
                q = deque([(sy, sx)])
                seen[sy, sx] = True
                comp = []
                while q:
                    y, x = q.popleft()
                    comp.append((y, x))
                    for dy, dx in ((1,0),(-1,0),(0,1),(0,-1)):
                        ny, nx = y+dy, x+dx
                        if 0 <= ny < sh and 0 <= nx < sw and sm[ny, nx] and not seen[ny, nx]:
                            seen[ny, nx] = True
                            q.append((ny, nx))
                if len(comp) > best_size:
                    best_size, best_seed = len(comp), comp[0]
    if best_seed is None:
        return arr
    # Flood the FULL-res mask from a seed inside the biggest blob.
    seedy, seedx = best_seed[0]*step, best_seed[1]*step
    keep = np.zeros_like(mask)
    q = deque([(seedy, seedx)])
    keep[seedy, seedx] = True
    while q:
        y, x = q.popleft()
        for dy, dx in ((1,0),(-1,0),(0,1),(0,-1)):
            ny, nx = y+dy, x+dx
            if 0 <= ny < H and 0 <= nx < W and mask[ny, nx] and not keep[ny, nx]:
                keep[ny, nx] = True
                q.append((ny, nx))
    out = arr.copy()
    out[..., 3] = np.where(keep, arr[..., 3], 0)
    return out


def tight_crop(arr, pad=6):
    alpha = arr[..., 3]
    ys, xs = np.where(alpha > 8)
    if len(xs) == 0:
        return None
    x0, x1 = max(xs.min() - pad, 0), min(xs.max() + pad + 1, arr.shape[1])
    y0, y1 = max(ys.min() - pad, 0), min(ys.max() + pad + 1, arr.shape[0])
    return arr[y0:y1, x0:x1]

def main(src):
    if not os.path.exists(src):
        print(f"ERROR: source not found: {src}")
        print('Try: python3 scripts/extract_mascots.py "images/Generated Image July 12, 2026 - 11_50PM.jpg"')
        sys.exit(1)
    im = load_rgba(src)
    W, H = im.size
    cw, ch = W / COLS, H / ROWS
    out_dir = "assets/mascots"
    os.makedirs(out_dir, exist_ok=True)
    made = []
    for r in range(ROWS):
        for c in range(COLS):
            idx = r * COLS + c
            name = NAMES[idx]
            box = (int(c*cw), int(r*ch), int((c+1)*cw), int((r+1)*ch))
            cell = im.crop(box)
            keyed, _ = checker_to_alpha(cell)
            keyed = largest_blob_only(keyed)
            cropped = tight_crop(keyed)
            if cropped is None:
                print(f"  ! {name}: empty after keying (check bg thresholds)")
                continue
            base = Image.fromarray(cropped, "RGBA")
            # Cap master to a sane UI size (longest edge 512px) to keep the
            # bundle light — these render at 40-160px in-app.
            longest = max(base.width, base.height)
            if longest > 512:
                s = 512 / longest
                base = base.resize((int(base.width*s), int(base.height*s)), Image.LANCZOS)
            # Single clean master PNG per mascot; Image.asset scales at runtime.
            fn = f"mascot_{name}.png"
            base.save(os.path.join(out_dir, fn))
            made.append(name)
    print(f"Extracted {len(made)}/30 mascots -> {out_dir}/")
    print("Names:", ", ".join(made))


if __name__ == "__main__":
    default = "images/Generated Image July 12, 2026 - 11_50PM.jpg"
    src = sys.argv[1] if len(sys.argv) > 1 else default
    main(src)
