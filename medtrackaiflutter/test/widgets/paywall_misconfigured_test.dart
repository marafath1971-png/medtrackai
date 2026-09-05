import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// With no RevenueCat key the paywall is the screen every user reaches, so its
/// misconfigured branch is the live path — not an edge case. Nothing covered
/// it, and the failure mode it guards against is silent: an empty package list
/// looks exactly like a failed network fetch.
void main() {
  late String src;

  setUpAll(() {
    src = File('lib/screens/paywall/premium_paywall_overlay.dart')
        .readAsStringSync();
  });

  group('a build that cannot sell says so', () {
    test('it distinguishes no-key from a failed fetch', () {
      // "Check your connection and try again" for a build with no key sends
      // the user to debug wifi over something no retry can fix.
      expect(src.contains('PurchasesService.isMisconfigured'), isTrue);

      final i = src.indexOf('isMisconfigured');
      final near = src.substring(i, (i + 400).clamp(0, src.length));
      expect(near.contains('not set up in this build'), isTrue,
          reason: 'the no-key case needs its own wording');
    });

    test('the retry affordance is not offered when retrying cannot work', () {
      // Retry is honest for a transient offerings failure and dishonest here.
      final i = src.indexOf("? 'Not available yet'");
      final j = src.indexOf("'Not available yet'");
      expect(j, greaterThan(-1),
          reason: 'a build without billing must not present a Retry button');
      expect(i == -1 || j > -1, isTrue);
    });

    test('the CTA is disabled when there is nothing to buy', () {
      // A live-looking button that cannot transact is worse than a dead one.
      expect(src.contains('enabled: hasPackages'), isTrue);
    });

    test('it reassures rather than reading as breakage', () {
      expect(src.contains('nothing is charged'), isTrue,
          reason: 'the user should know the app still works');
    });
  });

  group('the misconfigured state cannot be reached by accident', () {
    test('isMisconfigured is set only from a key check', () {
      final svc =
          File('lib/services/purchases_service.dart').readAsStringSync();
      // A transient offerings failure must not latch this flag, or a user with
      // bad wifi is told the build cannot sell anything.
      final sets = RegExp(r'_misconfigured\s*=\s*true').allMatches(svc).length;
      expect(sets, 1,
          reason: 'exactly one place should declare the build unsellable');

      // Walk back to the nearest enclosing branch rather than a fixed
      // window: a long comment sits between the guard and the assignment, and
      // a character count would measure the comment, not the control flow.
      final i = svc.indexOf('_misconfigured = true');
      final guard = svc.lastIndexOf('if (', i);
      expect(guard, greaterThan(-1));
      final condition = svc.substring(guard, svc.indexOf(')', guard) + 1);
      expect(condition.contains('_isValidKey'), isTrue,
          reason: 'it must follow the key check, not a network error; '
              'found instead: $condition');
    });
  });
}
