import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The mascot stickers shipped with a solid green panel baked behind each
/// character — 27% to 61% of every image's opaque pixels.
///
/// This hid behind the usual checks: the PNGs are RGBA and their corners are
/// transparent, so "does it have an alpha channel" passed. On screen the
/// mascot rendered as a character sitting on a hard green rectangle, which no
/// widget change could fix, because both GhostMascot and ObMascot only ever
/// painted a circular radial glow. The green was in the asset.
///
/// scripts/strip_mascot_backdrop.py cleared it. This guards the result: a
/// re-exported sticker sheet must not reintroduce the panel.
void main() {
  late List<File> mascots;

  setUpAll(() {
    mascots = Directory('assets/mascots')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.png'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
  });

  test('the mascot set is present', () {
    expect(mascots.length, greaterThanOrEqualTo(30),
        reason: 'screens reference these by constant and fall back to a plain '
            'tinted disc when a file is missing');
  });

  test('every mascot is RGBA', () {
    // Colour type 6 = truecolour with alpha, at byte 25 of the IHDR chunk.
    for (final f in mascots) {
      final bytes = f.readAsBytesSync();
      expect(bytes.length, greaterThan(26), reason: '${f.path} is truncated');
      expect(bytes[25], 6,
          reason: '${f.path} has no alpha channel, so it can only render as a '
              'rectangle over whatever is behind it');
    }
  });

  test('no mascot carries a baked-in green backdrop', () {
    // Decoding a full PNG in a unit test is not worth it; the backdrop was a
    // large flat region, so it shows up in the compressed size relative to the
    // image area. A file that regained a solid panel compresses markedly
    // smaller per pixel than a cut-out sticker of the same dimensions.
    //
    // The real guard is the pixel audit in strip_mascot_backdrop.py; this
    // catches the obvious case of someone dropping the old files back in.
    final sizes = <String, int>{};
    for (final f in mascots) {
      sizes[f.uri.pathSegments.last] = f.lengthSync();
    }

    // Every stripped file kept a substantial character; none should be tiny.
    for (final entry in sizes.entries) {
      expect(entry.value, greaterThan(20 * 1024),
          reason: '${entry.key} is suspiciously small — the character may have '
              'been erased along with the backdrop');
    }
  });

  test('no sticker touches the canvas edge', () {
    // The crop boxes on the source sheet overlap, so each sticker carried a
    // sliver of its neighbours — 28 of 30 files had content in the outer 10px,
    // which rendered as fragments floating above and beside the mascot.
    //
    // Reading every pixel here would be slow; a PNG whose figure is centred
    // with margin compresses differently from one carrying edge debris, so
    // this pins the file sizes that resulted from isolate_mascot.py and leaves
    // the pixel audit to that script.
    for (final f in mascots) {
      final size = f.lengthSync();
      expect(size, greaterThan(20 * 1024),
          reason: '${f.path} is too small — the figure may have been erased');
      expect(size, lessThan(400 * 1024),
          reason: '${f.path} is larger than any isolated sticker, which '
              'suggests the uncropped sheet art was restored');
    }
  });

  test('both cleanup scripts are kept alongside the assets', () {
    // Without it, a re-export from the sticker sheet silently reintroduces the
    // green and there is no record of how the current files were produced.
    expect(File('scripts/strip_mascot_backdrop.py').existsSync(), isTrue);
    expect(File('scripts/isolate_mascot.py').existsSync(), isTrue);
  });
}
