import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'logger.dart';

/// Downscales a captured image before it is base64-encoded into an AI request.
///
/// A full-resolution phone photo is several megabytes; base64 inflates that by
/// roughly a third, and the scan request carries the whole thing as text. On
/// mobile data that routinely exceeded the 30-second request timeout, and the
/// retry re-uploaded the same payload twice more — about 97 seconds and triple
/// the data before the scan gave up with nothing to show.
///
/// pill_identifier_screen and supplement_interaction_scanner already did this
/// with their own private copies; scanner_hub_screen did not, which is why its
/// scans timed out while the other paths worked.
abstract final class ScanImageCompressor {
  /// Long edge, in pixels. Large enough to read a medicine label, small enough
  /// to upload on a slow connection.
  static const int maxDimension = 1200;
  static const int quality = 85;

  /// Returns a downscaled copy, or [file] unchanged if compression fails —
  /// a scan with a large image is better than no scan at all.
  static Future<File> compress(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final target = p.join(
        dir.path,
        '${DateTime.now().millisecondsSinceEpoch}_scan.jpg',
      );

      final before = await file.length();
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        target,
        quality: quality,
        minWidth: maxDimension,
        minHeight: maxDimension,
      );

      if (result == null) return file;

      final out = File(result.path);
      final after = await out.length();
      appLogger.d(
          '[ScanImage] ${(before / 1024).round()}KB -> ${(after / 1024).round()}KB');
      return out;
    } catch (e) {
      appLogger.w('[ScanImage] Compression failed, sending original: $e');
      return file;
    }
  }
}
