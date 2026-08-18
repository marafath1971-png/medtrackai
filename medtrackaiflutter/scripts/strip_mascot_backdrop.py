#!/usr/bin/env python3
"""Remove the baked-in green backdrop from the mascot stickers.

Every file in assets/mascots/ carries a solid green panel behind the character
(27-61% of each image's opaque pixels). The PNGs are RGBA and their *corners*
are transparent, so the usual "does it have an alpha channel" check passes and
the problem only shows on screen: the mascot renders as a character sitting on
a hard green rectangle, which no widget change can fix because the green is
part of the image.

The backdrop is a narrow, highly saturated green — roughly RGB(12-20,150-175,
44-64) — while the ghost body is near-white and its props are blue, pink and
yellow. This clears pixels matching that green and feathers the boundary so the
edge does not alias.

Pure stdlib: PIL on this machine is an x86_64 build and cannot load on arm64.

Usage:
    python3 scripts/strip_mascot_backdrop.py            # rewrite in place
    python3 scripts/strip_mascot_backdrop.py --dry-run  # report only
"""

import glob
import os
import struct
import sys
import zlib


def _unfilter(raw, w, h):
    stride = w * 4
    rows = []
    prev = bytearray(stride)
    pos = 0
    for _ in range(h):
        ft = raw[pos]
        pos += 1
        line = bytearray(raw[pos:pos + stride])
        pos += stride
        if ft == 1:
            for i in range(4, stride):
                line[i] = (line[i] + line[i - 4]) & 255
        elif ft == 2:
            for i in range(stride):
                line[i] = (line[i] + prev[i]) & 255
        elif ft == 3:
            for i in range(stride):
                a = line[i - 4] if i >= 4 else 0
                line[i] = (line[i] + ((a + prev[i]) >> 1)) & 255
        elif ft == 4:
            for i in range(stride):
                a = line[i - 4] if i >= 4 else 0
                b = prev[i]
                c = prev[i - 4] if i >= 4 else 0
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pr = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                line[i] = (line[i] + pr) & 255
        rows.append(line)
        prev = line
    return rows


def load_rgba(path):
    data = open(path, 'rb').read()
    pos, idat, w, h, ct = 8, b'', 0, 0, None
    while pos < len(data):
        ln = struct.unpack('>I', data[pos:pos + 4])[0]
        typ = data[pos + 4:pos + 8]
        if typ == b'IHDR':
            w, h = struct.unpack('>II', data[pos + 8:pos + 16])
            ct = data[pos + 8 + 9]
        elif typ == b'IDAT':
            idat += data[pos + 8:pos + 8 + ln]
        pos += 12 + ln
    if ct != 6:
        raise ValueError(f'{path}: expected RGBA (colour type 6), got {ct}')
    return w, h, _unfilter(zlib.decompress(idat), w, h)


def save_rgba(path, w, h, rows):
    raw = b''.join(b'\x00' + bytes(r) for r in rows)

    def chunk(tag, payload):
        return (struct.pack('>I', len(payload)) + tag + payload
                + struct.pack('>I', zlib.crc32(tag + payload) & 0xFFFFFFFF))

    png = (b'\x89PNG\r\n\x1a\n'
           + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0))
           + chunk(b'IDAT', zlib.compress(raw, 9))
           + chunk(b'IEND', b''))
    open(path, 'wb').write(png)


def is_backdrop_green(r, g, b):
    """The panel colour, deliberately narrow.

    The ghost body is near-white, and props are blue/pink/yellow, so a tight
    band around the sampled backdrop clears it without touching the character.
    A wider rule would eat the green pill and the mint highlights.
    """
    return g > 110 and g - r > 55 and g - b > 45


def process(path, dry_run=False):
    w, h, rows = load_rgba(path)
    opaque = cleared = 0

    for y in range(h):
        row = rows[y]
        for x in range(w):
            i = x * 4
            a = row[i + 3]
            if a < 8:
                continue
            opaque += 1
            r, g, b = row[i], row[i + 1], row[i + 2]
            if is_backdrop_green(r, g, b):
                row[i] = row[i + 1] = row[i + 2] = 0
                row[i + 3] = 0
                cleared += 1

    # Feather: any surviving pixel neighbouring cleared space keeps its colour
    # but loses some alpha, so the cut edge is not a hard staircase.
    for y in range(1, h - 1):
        row = rows[y]
        above, below = rows[y - 1], rows[y + 1]
        for x in range(1, w - 1):
            i = x * 4
            if row[i + 3] < 200:
                continue
            holes = 0
            for nb, ni in ((row, i - 4), (row, i + 4), (above, i), (below, i)):
                if nb[ni + 3] == 0:
                    holes += 1
            if holes:
                row[i + 3] = max(120, row[i + 3] - 34 * holes)

    pct = 100 * cleared // max(opaque, 1)
    if not dry_run:
        save_rgba(path, w, h, rows)
    return pct, cleared


def main():
    dry = '--dry-run' in sys.argv
    files = sorted(glob.glob('assets/mascots/*.png'))
    if not files:
        print('no mascots found — run from the flutter project root')
        return 1

    print(f'{"file":<34} {"green removed":>13}')
    total = 0
    for f in files:
        pct, n = process(f, dry_run=dry)
        total += n
        print(f'{os.path.basename(f):<34} {pct:>12}%')
    print(f'\n{len(files)} files, {total:,} pixels cleared'
          + ('  (dry run — nothing written)' if dry else ''))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
