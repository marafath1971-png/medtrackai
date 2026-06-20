import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../core/utils/haptic_engine.dart';

enum AlertType { success, warning, error, info }

class SmartAlertService {
  static OverlayEntry? _currentEntry;
  static bool _isShowing = false;

  static void show(
    BuildContext context, {
    required String title,
    String? message,
    AlertType type = AlertType.info,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (_isShowing) {
      _currentEntry?.remove();
      _currentEntry = null;
    }

    _isShowing = true;

    // Determine colors and haptics based on type
    final L = context.L;
    Color bgColor = L.bg;
    Color accentColor = L.primary;
    IconData defaultIcon = Icons.info_outline_rounded;

    switch (type) {
      case AlertType.success:
        accentColor = L.success;
        defaultIcon = Icons.check_circle_rounded;
        HapticEngine.doseTaken();
        break;
      case AlertType.warning:
        accentColor = L.warning;
        defaultIcon = Icons.warning_rounded;
        HapticEngine.medium();
        break;
      case AlertType.error:
        accentColor = L.error;
        defaultIcon = Icons.error_rounded;
        HapticEngine.medium();
        break;
      case AlertType.info:
        accentColor = AppColors.cyanAccent;
        defaultIcon = Icons.info_outline_rounded;
        HapticEngine.light();
        break;
    }

    final displayIcon = icon ?? defaultIcon;

    _currentEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          child: SafeArea(
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1),
                    boxShadow: AppShadows.glow(accentColor, intensity: 0.15),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(displayIcon, color: accentColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: AppTypography.labelMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (message != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                message,
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate()
                 .slideY(begin: -1.0, end: 0, curve: Curves.easeOutBack, duration: 600.ms)
                 .fadeIn(duration: 400.ms)
                 .shimmer(delay: 400.ms, duration: 1000.ms, color: Colors.white.withValues(alpha: 0.2)),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_currentEntry!);

    Future.delayed(duration, () {
      if (_currentEntry != null) {
        _currentEntry!.remove();
        _currentEntry = null;
        _isShowing = false;
      }
    });
  }
}
