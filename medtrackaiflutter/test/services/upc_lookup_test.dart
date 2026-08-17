import 'package:flutter_test/flutter_test.dart';
import 'package:medai/services/upc_service.dart';

/// Barcode lookup returned `String?`, so three unrelated outcomes all arrived
/// as `null`: the code is absent from both public databases, the device is
/// offline, or the free UPCItemDB trial tier refused the request. The scanner
/// treated every one as "not found" and sent the AI a bare number, presenting
/// whatever came back as an identification of a medicine.
///
/// It also had no timeout — unlike the Gemini calls, which cap at 30s — so a
/// stalled connection froze the scanner, and it interpolated the raw scanned
/// value straight into a request URL.
void main() {
  group('isPlausibleBarcode', () {
    test('accepts the retail symbologies', () {
      // UPC-E through GTIN-14.
      expect(UPCService.isPlausibleBarcode('123456'), isTrue);
      expect(UPCService.isPlausibleBarcode('036000291452'), isTrue);
      expect(UPCService.isPlausibleBarcode('0123456789012'), isTrue);
      expect(UPCService.isPlausibleBarcode('01234567890123'), isTrue);
    });

    test('rejects QR payloads', () {
      // mobile_scanner decodes QR codes too, and a QR can carry anything.
      expect(UPCService.isPlausibleBarcode('https://example.com/x'), isFalse);
      expect(UPCService.isPlausibleBarcode('WIFI:S:net;P:pass;;'), isFalse);
      expect(UPCService.isPlausibleBarcode('hello world'), isFalse);
    });

    test('rejects values that would corrupt a query string', () {
      // These reached Uri.parse unescaped. & would append a parameter and #
      // would truncate the request.
      expect(UPCService.isPlausibleBarcode('123&foo=bar'), isFalse);
      expect(UPCService.isPlausibleBarcode('123#fragment'), isFalse);
      expect(UPCService.isPlausibleBarcode('../../etc/passwd'), isFalse);
    });

    test('rejects empty and out-of-range lengths', () {
      expect(UPCService.isPlausibleBarcode(''), isFalse);
      expect(UPCService.isPlausibleBarcode('12345'), isFalse);
      expect(UPCService.isPlausibleBarcode('123456789012345'), isFalse);
    });
  });

  group('lookup short-circuits before any request', () {
    test('an implausible code is unknown, not a failure', () async {
      // No network is available in tests; this must return without one, which
      // also proves the validator runs before the HTTP call.
      final result = await UPCService.lookup('not-a-barcode');

      expect(result, isA<BarcodeUnknown>(),
          reason: 'a QR payload is not a barcode lookup failure — there was '
              'nothing worth looking up');
    });

    test('whitespace is trimmed before validation', () async {
      final result = await UPCService.lookup('   ');

      expect(result, isA<BarcodeUnknown>());
    });
  });

  group('the outcome types are distinguishable', () {
    test('unknown and failed are different states', () {
      // The whole point of the sealed class: "we asked and nobody knew" must
      // not read the same as "we could not ask".
      const unknown = BarcodeUnknown();
      const failed = BarcodeLookupFailed('SocketException');

      expect(unknown, isNot(isA<BarcodeLookupFailed>()));
      expect(failed, isNot(isA<BarcodeUnknown>()));
      expect(failed.reason, contains('SocketException'));
    });

    test('a found result carries its source', () {
      // Two independent databases answer; knowing which one matters when a
      // supplement name comes back from a food database.
      const found = BarcodeFound('Metformin 500mg', 'UPCItemDB');

      expect(found.name, 'Metformin 500mg');
      expect(found.source, 'UPCItemDB');
    });
  });

  group('timeout', () {
    test('lookups are capped so the scanner cannot hang', () {
      // Public databases are best-effort. Without this the scanner waited
      // forever on a stalled connection with no way out.
      expect(UPCService.timeoutForTest.inSeconds, lessThanOrEqualTo(10));
      expect(UPCService.timeoutForTest.inSeconds, greaterThan(0));
    });
  });
}
