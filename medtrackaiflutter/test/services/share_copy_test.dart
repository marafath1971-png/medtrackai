import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Share text is the only copy in this app that leaves it.
///
/// A superlative on an in-app screen is marketing the user can judge against
/// the product in front of them. The same sentence in a referral message is a
/// claim made *about* the product to someone who has never seen it, forwarded
/// under the sender's name — so it has a higher bar, not a lower one.
///
/// The referral message carried "the #1 companion for medication success".
/// Nothing measures that. The codebase had already had its fabricated ratings
/// and install counts stripped (see invite_error_test.dart), but that guard
/// greps for the specific strings that were removed then — "500K+", "4.9 ·" —
/// so a different unverifiable claim in a different file passed it untouched.
void main() {
  group('outbound share copy makes no unverifiable claim', () {
    late String source;

    setUpAll(() {
      source = File('lib/services/share_service.dart').readAsStringSync();
    });

    /// Code lines only — several comments here explain the removed claims.
    Iterable<String> codeLines(String src) =>
        src.split('\n').where((l) => !l.trimLeft().startsWith('//'));

    test('no ranking claim survives', () {
      final offenders = codeLines(source).where((l) =>
          l.contains('#1') || l.contains('number one') || l.contains('No. 1'));

      expect(offenders, isEmpty,
          reason: 'a ranking nobody has measured, sent to a stranger');
    });

    test('no superlative stands in for evidence', () {
      // "best", "most accurate", "leading" — each asserts a comparison
      // against products this app has never been measured against.
      final offenders = codeLines(source).where((l) {
        final t = l.toLowerCase();
        return t.contains("world's best") ||
            t.contains('the best app') ||
            t.contains('most accurate') ||
            t.contains('leading app');
      });

      expect(offenders, isEmpty);
    });

    test('no invented user count or rating', () {
      // The same class of claim invite_error_test.dart guards elsewhere,
      // checked here because share text is a separate file it does not read.
      final offenders = codeLines(source).where((l) =>
          RegExp(r'\b\d+(\.\d+)?\s*(million|M\+|K\+)\s*(users|people|downloads)',
                  caseSensitive: false)
              .hasMatch(l) ||
          RegExp(r'\b[45]\.\d\s*(stars?|rating|★)', caseSensitive: false)
              .hasMatch(l));

      expect(offenders, isEmpty);
    });

    test('the referral message still says what the app is for', () {
      // Removing a claim must not leave the invite meaningless — the person
      // receiving it still needs a reason to tap.
      expect(source, contains('every dose'));
    });
  });
}
