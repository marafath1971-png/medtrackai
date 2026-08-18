#!/usr/bin/env python3
"""Isolate the single mascot figure on each sticker, discarding sheet bleed.

strip_mascot_backdrop.py removed the flat green panel, but two things survived:

* A darker, desaturated green rim — roughly RGB(48,120,96) — left where the
  panel met its own border. The first filter required g-r > 55; on that rim the
  difference is only 72-96, so it stayed.
* Fragments of the *neighbouring* stickers on the source sheet. The crop
  boxes overlap slightly, so 28 of 30 files carry slivers of another character
  along an edge. Those are the "extra elements above and to the side".

Widening the colour filter cannot fix the second problem — the fragments are
the same colours as the mascot itself. So this works structurally instead:
flood-fill from the largest connected blob of opaque pixels and keep only that
component. Anything not touching the main figure is sheet bleed by definition.

Run after strip_mascot_backdrop.py, or on the originals (it clears the rim too).

Usage:
    python3 scripts/isolate_mascot.py            # rewrite in place
    python3 scripts/isolate_mascot.py --dry-run  # report only
"""

import glob
import os
import sys
from collections import deque

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from strip_mascot_backdrop import load_rgba, save_rgba  # noqa: E402

# Alpha at or below this is treated as empty when tracing components.
ALPHA_FLOOR = 40

# Outermost band cleared as sheet bleed. The stickers are centred with margin,
# so no real figure reaches this close to the canvas edge.
EDGE_FRAME = 12


def is_rim_green(r, g, b):
    """The darker panel border the first pass missed.

    Deliberately still narrow: the mascots carry a mint pill and green cross
    that must survive, so this targets the desaturated rim tone only.
    """
    return 60 < g < 170 and 25 < (g - r) < 60 and (g - b) > 15


def largest_component(rows, w, h):
    """Label opaque pixels and return the set belonging to the biggest blob.

    Iterative flood fill — the recursive form overflows the stack on a 512x400
    figure.
    """
    seen = bytearray(w * h)
    best = set()

    for sy in range(h):
        for sx in range(w):
            idx = sy * w + sx
            if seen[idx] or rows[sy][sx * 4 + 3] <= ALPHA_FLOOR:
                continue

            comp = []
            q = deque([(sx, sy)])
            seen[idx] = 1
            while q:
                x, y = q.popleft()
                comp.append((x, y))
                for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                    if 0 <= nx < w and 0 <= ny < h:
                        ni = ny * w + nx
                        if not seen[ni] and rows[ny][nx * 4 + 3] > ALPHA_FLOOR:
                            seen[ni] = 1
                            q.append((nx, ny))

            if len(comp) > len(best):
                best = set(comp)

    return best


def process(path, dry_run=False):
    w, h, rows = load_rgba(path)

    # 1. Clear the leftover rim so it cannot bridge the figure to a fragment.
    rim = 0
    for y in range(h):
        row = rows[y]
        for x in range(w):
            i = x * 4
            if row[i + 3] <= ALPHA_FLOOR:
                continue
            if is_rim_green(row[i], row[i + 1], row[i + 2]):
                row[i] = row[i + 1] = row[i + 2] = row[i + 3] = 0
                rim += 1

    # 2. Clear a 12px frame around the canvas.
    #
    # The crop boxes on the source sheet overlap, so each sticker carries a
    # sliver of its neighbours along an edge — on love_pill, 270px of a dark
    # navy outline (21,17,41) down the left side. Those slivers *touch* the
    # mascot, so a flood fill alone keeps them. A real figure is centred with
    # margin, so anything in the outermost frame is bleed.
    frame = 0
    for y in range(h):
        row = rows[y]
        for x in range(w):
            if x < EDGE_FRAME or x >= w - EDGE_FRAME or \
               y < EDGE_FRAME or y >= h - EDGE_FRAME:
                i = x * 4
                if row[i + 3] > 0:
                    row[i] = row[i + 1] = row[i + 2] = row[i + 3] = 0
                    frame += 1

    # 3. Keep only the largest connected figure.
    keep = largest_component(rows, w, h)
    stripped = 0
    for y in range(h):
        row = rows[y]
        for x in range(w):
            i = x * 4
            if row[i + 3] > 0 and (x, y) not in keep:
                row[i] = row[i + 1] = row[i + 2] = row[i + 3] = 0
                stripped += 1

    if not dry_run:
        save_rgba(path, w, h, rows)
    return rim, stripped + frame, len(keep)


def main():
    dry = '--dry-run' in sys.argv
    files = sorted(glob.glob('assets/mascots/*.png'))
    if not files:
        print('no mascots found — run from the flutter project root')
        return 1

    print(f'{"file":<32}{"rim":>7}{"bleed":>9}{"kept":>9}')
    for f in files:
        rim, stripped, kept = process(f, dry_run=dry)
        print(f'{os.path.basename(f):<32}{rim:>7}{stripped:>9}{kept:>9}')
    if dry:
        print('\n(dry run — nothing written)')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
