import 'package:flutter/material.dart';

import '../../core/utils/haptic_engine.dart';
import '../../theme/med_ai_ui.dart';
import 'animated_pressable.dart';

/// Compact top strip for offline / network error states in [AppShell].
class AppStatusBanner extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color accent;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final String? retryLabel;

  const AppStatusBanner({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.accent,
    this.onRetry,
    this.onDismiss,
    this.retryLabel,
  });

  factory AppStatusBanner.offline({
    Key? key,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    return AppStatusBanner(
      key: key,
      title: 'You’re offline',
      message: 'Changes stay on this device until you’re back online.',
      icon: Icons.wifi_off_rounded,
      accent: AppColors.warningSoft,
      onRetry: onRetry,
      onDismiss: onDismiss,
      retryLabel: 'Retry',
    );
  }

  factory AppStatusBanner.error({
    Key? key,
    required String message,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    return AppStatusBanner(
      key: key,
      title: 'Connection issue',
      message: message,
      icon: Icons.error_outline_rounded,
      accent: AppColors.red,
      onRetry: onRetry,
      onDismiss: onDismiss,
      retryLabel: 'Retry',
    );
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Semantics(
      liveRegion: true,
      label: '$title. $message',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.p16,
          0,
          AppSpacing.p16,
          AppSpacing.p8,
        ),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.p12,
              vertical: AppSpacing.p12,
            ),
            decoration: BoxDecoration(
              color: L.card,
              borderRadius: BorderRadius.circular(AppRadius.l),
              border: Border.all(color: accent.withValues(alpha: 0.28)),
              boxShadow: AppShadows.soft,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.badgeFill(accent),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: accent),
                ),
                const SizedBox(width: AppSpacing.p12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTypography.labelLarge.copyWith(
                          color: L.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: L.sub,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(width: AppSpacing.p8),
                  AnimatedPressable(
                    onTap: () {
                      HapticEngine.selection();
                      onRetry!();
                    },
                    child: Text(
                      retryLabel ?? 'Retry',
                      style: AppTypography.labelMedium.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
                if (onDismiss != null) ...[
                  const SizedBox(width: AppSpacing.p4),
                  Semantics(
                    button: true,
                    label: 'Dismiss',
                    child: AnimatedPressable(
                      onTap: () {
                        HapticEngine.selection();
                        onDismiss!();
                      },
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: L.sub.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
