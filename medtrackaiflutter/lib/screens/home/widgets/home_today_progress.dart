import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/med_ai_ui.dart';

/// Compact today progress — one calm row, no hero glow.
class HomeTodayProgress extends StatelessWidget {
  final int taken;
  final int total;
  final VoidCallback? onTap;

  const HomeTodayProgress({
    super.key,
    required this.taken,
    required this.total,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final fraction = total == 0 ? 0.0 : (taken / total).clamp(0.0, 1.0);
    final allDone = total > 0 && taken >= total;
    final title = allDone
        ? 'All doses done'
        : total == 0
            ? 'No doses scheduled'
            : '$taken of $total doses taken';

    return Semantics(
      button: onTap != null,
      label: title,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: L.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: L.border.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CustomPaint(
                  painter: _RingPainter(
                    fraction: fraction,
                    track: L.fill,
                    progress: L.accent,
                  ),
                  child: Center(
                    child: Text(
                      allDone ? '✓' : '${(fraction * 100).round()}%',
                      style: AppTypography.labelLarge.copyWith(
                        color: L.text,
                        fontWeight: FontWeight.w800,
                        fontSize: allDone ? 18 : 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today',
                      style: AppTypography.labelSmall.copyWith(
                        color: L.sub,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: AppTypography.titleMedium.copyWith(
                        color: L.text,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right_rounded,
                    color: L.sub.withValues(alpha: 0.5), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  final Color track;
  final Color progress;

  _RingPainter({
    required this.fraction,
    required this.track,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    final stroke = 4.0;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    if (fraction > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * fraction,
        false,
        Paint()
          ..color = progress
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.fraction != fraction || old.progress != progress;
}
