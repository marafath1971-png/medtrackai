import 'package:flutter/material.dart';

import '../../../theme/med_ai_ui.dart';

class ConfidenceMeter extends StatelessWidget {
  final double confidence;
  final bool onDark;

  const ConfidenceMeter({
    super.key,
    required this.confidence,
    this.onDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final reduceMotion = MedAiA11y.reducedMotion(context);
    final pct = (confidence * 100).toInt();

    final barColor = confidence > 0.8
        ? AppColors.sageGreen
        : (confidence > 0.5 ? AppColors.amber : AppColors.red);
    final labelColor =
        onDark ? Colors.white.withValues(alpha: 0.9) : L.text;
    final trackColor = onDark
        ? Colors.white.withValues(alpha: 0.2)
        : L.border.withValues(alpha: 0.4);

    final fillWidth = 200.0 * confidence.clamp(0.0, 1.0);

    return Semantics(
      label: 'AI confidence $pct percent',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, color: barColor, size: 14),
              const SizedBox(width: 6),
              Text(
                'Ai Confidence $pct%',
                style: AppTypography.labelMedium.copyWith(
                  color: labelColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: 200,
            height: 5,
            decoration: BoxDecoration(
              color: trackColor,
              borderRadius: BorderRadius.circular(3),
            ),
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: reduceMotion
                  ? Duration.zero
                  : MedAiA11y.motion(context, AppDurations.medium),
              curve: AppCurves.smooth,
              width: fillWidth,
              height: 5,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(3),
                boxShadow: confidence > 0.8 && !reduceMotion
                    ? AppShadows.glow(barColor, intensity: 0.25)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
