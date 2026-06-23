import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../domain/entities/medicine.dart';
import '../../../theme/app_theme.dart';
import '../../../core/utils/color_utils.dart';
import '../../../widgets/shared/shared_widgets.dart';

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
    final day = medicine.currentCourseDay;
    final totalDays = medicine.courseDurationDays ?? 1;
    final pct = medicine.courseProgressPct;
    final baseColor = hexToColor(medicine.color);

    return BouncingButton(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: baseColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: baseColor.withValues(alpha: 0.15),
              blurRadius: 24,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Brain Fog Progress Ring
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: pct),
                    duration: 1.5.seconds,
                    curve: Curves.easeOutExpo,
                    builder: (context, value, child) {
                      return CircularProgressIndicator(
                        value: value,
                        strokeWidth: 8,
                        backgroundColor: baseColor.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(baseColor),
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
                          fontWeight: FontWeight.w900,
                          color: L.text,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        'OF $totalDays',
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: L.sub.withValues(alpha: 0.6),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            
            // Core Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: L.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'SHORT-TERM COURSE',
                      style: AppTypography.labelSmall.copyWith(
                        color: L.red,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
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
                  const SizedBox(height: 4),
                  Text(
                    'Recovery Mode Active',
                    style: AppTypography.bodySmall.copyWith(
                      color: L.sub,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            // Large Action Arrow (Low Cognitive Load)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: baseColor,
                shape: BoxShape.circle,
                boxShadow: AppShadows.glow(baseColor, intensity: 0.5),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
