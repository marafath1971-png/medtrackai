import 'package:flutter/material.dart';

import '../../core/utils/haptic_engine.dart';
import '../../services/share_service.dart';
import '../../theme/med_ai_ui.dart';
import 'animated_pressable.dart';

/// Always-on “recommend & share” surround — shown before and after pay
/// so users feel Med AI is worth recommending as their #1 companion.
class RecommendHopeCta extends StatelessWidget {
  final String? userName;

  const RecommendHopeCta({super.key, this.userName});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final name = (userName != null && userName!.trim().isNotEmpty)
        ? userName!.trim()
        : 'I';

    return AnimatedPressable(
      onTap: () {
        HapticEngine.selection();
        ShareService.shareText(
          '$name found ${HopeVibe.numberOneFeel}.\n'
          '${HopeVibe.tagline}\n\n'
          '${HopeVibe.shareInviteMessage}${ShareService.downloadUrl}',
          subject: 'Med AI — worth recommending',
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.p16),
        decoration: HopeVibe.softCard(
          tint: AppColors.pastelLilac,
          border: AppColors.accent,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(AppRadius.s),
              ),
              child: Icon(
                Icons.favorite_rounded,
                size: 22,
                color: AppColors.accentDeep,
              ),
            ),
            const SizedBox(width: AppSpacing.p12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    HopeVibe.recommendTitle,
                    style: AppTypography.titleMedium.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    HopeVibe.recommendSubtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: L.sub,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.p8),
            Icon(
              Icons.ios_share_rounded,
              size: 18,
              color: L.sub.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}
