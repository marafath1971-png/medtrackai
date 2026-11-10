import 'dart:io';
import 'package:health/health.dart';
import '../core/utils/logger.dart';

class OSHealthService {
  static final Health _health = Health();
  static bool? _hasAuth;

  static Future<bool> hasPermissions() async {
    try {
      final types = [HealthDataType.MINDFULNESS];
      return await _health.hasPermissions(types) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestPermissions() async {
    try {
      final types = [HealthDataType.MINDFULNESS];
      final permissions = [HealthDataAccess.READ_WRITE];
      final granted =
          await _health.requestAuthorization(types, permissions: permissions);
      _hasAuth = granted;
      return granted;
    } catch (e) {
      appLogger.e('Error requesting OS health permissions: $e');
      return false;
    }
  }

  static Future<bool> logDose({
    required String medName,
    required double dosageAmount,
    required DateTime takenAt,
  }) async {
    try {
      // Avoid repeatedly prompting or checking permissions if not granted
      if (_hasAuth == false) return false;
      final authorized = _hasAuth ?? await hasPermissions();
      if (!authorized) return false;

      // Do not forge false clinical data like water intake.
      // If the OS health integration has permissions for mindfulness/wellness habits,
      // record a mindful habit timestamp; otherwise gracefully skip.
      if (Platform.isIOS || Platform.isAndroid) {
        await _health.writeHealthData(
          value: 1, // 1 minute mindful health adherence moment
          type: HealthDataType.MINDFULNESS,
          startTime: takenAt.subtract(const Duration(minutes: 1)),
          endTime: takenAt,
        );
        appLogger.i('Logged health adherence session for dose of $medName');
      }

      return true;
    } catch (e) {
      appLogger.w('OS health sync skipped: $e');
      return false;
    }
  }
}
