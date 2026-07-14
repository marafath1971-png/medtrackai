import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/common/premium_texture.dart';

/// Reference-style bento tile with premium grain texture.
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
      child: GestureDetector(
        onTap: onTap,
        child: PremiumTextureCard(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
          radius: 22,
          texture: PremiumTextureStyle.dots,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 104),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelMedium.copyWith(
                        color: L.sub.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tint,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      mappedIcon,
                      size: 16,
                      color: L.text.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headlineMedium.copyWith(
                        color: L.text,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        fontSize: 26,
                      ),
                    ),
                  ),
                  if (unit.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        unit,
                        style: AppTypography.labelMedium.copyWith(
                          color: L.sub.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
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
