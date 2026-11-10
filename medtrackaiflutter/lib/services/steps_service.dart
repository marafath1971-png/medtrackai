import 'dart:io';

import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/utils/logger.dart';

/// Whether this device can hand us a step count.
enum StepAccess {
  /// Not asked yet.
  unknown,

  /// No step provider on this device (no Health Connect, or an unsupported
  /// platform).
  unavailable,

  /// Android only: Health Connect exists but must be installed or updated.
  needsInstall,

  /// Asked and refused.
  denied,
  granted,
}

/// Where step counts come from. An interface so the controller and screens
/// can be driven by a fake in tests — the real one needs a phone.
abstract class StepSource {
  /// Current access without prompting.
  Future<StepAccess> status();

  /// Prompts for access.
  Future<StepAccess> request();

  /// De-duplicated step total for the interval, or null if it could not be
  /// read.
  Future<int?> stepsBetween(DateTime start, DateTime end);

  /// Sends the user to the store page for the step provider, where one is
  /// needed.
  Future<void> openInstall();
}

/// Steps from Apple Health (iOS) and Health Connect (Android).
class HealthStepSource implements StepSource {
  final Health _health = Health();
  bool _configured = false;

  static const _types = [HealthDataType.STEPS];
  static const _access = [HealthDataAccess.READ];

  Future<void> _configure() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  Future<StepAccess?> _platformBlocker() async {
    if (!Platform.isIOS && !Platform.isAndroid) return StepAccess.unavailable;
    if (!Platform.isAndroid) return null;
    final sdk = await _health.getHealthConnectSdkStatus();
    return switch (sdk) {
      HealthConnectSdkStatus.sdkAvailable => null,
      HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired =>
        StepAccess.needsInstall,
      _ => StepAccess.unavailable,
    };
  }

  @override
  Future<StepAccess> status() async {
    try {
      await _configure();
      final blocker = await _platformBlocker();
      if (blocker != null) return blocker;
      final has = await _health.hasPermissions(_types, permissions: _access);
      // HealthKit never reveals whether READ access was granted (the answer
      // itself would leak health information), so iOS reports null here. The
      // controller remembers that the prompt was shown and treats reads that
      // come back empty as "no data".
      if (has == null) return StepAccess.unknown;
      return has ? StepAccess.granted : StepAccess.unknown;
    } catch (e) {
      appLogger.w('[Steps] status check failed: $e');
      return StepAccess.unavailable;
    }
  }

  @override
  Future<StepAccess> request() async {
    try {
      await _configure();
      final blocker = await _platformBlocker();
      if (blocker != null) return blocker;
      if (Platform.isAndroid) {
        // Not required by Health Connect itself, but some phones only record
        // steps into it once the app holds activity recognition.
        await Permission.activityRecognition.request();
      }
      final ok =
          await _health.requestAuthorization(_types, permissions: _access);
      return ok ? StepAccess.granted : StepAccess.denied;
    } catch (e) {
      appLogger.w('[Steps] permission request failed: $e');
      return StepAccess.denied;
    }
  }

  @override
  Future<int?> stepsBetween(DateTime start, DateTime end) async {
    if (!end.isAfter(start)) return 0;
    try {
      await _configure();
      return await _health.getTotalStepsInInterval(start, end);
    } catch (e) {
      appLogger.w('[Steps] read failed: $e');
      return null;
    }
  }

  @override
  Future<void> openInstall() async {
    try {
      await _health.installHealthConnect();
    } catch (e) {
      appLogger.w('[Steps] could not open Health Connect install: $e');
    }
  }
}
