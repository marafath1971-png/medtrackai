import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// Reference-style 2-up bento tile: pastel-tinted rounded card, a small
/// label with an emoji chip on the right, then a big value + unit on the
/// baseline (see reference "Step to walk 5,500 steps" cards).
///
/// Pure presentation — parents pass formatted strings + a pastel tint.
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
    return Semantics(
      button: onTap != null,
      label: '$label: $value $unit',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(minHeight: 104),
          decoration: BoxDecoration(
            color: L.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: L.border.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 16)),
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
}
