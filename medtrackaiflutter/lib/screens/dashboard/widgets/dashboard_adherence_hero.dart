import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/premium_texture.dart';

/// Apple Health–style adherence ring hero for Trends tab.
class DashboardAdherenceHero extends StatefulWidget {
  final List<Map<String, dynamic>> trendData;
  final double adherence;

  const DashboardAdherenceHero({
    super.key,
    required this.trendData,
    required this.adherence,
  });

  @override
  State<DashboardAdherenceHero> createState() => _DashboardAdherenceHeroState();
}

class _DashboardAdherenceHeroState extends State<DashboardAdherenceHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    final target = widget.adherence.clamp(0.0, 1.0);
    _c = AnimationController(
      vsync: this,
      duration: AppDurations.hero,
    );
    _a = Tween<double>(begin: 0, end: target).animate(
      CurvedAnimation(parent: _c, curve: AppCurves.emilOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      MedAiA11y.reducedMotion(context) ? _c.value = 1.0 : _c.forward();
    });
  }

  @override
  void didUpdateWidget(covariant DashboardAdherenceHero old) {
    super.didUpdateWidget(old);
    if (old.adherence != widget.adherence) {
      final target = widget.adherence.clamp(0.0, 1.0);
      _a = Tween<double>(begin: _a.value, end: target).animate(
        CurvedAnimation(parent: _c, curve: AppCurves.emilOut),
      );
      MedAiA11y.reducedMotion(context) ? _c.value = 1.0 : _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static const _dow = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final pct = (widget.adherence * 100).round();
    final week = widget.trendData.length >= 7
        ? widget.trendData.sublist(widget.trendData.length - 7)
        : widget.trendData;
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    String statusLabel;
    if (week.isEmpty || pct == 0) {
      statusLabel = 'Start logging';
    } else if (pct >= 80) {
      statusLabel = 'Excellent';
    } else if (pct >= 60) {
      statusLabel = 'On track';
    } else {
      statusLabel = 'Room to grow';
    }

    return PremiumTextureCard(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.p16, AppSpacing.gutter, AppSpacing.p16, AppSpacing.p20),
      radius: 28,
      texture: PremiumTextureStyle.fineGrain,
      child: Semantics(
        label: "Today's adherence $pct percent, $statusLabel",
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's adherence",
            style: AppTypography.labelMedium.copyWith(
              color: L.sub,
              fontWeight: FontWeight.w600
            ),
          ),
          const SizedBox(height: AppSpacing.p16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$pct',
                          style: AppTypography.displayMedium.copyWith(
                            color: L.text,
                            fontWeight: FontWeight.w800,
                            fontSize: 48,
                            letterSpacing: -2,
                            height: 1,
                          ),
                        ),
                        Text(
                          '%',
                          style: AppTypography.titleLarge.copyWith(
                            color: L.sub,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.p8),
                    Text(
                      statusLabel,
                      style: AppTypography.labelLarge.copyWith(
                        color: pct >= 80
                            ? AppColors.limeDeep
                            : L.sub,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.p4),
                    Text(
                      '7-day trend below',
                      style: AppTypography.bodySmall.copyWith(
                        color: L.sub.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: _a,
                builder: (context, _) {
                  return SizedBox(
                    width: 112,
                    height: 112,
                    child: CustomPaint(
                      painter: _TrendRingPainter(
                        _a.value.clamp(0.0, 1.0),
                        trackColor: L.fill.withValues(alpha: 0.65),
                        progressColor: AppColors.limeDeep,
                      ),
                      child: const Center(
                        child: ExcludeSemantics(
                          child: Icon(
                            Icons.show_chart_rounded,
                            size: 28,
                            color: AppColors.limeDeep,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          if (week.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.p24),
            SizedBox(
              height: 56,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(week.length, (i) {
                  final day = week[i];
                  final val = (day['value'] as num?)?.toDouble() ?? 0.0;
                  final dateStr = day['date'] as String? ?? '';
                  final isToday = dateStr == todayKey;
                  final date = DateTime.tryParse(dateStr);

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(end: i < week.length - 1 ? 4 : 0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor:
                                    val <= 0 ? 0.04 : val.clamp(0.04, 1.0),
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: isToday
                                        ? AppColors.limeDeep
                                        : AppColors.lime
                                            .withValues(alpha: 0.35 + val * 0.4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.p8),
                          Text(
                            date != null
                                ? _dow[(date.weekday - 1) % 7]
                                : _dow[i % 7],
                            style: AppTypography.labelSmall.copyWith(
                              color: isToday
                                  ? AppColors.limeDeep
                                  : L.sub.withValues(alpha: 0.5),
                              fontWeight:
                                  isToday ? FontWeight.w800 : FontWeight.w600
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
        ],
      ),
      ),
    );
  }
}

class _TrendRingPainter extends CustomPainter {
  final double fraction;
  final Color trackColor;
  final Color progressColor;

  _TrendRingPainter(
    this.fraction, {
    required this.trackColor,
    required this.progressColor,
  });

  /// Minimum painted fraction so low values (e.g. 7%) read as an arc,
  /// not two round caps merged into a floating blob. Number labeling
  /// still uses the real [fraction] outside this painter.
  static const double _minVisibleFraction = 0.04;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const stroke = 11.0;
    final radius = (size.shortestSide / 2) - stroke;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Full track — light gray ring (no round-cap ends; it's a closed circle).
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    if (fraction <= 0) return;

    // Arc length floor so round caps don't collapse into a "dot".
    // Also never shorter than ~stroke chord length on this radius.
    final capFloor = stroke / (2 * math.pi * radius);
    final painted = math.max(
      fraction,
      math.max(_minVisibleFraction, capFloor),
    );

    canvas.drawArc(
      rect,
      -math.pi / 2, // 12 o'clock
      2 * math.pi * painted.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TrendRingPainter old) =>
      old.fraction != fraction ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor;
}
