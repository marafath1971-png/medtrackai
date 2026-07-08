import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../core/utils/logger.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> isBiometricAvailable() async {
    try {
      return await _auth.isDeviceSupported();
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
        // Allow bypass in debug mode if biometrics/passcode are not setup on simulator
        bool isDebug = false;
        assert(() { isDebug = true; return true; }());
        return isDebug;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: reason,
      );
      
      return authenticated;
    } on PlatformException catch (e) {
      if (e.code == 'auth_in_progress' || e.code == 'authInProgress') {
        appLogger.w('Biometric auth already in progress; skipping duplicate request.');
        return false;
      }
      appLogger.e('Error during biometric authentication: ${e.message}');
      bool isDebug = false;
      assert(() { isDebug = true; return true; }());
      return isDebug;
    } catch (e, stack) {
      appLogger.e('Error during biometric authentication: $e\n$stack');
      bool isDebug = false;
      assert(() { isDebug = true; return true; }());
      
      // If we are on a real device and it fails, do not hard-lock in debug builds.
      return isDebug;
    }
  }
}
