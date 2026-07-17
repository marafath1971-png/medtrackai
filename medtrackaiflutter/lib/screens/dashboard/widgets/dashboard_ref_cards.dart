import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../theme/med_ai_ui.dart';

class DashboardMedAlert extends StatelessWidget {
  final int pendingCount;

  const DashboardMedAlert({super.key, required this.pendingCount});

  @override
  Widget build(BuildContext context) {
    if (pendingCount <= 0) return const SizedBox.shrink();
    final L = context.L;
    final label = pendingCount == 1
        ? 'Time to take your medicine'
        : '$pendingCount doses waiting today';

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.p4, AppSpacing.gutter, 0),
      child: MedAiGlass(
        radius: 999,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16, vertical: AppSpacing.p12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: L.fill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.medication_rounded,
                size: 18,
                color: L.text.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(width: AppSpacing.p12),
            Expanded(
              child: Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  color: L.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            Transform.flip(
              flipX: Directionality.of(context) == TextDirection.rtl,
              child: Icon(
                Icons.chevron_right_rounded,
                color: L.sub.withValues(alpha: 0.45),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardGlassAdherenceCard extends StatelessWidget {
  final List<Map<String, dynamic>> trendData;
  final double adherence;

  const DashboardGlassAdherenceCard({
    super.key,
    required this.trendData,
    required this.adherence,
  });

  static const _dow = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final pct = (adherence * 100).round();
    final week = trendData.length >= 7
        ? trendData.sublist(trendData.length - 7)
        : trendData;
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dateLabel = DateFormat('d MMM yyyy').format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.p16, AppSpacing.gutter, 0),
      child: MedAiGlass(
        radius: 28,
        padding: const EdgeInsets.fromLTRB(AppSpacing.p16, AppSpacing.p16, AppSpacing.p16, AppSpacing.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Adherence',
                        style: AppTypography.labelMedium.copyWith(
                          color: L.sub,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateLabel,
                        style: AppTypography.bodySmall.copyWith(
                          color: L.sub.withValues(alpha: 0.75),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _SemiGauge(value: adherence, accent: L.accent, track: L.fill),
              ],
            ),
            const SizedBox(height: AppSpacing.p8),
            Text(
              '$pct%',
              style: AppTypography.displaySmall.copyWith(
                color: L.text,
                fontWeight: FontWeight.w800,
                fontSize: 36,
                letterSpacing: -1,
                height: 1,
              ),
            ),
            const SizedBox(height: AppSpacing.p16),
            if (week.isEmpty)
              Text(
                'Log doses to unlock your weekly trend',
                style: AppTypography.bodySmall.copyWith(color: L.sub),
              )
            else
              SizedBox(
                height: 72,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(week.length, (i) {
                    final day = week[i];
                    final val = (day['value'] as num?)?.toDouble() ?? 0.0;
                    final dateStr = day['date'] as String? ?? '';
                    final isToday = dateStr == todayKey;
                    final date = DateTime.tryParse(dateStr);
                    final dowLabel = date != null
                        ? _dow[(date.weekday - 1) % 7]
                        : _dow[i % 7];

                    return Expanded(
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(
                            end: i < week.length - 1 ? 5 : 0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  heightFactor:
                                      val <= 0 ? 0.12 : val.clamp(0.15, 1.0),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      color: isToday
                                          ? L.accent
                                          : L.fill.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.p8),
                            Text(
                              dowLabel.substring(0, 1),
                              style: AppTypography.labelSmall.copyWith(
                                color: isToday
                                    ? L.text
                                    : L.sub.withValues(alpha: 0.55),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DashboardHealthParamsGrid extends StatelessWidget {
  final int streak;
  final int dosesWeek;
  final double heartRate;
  final double steps;
  final bool healthConnected;

  const DashboardHealthParamsGrid({
    super.key,
    required this.streak,
    required this.dosesWeek,
    required this.heartRate,
    required this.steps,
    required this.healthConnected,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.p16, AppSpacing.gutter, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _HealthParamLarge(
                  title: 'Day streak',
                  value: '$streak',
                  unit: 'days',
                  child: _PulseSparkline(color: L.amber),
                ),
              ),
              const SizedBox(width: AppSpacing.p12),
              Expanded(
                child: _HealthParamLarge(
                  title: 'Heart rate',
                  value: healthConnected ? '${heartRate.toInt()}' : '--',
                  unit: 'BPM',
                  child: _HeartWaveform(
                    active: healthConnected,
                    bpm: heartRate,
                    color: L.accent,
                    muted: L.fill,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.p12),
          Row(
            children: [
              Expanded(
                child: _HealthParamSmall(
                  title: 'Doses this week',
                  value: '$dosesWeek',
                  unit: dosesWeek == 1 ? 'dose' : 'doses',
                  icon: Icons.medication_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.p12),
              Expanded(
                child: _HealthParamSmall(
                  title: 'Steps today',
                  value: healthConnected ? '${steps.toInt()}' : '--',
                  unit: 'steps',
                  icon: Icons.directions_walk_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DashboardSectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const DashboardSectionTitle({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.gutter, AppSpacing.gutter, AppSpacing.p12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                color: L.text,
                fontWeight: FontWeight.w800,
                fontSize: 17,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                action!,
                style: AppTypography.labelLarge.copyWith(
                  color: L.sub,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SemiGauge extends StatelessWidget {
  final double value;
  final Color accent;
  final Color track;

  const _SemiGauge({
    required this.value,
    required this.accent,
    required this.track,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 32,
      child: CustomPaint(
        painter: _SemiGaugePainter(
          value.clamp(0.0, 1.0),
          accent: accent,
          track: track,
        ),
      ),
    );
  }
}

class _SemiGaugePainter extends CustomPainter {
  final double value;
  final Color accent;
  final Color track;

  _SemiGaugePainter(this.value, {required this.accent, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 4;
    const start = math.pi;
    const sweep = math.pi;

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      trackPaint,
    );

    final fill = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    // Floor tiny values so round caps still read as an arc on the semicircle.
    final painted = value <= 0 ? 0.0 : math.max(value, 0.08);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep * painted,
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _SemiGaugePainter old) =>
      old.value != value || old.accent != accent || old.track != track;
}

class _HealthParamLarge extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final Widget child;

  const _HealthParamLarge({
    required this.title,
    required this.value,
    required this.unit,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return MedAiGlass(
      radius: 24,
      padding: const EdgeInsets.all(AppSpacing.p16),
      child: SizedBox(
        height: 148,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.labelMedium.copyWith(
                color: L.sub,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: AppSpacing.p4),
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
                const SizedBox(width: AppSpacing.p4),
                Text(
                  unit,
                  style: AppTypography.labelSmall.copyWith(
                    color: L.sub,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(height: 44, child: child),
          ],
        ),
      ),
    );
  }
}

class _HealthParamSmall extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;

  const _HealthParamSmall({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return MedAiGlass(
      radius: 22,
      padding: const EdgeInsets.all(AppSpacing.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    color: L.sub,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: L.fill,
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(icon, size: 16, color: L.text.withValues(alpha: 0.7)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.p12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleLarge.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.p4),
              Flexible(
                child: Text(
                  unit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    color: L.sub,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeartWaveform extends StatelessWidget {
  final bool active;
  final double bpm;
  final Color color;
  final Color muted;

  const _HeartWaveform({
    required this.active,
    required this.bpm,
    required this.color,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HeartWavePainter(
        active: active,
        phase: active ? bpm / 120 : 0,
        color: color,
        muted: muted,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _HeartWavePainter extends CustomPainter {
  final bool active;
  final double phase;
  final Color color;
  final Color muted;

  _HeartWavePainter({
    required this.active,
    required this.phase,
    required this.color,
    required this.muted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = active ? color : muted
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final midY = size.height * 0.55;
    path.moveTo(0, midY);
    for (var x = 0.0; x <= size.width; x += 2) {
      final t = (x / size.width) * math.pi * 4 + phase;
      final y = midY + math.sin(t) * 8 + math.sin(t * 2.3) * 4;
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeartWavePainter old) =>
      old.active != active ||
      old.phase != phase ||
      old.color != color ||
      old.muted != muted;
}

class _PulseSparkline extends StatelessWidget {
  final Color color;

  const _PulseSparkline({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(color: color),
      child: const SizedBox.expand(),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final Color color;

  _SparklinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final points = [0.2, 0.45, 0.3, 0.7, 0.55, 0.85, 0.65];
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = size.width * (i / (points.length - 1));
      final y = size.height * (1 - points[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) => old.color != color;
}
