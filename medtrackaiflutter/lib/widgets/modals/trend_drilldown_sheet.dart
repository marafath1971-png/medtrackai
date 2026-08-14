import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/app_state.dart';
import '../../theme/med_ai_ui.dart';
import '../../core/utils/haptic_engine.dart';
import '../common/refined_sheet_wrapper.dart';
import 'daily_log_sheet.dart';

class TrendDrilldownSheet extends StatelessWidget {
  final AppState state;
  final AppThemeColors L;

  const TrendDrilldownSheet({super.key, required this.state, required this.L});

  Widget _entrance(BuildContext context, Widget child, {Duration? delay}) {
    if (MedAiA11y.reducedMotion(context)) return child;
    return child
        .animate(delay: delay)
        .fadeIn(duration: AppDurations.fast)
        .slideY(begin: 0.08, end: 0, curve: AppCurves.smooth);
  }

  @override
  Widget build(BuildContext context) {
    final trendData = state.getTrendData();
    final avgAdherence = state.getAdherenceScore();
    final reduceMotion = MedAiA11y.reducedMotion(context);

    return RefinedSheetWrapper(
      title: 'Health Trends',
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('30-DAY PERFORMANCE',
                  style: AppTypography.labelSmall.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: L.sub,
                      letterSpacing: 1.2)),
              MedAiGlass(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                radius: AppRadius.xl,
                child: Text('${(avgAdherence * 100).round()}% AVG',
                    style: AppTypography.labelMedium.copyWith(
                        color: L.green,
                        fontSize: 13,
                        fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Semantics(
            label: '30 day adherence chart',
            child: SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: trendData.asMap().entries.map((entry) {
                  final i = entry.key;
                  final d = entry.value;
                  final value = d['value'] as double;
                  final height = (value * 140).clamp(6.0, 140.0);
                  final barColor = value >= 0.8
                      ? L.green
                      : (value > 0.4 ? L.amber : L.red);

                  Widget bar = Container(
                    width: double.infinity,
                    height: height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          barColor,
                          barColor.withValues(alpha: 0.6),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );

                  if (!reduceMotion) {
                    bar = bar.animate().scaleY(
                          begin: 0,
                          end: 1,
                          duration: 600.ms,
                          delay: (i * 20).ms,
                          curve: AppCurves.smooth,
                        );
                  }

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          bar,
                          if (i % 7 == 0 || i == trendData.length - 1) ...[
                            const SizedBox(height: 8),
                            Text(d['date'].toString().split('-')[2],
                                style: AppTypography.labelSmall.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: L.sub)),
                          ] else ...[
                            const SizedBox(height: 20),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _entrance(
            context,
            MedAiDepthCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          color: AppColors.limeDeep, size: 18),
                      const SizedBox(width: 10),
                      Text('PATIENT INSIGHT',
                          style: AppTypography.labelSmall.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppColors.limeDeep,
                              letterSpacing: 0.5)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    avgAdherence >= 0.9
                        ? 'Exceptional consistency! Your 30-day streak is helping stabilize your therapy efficacy. Keep maintaining this rhythmic intake.'
                        : avgAdherence >= 0.7
                            ? 'Stable progress detected. You\'ve been most consistent on weekdays. Try setting deeper reminders for weekends to hit 90%+.'
                            : 'Irregular patterns identified. Consistency is key for medication bioavailability. Consider using the Refill Alert to avoid gaps.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: L.text,
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            delay: 400.ms,
          ),
          const SizedBox(height: 32),
          _entrance(
            context,
            MedAiCTA(
              label: 'View Detailed Daily Log',
              icon: Icons.history_rounded,
              secondary: true,
              semanticsLabel: 'View detailed daily log',
              onTap: () {
                HapticEngine.selection();
                DailyLogSheet.show(context, date: DateTime.now());
              },
            ),
            delay: 500.ms,
          ),
        ],
      ),
    );
  }
}
