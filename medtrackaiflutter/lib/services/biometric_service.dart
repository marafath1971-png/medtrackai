import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../core/utils/logger.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static const _authTimeout = Duration(seconds: 25);

  /// True when biometrics or device PIN/pattern/password can unlock.
  static Future<bool> isBiometricAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException catch (e) {
      appLogger.e('Error checking biometric availability: ${e.message}');
      return false;
    }
  }

  /// Cancels an in-flight system auth prompt when possible.
  static Future<void> cancelAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } catch (_) {/* best-effort */}
  }

  static Future<bool> authenticate({
    String reason = 'Authenticate to access MedAI',
  }) async {
    try {
      final available = await isBiometricAvailable();
      if (!available) {
        appLogger.w('Biometric authentication is not available on this device.');
        // Allow bypass in debug when biometrics/passcode are not set up.
        return _debugBypass;
      }

      final authenticated = await _auth
          .authenticate(
            localizedReason: reason,
            biometricOnly: false,
            persistAcrossBackgrounding: true,
          )
          .timeout(_authTimeout, onTimeout: () {
        appLogger.w(
            'Biometric authentication timed out after ${_authTimeout.inSeconds}s.');
        cancelAuthentication();
        return false;
      });

      return authenticated;
    } on PlatformException catch (e) {
      if (e.code == 'auth_in_progress' || e.code == 'authInProgress') {
        appLogger.w(
            'Biometric auth already in progress; skipping duplicate request.');
        return false;
      }
      appLogger.e('Error during biometric authentication: ${e.message}');
      return _debugBypass;
    } catch (e, stack) {
      appLogger.e('Error during biometric authentication: $e\n$stack');
      // Debug builds: never hard-lock the session on auth plugin failures.
      return _debugBypass;
    }
  }

  static bool get _debugBypass {
    var isDebug = false;
    assert(() {
      isDebug = true;
      return true;
    }());
    return isDebug;
  }
}
