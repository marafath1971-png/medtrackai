import 'package:flutter/material.dart';

import '../../../core/utils/haptic_engine.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared/shared_widgets.dart';
import '../../../widgets/viral/share_milestone_card.dart';

// ─────────────────────────────────────────────────────────────
// SHARE MILESTONE CTA — "Share your N-day streak" row, shown at
// streak ≥ 7. Extracted verbatim from home_tab.dart.
// ─────────────────────────────────────────────────────────────
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
    final gradColors = _getStreakGradient(streak, L);
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: L.border.withValues(alpha: 0.08), width: 1.0),
          boxShadow: AppShadows.neumorphic,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: L.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.share_rounded, size: 18, color: L.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔥 Share your $streak-day streak!',
                    style: AppTypography.titleMedium.copyWith(
                      color: L.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Inspire your followers on TikTok & Instagram',
                    style: AppTypography.bodySmall.copyWith(
                      color: L.sub.withValues(alpha: 0.55),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: gradColors[0].withValues(alpha: 0.7), size: 22),
          ],
        ),
      ),
    );
  }

  List<Color> _getStreakGradient(int streak, AppThemeColors L) {
    return [L.text, L.text.withValues(alpha: 0.7)];
  }
}
