import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/med_ai_ui.dart';

class WeeklyWellnessRing extends StatelessWidget {
  final double adherence;
  final List<double> dailyRates;

  const WeeklyWellnessRing({
    super.key,
    required this.adherence,
    required this.dailyRates,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final ringColor = _getColor(adherence, L);
    final reduceMotion = MedAiA11y.reducedMotion(context);

    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ringColor.withValues(alpha: 0.35),
                  blurRadius: 48,
                  spreadRadius: 8,
                )
              ],
            ),
          ),

          // Main Ring Painter
          _maybeAnimate(
            reduceMotion,
            CustomPaint(
              size: const Size(200, 200),
              painter: _WellnessRingPainter(
                adherence: adherence,
                dailyRates: dailyRates,
                color: ringColor,
                trackColor: L.border.withValues(alpha: 0.15),
              ),
            ),
            (w) => w
                .animate(key: const ValueKey('weekly_wellness_rotate_anim'))
                .rotate(duration: 800.ms, curve: Curves.easeOutCubic),
          ),

          // Center Text — theme-aware
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(adherence * 100).round()}%',
                style: AppTypography.displayMedium.copyWith(
                  fontWeight: FontWeight.w900,
                  color: L.text,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ADHERENCE',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: L.sub,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ).animate(key: const ValueKey('weekly_wellness_scale_anim')).scale(delay: 400.ms, duration: 600.ms, curve: Curves.easeOutBack),
        ],
      ),
    );
  }

  /// Applies [anim] only when reduced-motion is OFF; otherwise returns the
  /// static widget so the ring is fully usable without motion.
  Widget _maybeAnimate(
    bool reduceMotion,
    Widget child,
    Widget Function(Widget) anim,
  ) =>
      reduceMotion ? child : anim(child);

  /// Returns semantic adherence color from the design system:
  /// ≥80% → accent lime-green (#D4F544), ≥50% → orange accent, <50% → error red
  Color _getColor(double rate, AppThemeColors L) {
    if (rate >= 0.8) return const Color(0xFFD4F544); // high adherence — lime
    if (rate >= 0.5) return AppColors.accent;         // medium — orange brand accent
    return L.error;                                   // low — theme error red
  }
}

class _WellnessRingPainter extends CustomPainter {
  final double adherence;
  final List<double> dailyRates;
  final Color color;
  final Color trackColor;

  _WellnessRingPainter({
    required this.adherence,
    required this.dailyRates,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // 1. Draw Background Track — theme-aware
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // 2. Draw Daily Segments
    const segmentAngle = (2 * pi) / 7;
    const gap = 0.1;

    for (int i = 0; i < 7; i++) {
      final rate = i < dailyRates.length ? dailyRates[i] : 0.0;
      final startAngle = -pi / 2 + (i * segmentAngle) + (gap / 2);
      final sweepAngle = (segmentAngle - gap) * rate;

      if (rate > 0) {
        final segmentPaint = Paint()
          ..color = color.withValues(alpha: 0.3 + (rate * 0.7))
          ..strokeWidth = 12
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          false,
          segmentPaint,
        );
      }
    }

    // 3. Draw Overall Progress Ring (Thin outer ring)
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius + 10),
      -pi / 2,
      2 * pi * adherence,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WellnessRingPainter oldDelegate) =>
      oldDelegate.adherence != adherence ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor;
}
