import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/logger.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Log a custom event with properties.
  static Future<void> logEvent(String name,
      {Map<String, Object>? parameters}) async {
    try {
      if (kDebugMode) {
        appLogger.d('[Analytics] Logging Event: $name | Params: $parameters');
      }
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      if (kDebugMode) appLogger.e('[Analytics] Error: $e');
    }
  }

  /// Specific event for Medicine Scanning.
  ///
  /// Records only whether the scan succeeded. What was scanned is health
  /// data: sending a drug name to an analytics vendor alongside [setUserId]
  /// is the disclosure the FTC Health Breach Notification Rule treats as a
  /// breach, so it never leaves the device through this service.
  static Future<void> logMedicineScan({required bool success}) async {
    await logEvent('medicine_scan', parameters: {
      'is_success': success ? 1 : 0,
    });
  }

  /// Specific event for Subscription
  static Future<void> logSubscriptionStart(String planId) async {
    await logEvent('subscription_start', parameters: {
      'plan_id': planId,
    });
  }

  /// Specific event for Care Circle
  static Future<void> logCareInviteSent() async {
    await logEvent('care_invite_sent');
  }

  /// Record user ID for personalized tracking (HIPAA safe - anonymous UID)
  static Future<void> setUserId(String? uid) async {
    await _analytics.setUserId(id: uid);
  }

  /// Log Dose interactions (take, skip, miss).
  ///
  /// Deliberately takes no medicine name, for the reason on [logMedicineScan].
  static Future<void> logDoseAction({
    required String action,
    Map<String, Object>? extra,
  }) async {
    await logEvent('dose_action', parameters: {
      'action': action, // 'take', 'skip', 'miss'
      ...?extra,
    });
  }

  /// Log Screen Views for non-standard routing
  static Future<void> logScreenView(String screenName) async {
    await _analytics.logEvent(
      name: 'screen_view_custom',
      parameters: {'screen_name': screenName},
    );
  }

  /// Log Onboarding Completion
  static Future<void> logOnboardingComplete() async {
    await logEvent('onboarding_complete');
  }
}
