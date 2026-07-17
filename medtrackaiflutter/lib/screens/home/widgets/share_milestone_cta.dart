import 'package:flutter/material.dart';

import '../../../core/utils/haptic_engine.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/hope_vibe.dart';
import '../../../widgets/shared/shared_widgets.dart';
import '../../../widgets/viral/share_milestone_card.dart';

/// Share milestone CTA — streak ≥ 7. Hopeful “inspire others / worth it” framing.
class ShareMilestoneCta extends StatelessWidget {
  final int streak;
  final double dosePct;
  final String userName;
  final int totalDosesTaken;
  const ShareMilestoneCta({
    super.key,
    required this.streak,
    this.dosePct = 0.0,
    this.userName = '',
    this.totalDosesTaken = 0,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return AnimatedPressable(
      onTap: () {
        HapticEngine.selection();
        ShareMilestoneCard.share(
          context,
          streak,
          adherencePct: dosePct,
          userName: userName,
          totalDosesTaken: totalDosesTaken,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.p16, vertical: AppSpacing.p12),
        decoration: HopeVibe.softCard(
          tint: AppColors.pastelSun,
          border: AppColors.limeDeep,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.p12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.share_rounded, size: 18, color: L.accent),
            ),
            const SizedBox(width: AppSpacing.p16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    HopeVibe.shareStreakTitle(streak),
                    style: AppTypography.titleMedium.copyWith(
                      color: L.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    HopeVibe.shareStreakSubtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: L.sub.withValues(alpha: 0.75),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: L.text.withValues(alpha: 0.45), size: 22),
          ],
        ),
      ),
    );
  }
}
