import 'dart:io';

/// Lightweight connectivity probe — no extra package.
class NetworkStatus {
  NetworkStatus._();

  static Future<bool> isOnline({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      final result = await InternetAddress.lookup('dns.google')
          .timeout(timeout);
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
