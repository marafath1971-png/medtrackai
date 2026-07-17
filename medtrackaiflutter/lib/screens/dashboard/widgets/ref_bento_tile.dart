import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/common/animated_pressable.dart';
import '../../../widgets/common/premium_texture.dart';

/// Reference-style bento tile — content-hugging (no dead vertical space).
class RefBentoTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String emoji;
  final Color tint;
  final VoidCallback? onTap;

  const RefBentoTile({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.emoji,
    required this.tint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final mappedIcon = _mapEmojiIcon(emoji);
    return Semantics(
      button: onTap != null,
      label: '$label: $value $unit',
      child: AnimatedPressable(
        onTap: onTap,
        disabled: onTap == null,
        scaleFactor: 0.97,
        child: PremiumTextureCard(
          padding: const EdgeInsets.all(AppSpacing.p16),
          radius: AppRadius.l,
          texture: PremiumTextureStyle.dots,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: L.sub.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.p8),
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.badgeFill(tint),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      mappedIcon,
                      size: 16,
                      color: tint,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.p8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    flex: 3,
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headlineMedium.copyWith(
                        color: L.text,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  if (unit.isNotEmpty) ...[
                    const SizedBox(width: AppSpacing.p4),
                    Flexible(
                      flex: 2,
                      child: Text(
                        unit,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelLarge.copyWith(
                          color: L.sub.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _mapEmojiIcon(String token) {
    return switch (token) {
      '🔥' => Icons.local_fire_department_rounded,
      '💊' => Icons.medication_rounded,
      '📈' => Icons.show_chart_rounded,
      '👟' => Icons.directions_walk_rounded,
      '❤️' => Icons.favorite_rounded,
      '⏰' => Icons.schedule_rounded,
      _ => Icons.auto_awesome_rounded,
    };
  }
}
