import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:medai/core/utils/scan_image_compressor.dart';

/// Scan images are base64-encoded into the AI request body, so the captured
/// image size directly sets the upload size. scanner_hub_screen sent raw
/// captures — including a lossless PNG rendered at pixelRatio 2.0 — and every
/// photo scan on a real device failed:
///
///   TimeoutException after 0:00:30 — Retrying in 1000ms (attempt 1/3)
///   TimeoutException after 0:00:30 — Retrying in 2000ms (attempt 2/3)
///   TimeoutException after 0:00:30 — Retrying in 4000ms (attempt 3/3)
///
/// ~97 seconds and three full uploads before giving up with nothing to show,
/// while text search on the same build and session returned in seconds. The
/// sibling scanners (pill_identifier, supplement_interaction) compressed and
/// worked, which is what isolated the difference.
void main() {
  group('compression bounds', () {
    test('long edge stays small enough to upload on mobile data', () {
      expect(ScanImageCompressor.maxDimension, lessThanOrEqualTo(1600),
          reason: 'a full-resolution phone photo is the payload that timed '
              'out at 30 seconds');
    });

    test('resolution stays high enough to read a medicine label', () {
      // The whole feature is OCR of dosage text on packaging. Shrinking the
      // image until upload is fast but the label is illegible trades a
      // timeout for a wrong answer, which is worse in a medical app.
      expect(ScanImageCompressor.maxDimension, greaterThanOrEqualTo(1000));
      expect(ScanImageCompressor.quality, greaterThanOrEqualTo(80));
    });
  });

  group('failure behaviour', () {
    test('an unreadable file falls back to the original', () async {
      // Compression runs on the scan path; if it throws, the scan should
      // still attempt to send rather than dying before the request.
      final missing = File('/nonexistent/never_written.jpg');

      final out = await ScanImageCompressor.compress(missing);

      expect(out.path, missing.path);
    });
  });

  test('every scanner compresses before handing an image to Gemini', () {
    // The bug was one screen out of three skipping compression, and it was
    // only found by testing on a physical device. This is the cheap guard:
    // any screen that sends an image must route it through the compressor.
    final offenders = <String>[];

    for (final entity in Directory('lib/screens/scan').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final src = entity.readAsStringSync();

      final sendsImage = src.contains('image: ') &&
          (src.contains('GeminiService.') || src.contains('analyzeProductInsight'));
      if (!sendsImage) continue;

      // Match the call, not the name: a passing mention in a comment must not
      // satisfy this guard (an earlier version of this test was fooled by
      // exactly that and reported a reverted fix as still present).
      final compresses = src.contains('ScanImageCompressor.compress(') ||
          src.contains('FlutterImageCompress.compressAndGetFile(');
      if (!compresses) offenders.add(entity.path);
    }

    expect(offenders, isEmpty,
        reason: 'these screens upload an image without downscaling it, which '
            'is what made photo scan time out three times and fail');
  });
}
