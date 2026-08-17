import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/utils/logger.dart';

/// Outcome of a barcode lookup.
///
/// The old signature returned `String?`, which collapsed three very different
/// situations into `null`: the barcode is genuinely absent from both public
/// databases, the device is offline, or the free UPCItemDB trial tier refused
/// the request. The caller could only ever say "not found", so a rate-limited
/// lookup told the user their medicine does not exist.
sealed class BarcodeLookup {
  const BarcodeLookup();
}

/// A product name was found.
class BarcodeFound extends BarcodeLookup {
  final String name;
  final String source;
  const BarcodeFound(this.name, this.source);
}

/// Both databases answered, neither knew this code. The AI can still try.
class BarcodeUnknown extends BarcodeLookup {
  const BarcodeUnknown();
}

/// The lookup could not complete — offline, timed out, or refused.
///
/// Distinct from [BarcodeUnknown] because retrying may help, and because the
/// user deserves different advice.
class BarcodeLookupFailed extends BarcodeLookup {
  final String reason;
  const BarcodeLookupFailed(this.reason);
}

class UPCService {
  /// Public barcode databases are best-effort; a scan should not hang on them.
  ///
  /// The Gemini calls already cap at 30s, but these had no timeout at all, so a
  /// stalled connection froze the scanner with no way out. 8s is generous for a
  /// simple GET and still short enough that the AI fallback feels responsive.
  static const Duration _timeout = Duration(seconds: 8);

  /// Exposed so a test can pin that the cap exists — its absence is what froze
  /// the scanner, and that is invisible to any test that only checks results.
  @visibleForTesting
  static Duration get timeoutForTest => _timeout;

  /// Looks up a scanned code, trying UPCItemDB then OpenFoodFacts.
  static Future<BarcodeLookup> lookup(String barcode) async {
    final code = barcode.trim();
    if (!isPlausibleBarcode(code)) {
      appLogger.w('[UPCService] Ignoring implausible barcode');
      return const BarcodeUnknown();
    }

    // Percent-encode before interpolating. A QR code can carry arbitrary text,
    // and an unescaped & or # would silently truncate or corrupt the query.
    final q = Uri.encodeQueryComponent(code);

    try {
      final upc = await http
          .get(Uri.parse(
              'https://api.upcitemdb.com/prod/trial/lookup?upc=$q'))
          .timeout(_timeout);

      if (upc.statusCode == 200) {
        final data = json.decode(upc.body);
        final items = data['items'];
        if (items is List && items.isNotEmpty) {
          final title = items.first['title'];
          if (title is String && title.trim().isNotEmpty) {
            appLogger.i('[UPCService] Found via UPCItemDB');
            return BarcodeFound(title.trim(), 'UPCItemDB');
          }
        }
      } else if (upc.statusCode == 429 || upc.statusCode == 403) {
        // The trial tier is rate limited per day. Treating that as "not found"
        // is what made a working barcode look unrecognised.
        appLogger.w('[UPCService] UPCItemDB refused: ${upc.statusCode}');
      }
    } catch (e) {
      // Deliberately swallowed: OpenFoodFacts below is an independent source
      // and is worth trying even when the first host is unreachable.
      appLogger.w('[UPCService] UPCItemDB lookup failed: $e');
    }

    try {
      final off = await http
          .get(Uri.parse(
              'https://world.openfoodfacts.org/api/v0/product/$q.json'))
          .timeout(_timeout);

      if (off.statusCode == 200) {
        final data = json.decode(off.body);
        final name = data['product']?['product_name'];
        if (name is String && name.trim().isNotEmpty) {
          appLogger.i('[UPCService] Found via OpenFoodFacts');
          return BarcodeFound(name.trim(), 'OpenFoodFacts');
        }
      }
    } catch (e) {
      appLogger.w('[UPCService] OpenFoodFacts lookup failed: $e');
      // Both sources errored rather than answering, so this is a failure to
      // look up — not evidence the product is unknown.
      return BarcodeLookupFailed('$e');
    }

    appLogger.w('[UPCService] Barcode not in any public database');
    return const BarcodeUnknown();
  }

  /// Whether a scanned string looks like a retail barcode.
  ///
  /// Barcode scanners also decode QR codes, which can contain URLs or arbitrary
  /// text. Sending those to a UPC database is pointless and puts unvalidated
  /// input into a request URL.
  static bool isPlausibleBarcode(String value) {
    if (value.isEmpty || value.length > 14) return false;
    // UPC-E (6) through GTIN-14 (14); all retail symbologies are pure digits.
    if (value.length < 6) return false;
    return RegExp(r'^\d+$').hasMatch(value);
  }

  /// Back-compat wrapper for callers that only want a name.
  @Deprecated('Use lookup() so offline and rate-limited cases can be told apart')
  static Future<String?> lookupBarcode(String barcode) async {
    final result = await lookup(barcode);
    return result is BarcodeFound ? result.name : null;
  }
}
