import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../core/utils/logger.dart';

class NativeWidgetService {
  static const MethodChannel _channel = MethodChannel('com.medtrackai.widget');

  @visibleForTesting
  static bool enableForTesting = false;

  /// Syncs app state data to the native iOS widget.
  static Future<void> syncWidgetData({
    required int streak,
    required String nextMedName,
    required String nextMedTime,
    required String mascotMood,
  }) async {
    if (!Platform.isIOS && !enableForTesting) return;

    try {
      await _channel.invokeMethod('syncData', {
        'streak': streak,
        'nextMedName': nextMedName,
        'nextMedTime': nextMedTime,
        'mascotMood': mascotMood,
      });
      appLogger
          .d('[NativeWidgetService] Successfully synced data to iOS widget.');
    } catch (e) {
      appLogger.w('[NativeWidgetService] Failed to sync widget data: $e');
    }
  }

  /// Pushes today's steps to the home-screen steps widget (iOS WidgetKit and
  /// the Android app widget share the channel and the payload).
  ///
  /// [partnerSteps] is -1 when there is no walking partner, which is how the
  /// widget tells "no partner" from "partner at zero".
  static Future<void> syncSteps({
    required bool enabled,
    required int steps,
    required int goal,
    required int streak,
    required String partnerName,
    required int partnerSteps,
    required int partnerGoal,
  }) async {
    if (!Platform.isIOS && !Platform.isAndroid && !enableForTesting) return;

    try {
      await _channel.invokeMethod('syncSteps', {
        'enabled': enabled,
        'steps': steps,
        'goal': goal,
        'streak': streak,
        'partnerName': partnerName,
        'partnerSteps': partnerSteps,
        'partnerGoal': partnerGoal,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      appLogger.w('[NativeWidgetService] Failed to sync steps widget: $e');
    }
  }
}
