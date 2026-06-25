import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../core/utils/logger.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } on PlatformException catch (e) {
      appLogger.e('Error checking biometric availability: ${e.message}');
      return false;
    }
  }

  static Future<bool> authenticate({String reason = 'Authenticate to access MedAI'}) async {
    try {
      final available = await isBiometricAvailable();
      if (!available) {
        appLogger.w('Biometric authentication is not available on this device.');
        return false;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: reason,
      );
      
      return authenticated;
    } on PlatformException catch (e) {
      appLogger.e('Error during biometric authentication: ${e.message}');
      return false;
    }
  }
}
