import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/med_ai_ui.dart';

/// A week-over-week reading of adherence, with the 30-day shape behind it.
///
/// The Trends tab opened on two flat tiles — "Adherence 0% / All time" and
/// "Symptoms 0 / Total logs" — above a list of navigation cards. Nothing on it
/// trended: an all-time average says nothing about whether this week is better
/// than last, which is the only question a trends screen exists to answer, and
/// a 30-day series was already being computed and left unused.
///
/// This leads with the direction of travel and states the comparison in words,
/// because a sparkline alone is decoration unless the reader is told what it
/// means.
class TrendHero extends StatelessWidget {
  /// Daily adherence 0..1, oldest first. Typically 30 entries.
  final List<double> series;

  const TrendHero({super.key, required this.series});

  /// Mean of the most recent 7 days.
  double get thisWeek => _mean(series.length <= 7
      ? series
      : series.sublist(series.length - 7));

  /// Mean of the 7 days before those.
  double get lastWeek {
    if (series.length < 8) return 0;
    final end = series.length - 7;
    final start = math.max(0, end - 7);
    return _mean(series.sublist(start, end));
  }

  /// Percentage-point change, this week against last.
  int get deltaPoints => ((thisWeek - lastWeek) * 100).round();

  /// Whether there is enough history to compare two weeks at all.
  bool get hasComparison => series.length >= 8 && series.any((v) => v > 0);

  static double _mean(List<double> xs) =>
      xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final pct = (thisWeek * 100).round();
    final up = deltaPoints > 0;
    final flat = deltaPoints == 0;
    final accent = !hasComparison || flat
        ? AppColors.accentDeep
        : (up ? AppColors.accentDeep : const Color(0xFFB4494A));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.p20),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: L.border.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THIS WEEK',
            style: AppTypography.caption.copyWith(
              color: L.sub,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.p8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$pct%',
                style: AppTypography.displaySmall.copyWith(
                  color: L.text,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(width: AppSpacing.p8),
              if (hasComparison)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _DeltaChip(points: deltaPoints, accent: accent),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            // Said in words: a chip alone leaves the reader to work out what
            // "+8" is measured against.
            !hasComparison
                ? 'Keep logging doses — a week of history unlocks the comparison.'
                : flat
                    ? 'Holding steady against last week.'
                    : up
                        ? '$deltaPoints points better than last week.'
                        : '${deltaPoints.abs()} points below last week.',
            style: AppTypography.bodySmall.copyWith(color: L.sub, height: 1.4),
          ),
          if (series.length > 1) ...[
            const SizedBox(height: AppSpacing.p16),
            SizedBox(
              height: 56,
              child: CustomPaint(
                size: Size.infinite,
                painter: _SparklinePainter(
                  series: series,
                  color: accent,
                  fill: accent.withValues(alpha: 0.12),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${series.length} days ago',
                    style: AppTypography.caption.copyWith(color: L.sub)),
                Text('Today',
                    style: AppTypography.caption.copyWith(color: L.sub)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  final int points;
  final Color accent;

  const _DeltaChip({required this.points, required this.accent});

  @override
  Widget build(BuildContext context) {
    final up = points > 0;
    final flat = points == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.max),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            flat
                ? Icons.remove_rounded
                : up
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
            size: 13,
            color: accent,
          ),
          const SizedBox(width: 3),
          Text(
            flat ? 'same' : '${points.abs()} pts',
            style: AppTypography.labelSmall.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> series;
  final Color color;
  final Color fill;

  _SparklinePainter({
    required this.series,
    required this.color,
    required this.fill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (series.length < 2) return;

    // Always plot against a full 0..1 range. Scaling to the observed min/max
    // would make a flat 95% week look identical to a flat 20% one.
    final dx = size.width / (series.length - 1);
    final points = <Offset>[
      for (var i = 0; i < series.length; i++)
        Offset(i * dx, size.height - series[i].clamp(0.0, 1.0) * size.height),
    ];

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }

    final area = Path.from(line)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.drawPath(area, Paint()..color = fill);
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawCircle(points.last, 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.series != series || old.color != color;
}
