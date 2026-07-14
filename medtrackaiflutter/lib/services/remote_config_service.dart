import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import '../core/utils/logger.dart';

/// Central experiment/config switchboard (blueprint §3.1 — the single
/// highest-leverage revenue gap: apps running 50+ paywall experiments earn
/// 18.7x more than apps running one).
///
/// Every monetization-sensitive value routes through here so pricing, plan
/// order, copy, and funnel structure can change WITHOUT an app release.
/// Call [init] once after Firebase.initializeApp (safe to fail silently:
/// all getters fall back to shipped defaults).
class RemoteConfigService {
  RemoteConfigService._();

  static FirebaseRemoteConfig? _rc;
  static bool get isReady => _rc != null;

  /// Shipped defaults — the app behaves exactly as coded until the console
  /// overrides them. Keys are the experiment surface.
  static const Map<String, dynamic> _defaults = {
    // Paywall
    'paywall_headline_variant': 'personalized', // personalized | generic
    'paywall_show_trial_timeline': true,
    'paywall_default_plan': 'annual', // annual | monthly | weekly
    'paywall_show_weekly_plan': true,
    'paywall_exit_offer_enabled': false, // iOS App Review gray area
    // Onboarding
    'onboarding_show_rating_step': true,
    'onboarding_show_att_step': true,
    'onboarding_skip_enabled': true,
    // Defer the onboarding paywall until the user has added their first med
    // (the activation "aha"). Session-1 activators convert 2-3x better, so
    // asking for the trial *after* value should lift trial-start rate.
    'paywall_after_activation': true,
    // Free tier gates
    'free_tier_med_limit': 5,
    'free_tier_scan_limit': 3,
    'free_tier_voice_limit': 3,
    // Trial reminder
    'trial_reminder_enabled': true,
  };

  static Future<void> init() async {
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 8),
        minimumFetchInterval: kDebugMode
            ? Duration.zero
            : const Duration(hours: 1),
      ));
      await rc.setDefaults(_defaults);
      await rc.fetchAndActivate();
      _rc = rc;
      appLogger.i('[RemoteConfig] initialized & activated');
    } catch (e) {
      // Never block launch on config — defaults keep the app fully working.
      appLogger.w('[RemoteConfig] init failed, using defaults: $e');
    }
  }

  static bool getBool(String key) =>
      _rc?.getBool(key) ?? (_defaults[key] as bool? ?? false);

  static int getInt(String key) =>
      _rc?.getInt(key) ?? (_defaults[key] as int? ?? 0);

  static String getString(String key) =>
      _rc?.getString(key) ?? (_defaults[key] as String? ?? '');

  // ── Typed accessors used by the funnel ────────────────────────────────
  static bool get showTrialTimeline => getBool('paywall_show_trial_timeline');
  static String get defaultPlan => getString('paywall_default_plan');
  static bool get showWeeklyPlan => getBool('paywall_show_weekly_plan');
  static bool get showRatingStep => getBool('onboarding_show_rating_step');
  static bool get showAttStep => getBool('onboarding_show_att_step');
  static int get freeTierMedLimit => getInt('free_tier_med_limit');
  static int get freeTierScanLimit => getInt('free_tier_scan_limit');
  static int get freeTierVoiceLimit => getInt('free_tier_voice_limit');
  static bool get trialReminderEnabled => getBool('trial_reminder_enabled');
  static bool get paywallAfterActivation => getBool('paywall_after_activation');
}
