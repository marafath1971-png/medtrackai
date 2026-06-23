import 'package:flutter/services.dart';

class HapticEngine {
  static bool isEnabled = true;
  static DateTime? _lastHapticTime;
  static const int _minIntervalMs = 80;

  static Future<void> _trigger(Future<void> Function() action) async {
    if (!isEnabled) return;
    
    final now = DateTime.now();
    if (_lastHapticTime != null && 
        now.difference(_lastHapticTime!).inMilliseconds < _minIntervalMs) {
      return; // Rate limit / throttle to prevent spamming
    }
    
    _lastHapticTime = now;
    try {
      await action();
    } catch (_) {
      // Ignore platform exceptions (e.g., if haptics unavailable)
    }
  }

  // ── Core Haptic Levels ─────────────────────────────────────────
  static Future<void> light() => _trigger(HapticFeedback.lightImpact);
  static Future<void> medium() => _trigger(HapticFeedback.mediumImpact);
  static Future<void> heavy() => _trigger(HapticFeedback.heavyImpact);
  static Future<void> selection() => _trigger(HapticFeedback.selectionClick);
  static Future<void> error() => _trigger(HapticFeedback.vibrate);

  // ── Existing Aliases & Composite Haptics ───────────────────────
  static Future<void> lightImpact() => light();
  static Future<void> heavyImpact() => heavy();
  static Future<void> lightTap() => light();
  static Future<void> success() => medium();

  static Future<void> successScan() async {
    await heavy();
    await Future.delayed(const Duration(milliseconds: 80));
    await selection();
  }

  static Future<void> doseTaken() async {
    await medium();
    await Future.delayed(const Duration(milliseconds: 100));
    await medium();
  }

  static Future<void> alertWarning() async {
    await heavy();
    await Future.delayed(const Duration(milliseconds: 80));
    await heavy();
  }

  static Future<void> successDose() async {
    await medium();
    await Future.delayed(const Duration(milliseconds: 80));
    await medium();
  }

  static Future<void> heavyMilestone() async {
    await heavy();
    await Future.delayed(const Duration(milliseconds: 150));
    await error();
  }
}
