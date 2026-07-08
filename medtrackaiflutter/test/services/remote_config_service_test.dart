import 'package:flutter_test/flutter_test.dart';
import 'package:medai/services/remote_config_service.dart';

/// Guards the shipped Remote Config defaults — the values the app runs on
/// whenever Firebase is unreachable (and in every unit test, since init()
/// is never called here). If one of these flips accidentally, a paywall
/// fence could silently open or a funnel step could vanish for all users
/// with no console override in place.
void main() {
  test('service reports not-ready without init', () {
    expect(RemoteConfigService.isReady, isFalse);
  });

  group('paywall defaults', () {
    test('annual-led, weekly visible, timeline on', () {
      expect(RemoteConfigService.defaultPlan, 'annual');
      expect(RemoteConfigService.showWeeklyPlan, isTrue);
      expect(RemoteConfigService.showTrialTimeline, isTrue);
    });

    test('exit offer ships OFF (iOS review gray area)', () {
      expect(
          RemoteConfigService.getBool('paywall_exit_offer_enabled'), isFalse);
    });

    test('trial reminder ships ON (paywall timeline promises it)', () {
      expect(RemoteConfigService.trialReminderEnabled, isTrue);
    });

    test('headline variant defaults to personalized', () {
      expect(RemoteConfigService.getString('paywall_headline_variant'),
          'personalized');
    });
  });

  group('onboarding defaults', () {
    test('rating, ATT, and skip all enabled by default', () {
      expect(RemoteConfigService.showRatingStep, isTrue);
      expect(RemoteConfigService.showAttStep, isTrue);
      expect(RemoteConfigService.getBool('onboarding_skip_enabled'), isTrue);
    });
  });

  group('free-tier fences', () {
    test('shipped limits: 5 meds, 3 scans, 3 voice logs', () {
      expect(RemoteConfigService.freeTierMedLimit, 5);
      expect(RemoteConfigService.freeTierScanLimit, 3);
      expect(RemoteConfigService.freeTierVoiceLimit, 3);
    });

    test('limits are positive — a zero default would hard-lock free users',
        () {
      expect(RemoteConfigService.freeTierMedLimit, greaterThan(0));
      expect(RemoteConfigService.freeTierScanLimit, greaterThan(0));
      expect(RemoteConfigService.freeTierVoiceLimit, greaterThan(0));
    });
  });

  group('unknown keys fall back safely', () {
    test('bool -> false, int -> 0, string -> empty', () {
      expect(RemoteConfigService.getBool('nonexistent_key'), isFalse);
      expect(RemoteConfigService.getInt('nonexistent_key'), 0);
      expect(RemoteConfigService.getString('nonexistent_key'), '');
    });
  });
}
