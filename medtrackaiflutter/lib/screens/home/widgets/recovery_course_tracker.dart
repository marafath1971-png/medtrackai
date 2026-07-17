import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../domain/entities/medicine.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../core/utils/color_utils.dart';

class RecoveryCourseTracker extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onTap;

  const RecoveryCourseTracker({
    super.key,
    required this.medicine,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final reduceMotion = MedAiA11y.reducedMotion(context);
    final day = medicine.currentCourseDay;
    final totalDays = medicine.courseDurationDays ?? 1;
    final pct = medicine.courseProgressPct;
    final baseColor = hexToColor(medicine.color);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.p8),
      child: _entrance(
        reduceMotion,
        Semantics(
          button: true,
          label:
              'Recovery course for ${medicine.name}, day $day of $totalDays',
          child: MedAiDepthCard(
          accentGlow: true,
          onTap: onTap,
          padding: const EdgeInsets.all(AppSpacing.p20),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (reduceMotion)
                      CircularProgressIndicator(
                        value: pct,
                        strokeWidth: 8,
                        backgroundColor: baseColor.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(baseColor),
                        strokeCap: StrokeCap.round,
                      )
                    else
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: pct),
                        duration: 1.5.seconds,
                        curve: Curves.easeOutExpo,
                        builder: (context, value, child) {
                          return CircularProgressIndicator(
                            value: value,
                            strokeWidth: 8,
                            backgroundColor: baseColor.withValues(alpha: 0.1),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(baseColor),
                            strokeCap: StrokeCap.round,
                          );
                        },
                      ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$day',
                          style: AppTypography.titleLarge.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: L.text,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          'of $totalDays',
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: L.sub,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.p20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.p8, vertical: AppSpacing.p4),
                      decoration: BoxDecoration(
                        color: L.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.s),
                      ),
                      child: Text(
                        'Short-term course',
                        style: AppTypography.labelSmall.copyWith(
                          color: L.red,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.p8),
                    Text(
                      medicine.name,
                      style: AppTypography.titleMedium.copyWith(
                        color: L.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.p4),
                    Text(
                      'Recovery mode active',
                      style: AppTypography.bodySmall.copyWith(
                        color: L.sub,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: MedAiA11y.minTapTargetCompact,
                height: MedAiA11y.minTapTargetCompact,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [baseColor, baseColor.withValues(alpha: 0.85)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: L.accentGlow(intensity: 0.2),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  static Widget _entrance(bool reduceMotion, Widget child) {
    if (reduceMotion) return child;
    return child
        .animate()
        .fadeIn(duration: AppDurations.fast, curve: AppCurves.smooth)
        .slideY(begin: 0.06, end: 0, curve: AppCurves.smooth);
  }
}
