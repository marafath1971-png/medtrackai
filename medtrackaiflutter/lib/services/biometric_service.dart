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
  ///
  /// Throws when there is no prompt to cancel — "BiometricFragment not found"
  /// — which is the normal case after the Activity was stopped before the
  /// prompt appeared, so it is not an error worth surfacing.
  static Future<void> cancelAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } catch (_) {/* best-effort */}
  }

  /// True while a system prompt is outstanding.
  ///
  /// The plugin rejects a second concurrent request with auth_in_progress, and
  /// the lock screen re-offers the prompt whenever the app returns to the
  /// foreground, so the two can collide without this.
  static bool _inFlight = false;

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

      if (_inFlight) {
        appLogger.w('Biometric prompt already showing; not requesting again.');
        return false;
      }

      _inFlight = true;
      try {
        return await _auth
            .authenticate(
              localizedReason: reason,
              biometricOnly: false,
              persistAcrossBackgrounding: true,
            )
            .timeout(_authTimeout, onTimeout: () {
          appLogger.w('Biometric authentication timed out after '
              '${_authTimeout.inSeconds}s.');
          cancelAuthentication();
          return false;
        });
      } finally {
        _inFlight = false;
      }
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
