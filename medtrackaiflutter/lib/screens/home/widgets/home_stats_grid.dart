import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/app_state.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app_routes.dart';
import '../../../core/utils/haptic_engine.dart';

class HomeStatsGrid extends StatelessWidget {
  final AppState state;
  final List<DoseItem> doses;
  final int takenCount;
  final int remaining;
  final double dosePct;
  final Color ringCol;

  const HomeStatsGrid({
    super.key,
    required this.state,
    required this.doses,
    required this.takenCount,
    required this.remaining,
    required this.dosePct,
    required this.ringCol,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final reduceMotion = MedAiA11y.reducedMotion(context);
    final adherence = (state.getAdherenceScore() * 100).round();
    final streak = state.getStreak();
    final now = DateTime.now();
    final nowM = now.hour * 60 + now.minute;
    final takenToday = state.takenToday;
    final upcoming = doses.where((d) {
      final schedM = d.sched.h * 60 + d.sched.m;
      return !(takenToday[d.key] ?? false) && schedM >= nowM;
    }).toList()
      ..sort((a, b) =>
          (a.sched.h * 60 + a.sched.m).compareTo(b.sched.h * 60 + b.sched.m));
    final nextDose = upcoming.isNotEmpty ? upcoming.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── TOP ROW: Main Progress + Adherence ──
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main Progress Card (Bento Style)
              Expanded(
                flex: 6,
                child: _entrance(
                  reduceMotion,
                  _BentoMetricCard(
                    emoji: '📈',
                    iconColor: L.primary,
                    label: 'Daily Progress',
                    value: '${(dosePct * 100).round()}%',
                    unit: 'complete',
                    sublabel: '$takenCount of ${doses.length} doses taken',
                    sparklineData: _buildWeeklyData(state),
                    sparklineColor: L.primary,
                    L: L,
                    reduceMotion: reduceMotion,
                    onTap: () {
                      context.push(AppRoutes.statsAnalytics);
                    },
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.p12),
              // Secondary Stats Stacked
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    Expanded(
                      child: _entrance(
                        reduceMotion,
                        _BentoSmallCard(
                          emoji: streak > 0 ? '⚡' : '🛡️',
                          label: 'Streak',
                          value: '$streak days',
                          valueColor: L.warning,
                          L: L,
                          reduceMotion: reduceMotion,
                        ),
                        delay: 100.ms,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.p12),
                    Expanded(
                      child: _entrance(
                        reduceMotion,
                        _BentoSmallCard(
                          emoji: '📈',
                          label: 'Adherence',
                          value: '$adherence%',
                          valueColor: L.success,
                          L: L,
                          reduceMotion: reduceMotion,
                          onTap: () {
                            context.push(AppRoutes.statsAnalytics);
                          },
                        ),
                        delay: 200.ms,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.p12),

        // ── MIDDLE ROW: Next Dose (Full Width Premium) ──
        if (nextDose != null)
          _entrance(
            reduceMotion,
            _NextDoseCard(dose: nextDose, nowM: nowM, L: L, reduceMotion: reduceMotion),
            delay: 300.ms,
          ),

        const SizedBox(height: AppSpacing.p12),

        // ── BOTTOM ROW: BP + Mood ──
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _entrance(
                  reduceMotion,
                  _BentoMetricCard(
                    emoji: '📦',
                    iconColor: AppColors.dangerSoft,
                    label: 'Inventory',
                    value: '${state.getLowStockCount()}',
                    unit: 'low',
                    sublabel: state.getLowStockCount() == 0
                        ? 'Stocks healthy'
                        : '${state.getLowStockCount()} refill needed',
                    sparklineData: _buildStockData(state),
                    sparklineColor: AppColors.dangerSoft,
                    L: L,
                    reduceMotion: reduceMotion,
                  ),
                  delay: 400.ms,
                ),
              ),
              const SizedBox(width: AppSpacing.p12),
              Expanded(
                child: _entrance(
                  reduceMotion,
                  _BentoMetricCard(
                    emoji: '✨',
                    iconColor: AppColors.warningSoft,
                    label: 'Mood',
                    value: state.getMoodSummary(
                      good: 'Good',
                      stable: 'Stable',
                      severe: 'Severe',
                      empty: '-',
                    )['value']!,
                    unit: state.getMoodSummary(
                      good: 'Good',
                      stable: 'Stable',
                      severe: 'Severe',
                      empty: '-',
                    )['unit']!,
                    sublabel: state.getMoodSummary(
                      good: 'Good',
                      stable: 'Stable',
                      severe: 'Severe',
                      empty: 'No logs',
                    )['sublabel']!,
                    sparklineData: state.getRecentSymptomStats(),
                    sparklineColor: AppColors.warningSoft,
                    L: L,
                    reduceMotion: reduceMotion,
                  ),
                  delay: 500.ms,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<double> _buildWeeklyData(AppState state) {
    return List.generate(7, (i) {
      final d = DateTime.now().subtract(Duration(days: 6 - i));
      final k = d.toIso8601String().substring(0, 10);
      final ds = state.history[k] ?? [];
      if (ds.isEmpty) return 0.0;
      return ds.where((x) => x.taken).length / ds.length;
    });
  }

  List<double> _buildStockData(AppState state) {
    return state.inventoryHistory;
  }

  static Widget _entrance(bool reduceMotion, Widget child, {Duration? delay}) {
    if (reduceMotion) return child;
    return child
        .animate(delay: delay)
        .fadeIn(duration: AppDurations.fast, curve: AppCurves.smooth)
        .slideY(begin: 0.08, end: 0, curve: AppCurves.smooth);
  }
}

// ─────────────────────────────────────────────────────────────
// BENTO METRIC CARD — with sparkline
// ─────────────────────────────────────────────────────────────
class _BentoMetricCard extends StatelessWidget {
  final String emoji;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;
  final String sublabel;
  final List<double> sparklineData;
  final Color sparklineColor;
  final AppThemeColors L;
  final bool reduceMotion;

  const _BentoMetricCard({
    required this.emoji,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
    required this.sublabel,
    required this.sparklineData,
    required this.sparklineColor,
    required this.L,
    this.onTap,
    this.reduceMotion = false,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconData = _mapMetricIcon(emoji);
    Widget sparkline = SizedBox(
      height: AppSpacing.p32,
      child: CustomPaint(
        size: const Size(double.infinity, 32),
        painter: _SparklinePainter(
          data: sparklineData,
          color: sparklineColor,
        ),
      ),
    );

    return Semantics(
      button: onTap != null,
      label: onTap != null ? '$label, $value $unit' : null,
      child: MedAiDepthCard(
        padding: const EdgeInsets.all(AppSpacing.p16),
        radius: AppRadius.squircle,
        onTap: onTap != null
            ? () {
                HapticEngine.selection();
                onTap!();
              }
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.badgeFill(iconColor),
                    borderRadius: BorderRadius.circular(AppRadius.s),
                  ),
                  child: Center(
                    child: Icon(
                      iconData,
                      size: 14,
                      color: iconColor,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.p8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      color: L.sub,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.p12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: AppTypography.displaySmall.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.0,
                    height: 1.0,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.p4),
                  Text(
                    unit,
                    style: AppTypography.labelSmall.copyWith(
                      color: L.sub.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.p4),
            Text(
              sublabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                color: L.sub.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.p16),
            sparkline,
          ],
        ),
      ),
    );
  }

  IconData _mapMetricIcon(String token) {
    return switch (token) {
      '📈' => Icons.insights_rounded,
      '📦' => Icons.inventory_2_rounded,
      '✨' => Icons.mood_rounded,
      _ => Icons.auto_awesome_rounded,
    };
  }
}

// ─────────────────────────────────────────────────────────────
// BENTO SMALL CARD
// ─────────────────────────────────────────────────────────────
class _BentoSmallCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color valueColor;
  final AppThemeColors L;
  final bool reduceMotion;

  const _BentoSmallCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.L,
    this.onTap,
    this.reduceMotion = false,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconData = _mapSmallIcon(emoji);
    final emojiWidget = Icon(iconData, size: 22, color: valueColor);

    return Semantics(
      button: onTap != null,
      label: '$label, $value',
      child: MedAiDepthCard(
        padding: const EdgeInsets.all(AppSpacing.p12),
        radius: AppRadius.squircle,
        onTap: onTap != null
            ? () {
                HapticEngine.selection();
                onTap!();
              }
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            emojiWidget,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTypography.titleLarge.copyWith(
                    color: valueColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: L.sub,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _mapSmallIcon(String token) {
    return switch (token) {
      '⚡' => Icons.bolt_rounded,
      '🛡️' => Icons.shield_outlined,
      '📈' => Icons.show_chart_rounded,
      _ => Icons.insights_rounded,
    };
  }
}

// ─────────────────────────────────────────────────────────────
// NEXT DOSE BANNER
// ─────────────────────────────────────────────────────────────
class _NextDoseCard extends StatelessWidget {
  final DoseItem dose;
  final int nowM;
  final AppThemeColors L;
  final bool reduceMotion;

  const _NextDoseCard({
    required this.dose,
    required this.nowM,
    required this.L,
    this.reduceMotion = false,
  });

  @override
  Widget build(BuildContext context) {
    final schedMin = dose.sched.h * 60 + dose.sched.m;
    final diff = schedMin - nowM;
    final timeLabel = diff <= 60
        ? 'in $diff min'
        : 'at ${dose.sched.h}:${dose.sched.m.toString().padLeft(2, '0')}';
    final doseEmoji = diff <= 15 ? '⚡' : (diff <= 60 ? '⏱️' : '🛡️');
    final emojiInner = Text(doseEmoji, style: const TextStyle(fontSize: 26));

    return Semantics(
      label: 'Next dose: ${dose.med.name}, $timeLabel',
      child: MedAiDepthCard(
        color: Colors.black,
        padding: const EdgeInsets.all(AppSpacing.p16),
        radius: AppRadius.squircle,
        accentGlow: !reduceMotion,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: L.onPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.m),
              ),
              child: Center(child: emojiInner),
            ),
            const SizedBox(width: AppSpacing.p16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next dose',
                    style: AppTypography.labelSmall.copyWith(
                      color: L.onPrimary.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                  Text(
                    dose.med.name,
                    style: AppTypography.headlineSmall.copyWith(
                      color: L.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.p12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16, vertical: AppSpacing.p12),
              decoration: BoxDecoration(
                color: L.onPrimary,
                borderRadius: BorderRadius.circular(AppRadius.max),
              ),
              child: Text(
                timeLabel,
                style: AppTypography.labelMedium.copyWith(
                  color: L.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SPARKLINE PAINTER
// ─────────────────────────────────────────────────────────────
class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final w = size.width / (data.length - 1);
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = i * w;
      final y = size.height - (data[i].clamp(0, 1) * (size.height - 8) + 4);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final prevX = (i - 1) * w;
        final prevY =
            size.height - (data[i - 1].clamp(0, 1) * (size.height - 8) + 4);
        final cpX = (prevX + x) / 2;
        path.cubicTo(cpX, prevY, cpX, y, x, y);
        fillPath.cubicTo(cpX, prevY, cpX, y, x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Terminal point glow
    final lastX = size.width;
    final lastY = size.height - (data.last.clamp(0, 1) * (size.height - 8) + 4);
    canvas.drawCircle(Offset(lastX, lastY), 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.data != data || old.color != color;
}

// ─────────────────────────────────────────────────────────────
// SHARED HEADER ACTION BTN
// ─────────────────────────────────────────────────────────────
class HeaderActionBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final String? semanticsLabel;

  const HeaderActionBtn({
    super.key,
    required this.child,
    required this.onTap,
    this.backgroundColor,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: AnimatedPressable(
        onTap: () {
          HapticEngine.selection();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: MedAiA11y.minTapTarget,
          height: MedAiA11y.minTapTarget,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.max),
            boxShadow: AppShadows.soft,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
