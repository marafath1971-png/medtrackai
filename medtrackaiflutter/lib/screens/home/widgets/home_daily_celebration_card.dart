import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/utils/haptic_engine.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';

/// A celebratory card displayed on the Home screen when a user completes
/// all scheduled doses for the day (100% daily adherence).
///
/// Designed like Duolingo / Cal AI milestone rewards to provide instant
/// positive reinforcement, habit dopamine, and viral sharing.
class HomeDailyCelebrationCard extends StatelessWidget {
  final int takenCount;
  final int totalDoses;
  final int streak;
  final VoidCallback? onShare;

  const HomeDailyCelebrationCard({
    super.key,
    required this.takenCount,
    required this.totalDoses,
    required this.streak,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final reduceMotion = MedAiA11y.reducedMotion(context);

    final bgGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF142E1F), Color(0xFF0C1D13)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEDFBF0), Color(0xFFDCF7E2)],
          );

    final borderColor = isDark
        ? AppColors.lime.withValues(alpha: 0.3)
        : AppColors.limeDeep.withValues(alpha: 0.25);

    final textColor = isDark ? Colors.white : AppColors.inkStrong;
    final subColor = isDark ? Colors.white70 : AppColors.grey700;

    final content = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.p20,
        vertical: AppSpacing.p16,
      ),
      decoration: BoxDecoration(
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.limeDeep.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.lime.withValues(alpha: 0.2)
                      : AppColors.lime.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppRadius.max),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.celebration_rounded,
                      size: 13,
                      color: AppColors.limeDeep,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'PERFECT DAY',
                      style: AppTypography.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.limeInk,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (streak > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2E2211)
                        : const Color(0xFFFFF2DC),
                    borderRadius: BorderRadius.circular(AppRadius.max),
                    border: Border.all(
                      color: const Color(0xFFFF9500).withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '🔥',
                        style: TextStyle(fontSize: 11),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$streak day streak',
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.p12),
          Text(
            'All Doses Done for Today! 🎉',
            style: AppTypography.titleLarge.copyWith(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.4,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'You completed all $takenCount of $totalDoses scheduled doses on time. Your consistency is paying off!',
            style: AppTypography.bodySmall.copyWith(
              color: subColor,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          if (onShare != null) ...[
            const SizedBox(height: AppSpacing.p12),
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedPressable(
                onTap: () {
                  HapticEngine.selection();
                  onShare!();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.limeDeep : AppColors.lime,
                    borderRadius: BorderRadius.circular(AppRadius.m),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.limeDeep.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.ios_share_rounded,
                        size: 14,
                        color: isDark ? Colors.white : AppColors.limeInk,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Share Today's Win",
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.limeInk,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (reduceMotion) return content;
    return content.animate().fadeIn(duration: 350.ms).slideY(
          begin: 0.05,
          end: 0,
          curve: AppCurves.emilOut,
        );
  }
}
