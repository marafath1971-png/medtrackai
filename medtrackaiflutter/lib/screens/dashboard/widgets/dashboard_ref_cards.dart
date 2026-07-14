import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: MedAiGlass(
        radius: 999,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.pastelMint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.medication_rounded,
                size: 18,
                color: AppColors.limeInk,
              ),
            ),
            const SizedBox(width: 12),
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
            Icon(
              Icons.chevron_right_rounded,
              color: L.sub.withValues(alpha: 0.45),
              size: 20,
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
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
      child: MedAiGlass(
        radius: 28,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
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
                _SemiGauge(value: adherence),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$pct%',
              style: AppTypography.displaySmall.copyWith(
                color: L.text,
                fontWeight: FontWeight.w800,
                fontSize: 34,
                letterSpacing: -1,
                height: 1,
              ),
            ),
            const SizedBox(height: 16),
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
                        padding:
                            EdgeInsets.only(right: i < week.length - 1 ? 5 : 0),
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
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: isToday
                                            ? const [
                                                Color(0xFFFFB8D9),
                                                Color(0xFFE894C8),
                                              ]
                                            : [
                                                const Color(0xFFFFD6E8)
                                                    .withValues(alpha: 0.55),
                                                const Color(0xFFE8C4F0)
                                                    .withValues(alpha: 0.45),
                                              ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              dowLabel.substring(0, 1),
                              style: AppTypography.labelSmall.copyWith(
                                color: isToday
                                    ? L.text
                                    : L.sub.withValues(alpha: 0.55),
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _HealthParamLarge(
                  title: 'Day streak',
                  value: '$streak',
                  unit: 'days',
                  accent: const [Color(0xFFFFC8A8), Color(0xFFFF9F7A)],
                  child: _PulseSparkline(color: const Color(0xFFFF8A65)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HealthParamLarge(
                  title: 'Heart rate',
                  value: healthConnected ? '${heartRate.toInt()}' : '--',
                  unit: 'BPM',
                  accent: const [Color(0xFFFFB8D4), Color(0xFFFF8CB8)],
                  child: _HeartWaveform(
                    active: healthConnected,
                    bpm: heartRate,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _HealthParamSmall(
                  title: 'Doses this week',
                  value: '$dosesWeek',
                  unit: dosesWeek == 1 ? 'dose' : 'doses',
                  tint: AppColors.pastelSky,
                  icon: Icons.medication_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HealthParamSmall(
                  title: 'Steps today',
                  value: healthConnected ? '${steps.toInt()}' : '--',
                  unit: 'steps',
                  tint: AppColors.pastelMint,
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
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
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
                  fontSize: 13,
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

  const _SemiGauge({required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 32,
      child: CustomPaint(
        painter: _SemiGaugePainter(value.clamp(0.0, 1.0)),
      ),
    );
  }
}

class _SemiGaugePainter extends CustomPainter {
  final double value;

  _SemiGaugePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 4;
    const start = math.pi;
    const sweep = math.pi;

    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      track,
    );

    final fill = Paint()
      ..shader = const SweepGradient(
        colors: [Color(0xFFFFB8D9), Color(0xFFB8A0FF), Color(0xFFFFC8A0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep * value,
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _SemiGaugePainter old) => old.value != value;
}

class _HealthParamLarge extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final List<Color> accent;
  final Widget child;

  const _HealthParamLarge({
    required this.title,
    required this.value,
    required this.unit,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return MedAiGlass(
      radius: 24,
      padding: const EdgeInsets.all(14),
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
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: AppTypography.headlineMedium.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 4),
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
  final Color tint;
  final IconData icon;

  const _HealthParamSmall({
    required this.title,
    required this.value,
    required this.unit,
    required this.tint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return MedAiGlass(
      radius: 22,
      padding: const EdgeInsets.all(14),
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
                  color: tint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: L.text.withValues(alpha: 0.7)),
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
                  style: AppTypography.titleLarge.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: AppTypography.labelSmall.copyWith(
                  color: L.sub,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
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

  const _HeartWaveform({required this.active, required this.bpm});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HeartWavePainter(
        active: active,
        phase: active ? bpm / 120 : 0,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _HeartWavePainter extends CustomPainter {
  final bool active;
  final double phase;

  _HeartWavePainter({required this.active, required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = active ? const Color(0xFFFF6B9D) : Colors.white.withValues(alpha: 0.35)
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
      old.active != active || old.phase != phase;
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
