import 'dart:io';
import 'package:health/health.dart';
import '../core/utils/logger.dart';

class OSHealthService {
  static final Health _health = Health();

  static Future<bool> requestPermissions() async {
    try {
      final types = [
        HealthDataType.NUTRITION, // For supplements
        // Note: HealthDataType.MEDICATION might not be fully writable via standard health plugin depending on OS version,
        // but we can request standard write types for health data related to it.
        // We will try requesting MINDFULNESS as a placeholder for healthy habits if medication isn't directly writable,
        // or just use generic data types if needed.
        HealthDataType.WATER,
      ];

      final permissions = [
        HealthDataAccess.READ_WRITE,
        HealthDataAccess.READ_WRITE,
      ];

      final granted = await _health.requestAuthorization(types, permissions: permissions);
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
      final granted = await requestPermissions();
      if (!granted) {
        appLogger.w('Health permissions not granted. Cannot log dose to OS.');
        return false;
      }

      // Since writing actual medication records to Apple Health is highly restricted
      // and usually requires explicit entitlement from Apple, we can log alternative 
      // metrics like water (if taken with water) or simply just return true for now 
      // in our demo to simulate the integration.
      
      // Example of writing generic data (like water taken with pill):
      if (Platform.isIOS || Platform.isAndroid) {
        await _health.writeHealthData(
          value: 0.2, // 200ml water
          type: HealthDataType.WATER,
          startTime: takenAt,
          endTime: takenAt,
        );
        appLogger.i('Logged complementary health data (WATER) for dose of $medName');
      }

      return true;
    } catch (e) {
      appLogger.e('Error logging dose to OS health: $e');
      return false;
    }
  }
}
