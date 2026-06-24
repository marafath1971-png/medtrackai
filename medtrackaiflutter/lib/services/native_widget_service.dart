import 'dart:io';
import 'package:flutter/services.dart';
import '../core/utils/logger.dart';

class NativeWidgetService {
  static const MethodChannel _channel = MethodChannel('com.medtrackai.widget');

  /// Syncs app state data to the native iOS widget.
  static Future<void> syncWidgetData({
    required int streak,
    required String nextMedName,
    required String nextMedTime,
    required String mascotMood,
  }) async {
    if (!Platform.isIOS) return;

    try {
      await _channel.invokeMethod('syncData', {
        'streak': streak,
        'nextMedName': nextMedName,
        'nextMedTime': nextMedTime,
        'mascotMood': mascotMood,
      });
      appLogger.d('[NativeWidgetService] Successfully synced data to iOS widget.');
    } catch (e) {
      appLogger.w('[NativeWidgetService] Failed to sync widget data: $e');
    }
  }
}
