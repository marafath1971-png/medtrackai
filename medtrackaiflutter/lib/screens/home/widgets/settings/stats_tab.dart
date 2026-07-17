import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../providers/app_state.dart';
import '../../../../theme/med_ai_ui.dart';
import '../../../../widgets/common/animated_pressable.dart';
import '../../../../widgets/common/premium_empty_state.dart';
import '../../../../core/utils/refill_helper.dart';
import 'settings_shared.dart';
import '../../../stats/widgets/weekly_wellness_ring.dart';
import '../../../stats/widgets/predictive_insight_card.dart';

class StatsTab extends StatelessWidget {
  final AppState state;
  final AppThemeColors L;

  const StatsTab({
    super.key,
    required this.state,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    // Select only what we need for bulk calculations if necessary,
    // but better to use cached getters if we added them.
    // We already have getStreak() and getAdherenceScore().

    final overallAdh =
        (context.select<AppState, double>((s) => s.getAdherenceScore()) * 100)
            .round();
    final streak = context.select<AppState, int>((s) => s.getStreak());

    // For the rest, we still need some history data.
    // Let's select the history keys to react to history changes.
    final historyKeys =
        context.select<AppState, List<String>>((s) => s.history.keys.toList());
    final daysTracked = historyKeys.length;

    // We still need the full history for the complex week and total counts.
    // To be truly granular, we should probably add getters to AppState for these too.
    // For now, let's select the whole history but at least we're using select.
    final history = context
        .select<AppState, Map<String, List<DoseEntry>>>((s) => s.history);

    final allEntries = history.values.expand((e) => e).toList();
    final taken = allEntries.where((e) => e.taken).length;
    final total = allEntries.length;

    // Last 7-day adherence
    final today = DateTime.now();
    final last7Keys = List.generate(
        7,
        (i) => today
            .subtract(Duration(days: i))
            .toIso8601String()
            .substring(0, 10));
    final last7Entries = last7Keys.expand((k) => history[k] ?? []).toList();
    final last7Adh = last7Entries.isNotEmpty
        ? (last7Entries.where((e) => e.taken).length *
            100 ~/
            last7Entries.length)
        : 0;

    final weekData = List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      final k = d.toIso8601String().substring(0, 10);
      final ds = history[k] ?? [];
      final rate =
          ds.isEmpty ? 0.0 : ds.where((x) => x.taken).length / ds.length;
      return {
        'day': ['S', 'M', 'T', 'W', 'T', 'F', 'S'][d.weekday % 7],
        'rate': rate
      };
    });

    final predictions = context.select<AppState, List<PredictiveInsight>>(
      (s) => s.wellness.predictions,
    );

    // Trigger analysis if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      state.wellness.analyzePredictivePatterns(state.history);
    });

    final dailyRates = weekData.map((w) => w['rate'] as double).toList();

    return SingleChildScrollView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.p4, 0, AppSpacing.p40),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p20),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.p24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.lime, AppColors.limeDeep],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.limeDeep.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Your success score',
                    style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.limeInk,
                        letterSpacing: -0.2)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.p8, vertical: AppSpacing.p4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    "On track",
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.limeInk,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.p20),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('$overallAdh%',
                  style: AppTypography.displayLarge.copyWith(
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      color: AppColors.limeInk,
                      letterSpacing: -2,
                      height: 0.9)),
              const SizedBox(width: AppSpacing.p12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.p8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                          overallAdh >= 80
                              ? 'Excellent'
                              : (overallAdh >= 60
                                  ? 'Stable'
                                  : 'Needs attention'),
                          style: AppTypography.labelLarge.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                              color: AppColors.limeInk.withValues(alpha: 0.85))),
                      const SizedBox(height: 2),
                      Text(
                        "Adherence",
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.limeInk.withValues(alpha: 0.65),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ]),
            const SizedBox(height: AppSpacing.p24),
            Stack(
              children: [
                Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: (overallAdh / 100.0).clamp(0.05, 1.0),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                        color: AppColors.limeInk,
                        borderRadius: BorderRadius.circular(99)),
                  ),
                ),
              ],
            ),
              ]),
        ),
        ),
        const SizedBox(height: AppSpacing.p24),

        // 🧠 AI PREDICTIVE INSIGHTS (Phase 5.0)
        if (predictions.isNotEmpty) ...[
          Text('Smart patterns',
              style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: L.text,
                  letterSpacing: -0.2)),
          const SizedBox(height: AppSpacing.p12),
          ...predictions.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.p12),
                child: PredictiveInsightCard(insight: p),
              )),
          const SizedBox(height: AppSpacing.p16),
        ],

        // 📊 WEEKLY WELLNESS RING (Phase 5.0)
        SettingsSection(
            title: 'Precision Overview',
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.p24),
              decoration: BoxDecoration(
                color: L.card,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: L.border.withValues(alpha: 0.1), width: 0.5),
                boxShadow: AppShadows.soft,
              ),
              child: Center(
                child: WeeklyWellnessRing(
                  adherence: overallAdh / 100.0,
                  dailyRates: dailyRates,
                ),
              ),
            )),
        const SizedBox(height: AppSpacing.p16),

        // Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.4,
          children: [
            SettingsStatCard(
                    label: 'Doses Taken',
                    val: '$taken',
                    sub: 'of $total total',
                    emoji: '✅',
                    L: L)
                .animate()
                .fade(delay: 100.ms)
                .slideY(begin: 0.2, end: 0),
            SettingsStatCard(
                    label: '7-Day Rate',
                    val: '$last7Adh%',
                    sub: 'Last 7 days',
                    emoji: '📈',
                    L: L)
                .animate()
                .fade(delay: 200.ms)
                .slideY(begin: 0.2, end: 0),
            SettingsStatCard(
                    label: 'Current Streak',
                    val: '${streak}d',
                    sub: 'days in a row',
                    emoji: '🔥',
                    L: L)
                .animate()
                .fade(delay: 300.ms)
                .slideY(begin: 0.2, end: 0),
            SettingsStatCard(
                    label: 'Days Tracked',
                    val: '$daysTracked',
                    sub: 'days of data',
                    emoji: '📅',
                    L: L)
                .animate()
                .fade(delay: 400.ms)
                .slideY(begin: 0.2, end: 0),
          ],
        ),
        const SizedBox(height: AppSpacing.p16),

        // Weekly Bar Chart
        SettingsSection(
            title: 'This Week',
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.p24),
              decoration: BoxDecoration(
                color: L.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: L.border.withValues(alpha: 0.08), width: 0.5),
                boxShadow: AppShadows.soft,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: weekData.map((w) {
                  final rate = w['rate'] as double;
                  return Expanded(
                    child: Column(children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: (rate * 60).clamp(8, 60),
                        decoration: BoxDecoration(
                            color: rate >= 0.8
                                ? AppColors.grey900
                                : (rate > 0 ? L.warning : L.fill),
                            borderRadius: BorderRadius.circular(6)),
                      ),
                      const SizedBox(height: AppSpacing.p8),
                      Text(w['day'] as String,
                          style: AppTypography.labelLarge.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: L.sub)),
                    ]),
                  );
                }).toList(),
              ),
            )),
        const SizedBox(height: AppSpacing.p16),

        // Symptom Trends (Phase 13: Live Integration)
        SettingsSection(
            title: 'Health Story',
            child: state.symptoms.isEmpty
                ? PremiumEmptyState(
                    compact: true,
                    title: 'No symptoms recorded',
                    subtitle: 'Log how you feel to build your health story.',
                    mascotFeature: 'calm',
                    icon: Icons.monitor_heart_outlined,
                  )
                : Column(
                    children: state.symptoms.reversed.take(5).map((s) {
                      final isHigh = s.severity >= 7;
                      final isLow = s.severity <= 3;
                      final color =
                          isHigh ? L.red : (isLow ? L.success : L.warning);

                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.p16),
                        decoration: BoxDecoration(
                          color: L.card,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppShadows.soft,
                          border: Border.all(
                              color: L.border.withValues(alpha: 0.08),
                              width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  shape: BoxShape.circle),
                              child: Center(
                                child: Text('${s.severity}',
                                    style: AppTypography.labelSmall.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: color)),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.p12),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.name,
                                        style: AppTypography.labelLarge
                                            .copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: L.text)),
                                    if (s.notes != null && s.notes!.isNotEmpty)
                                      Text(s.notes!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.labelSmall
                                              .copyWith(color: L.sub)),
                                  ]),
                            ),
                            const SizedBox(width: AppSpacing.p8),
                            Text(s.timestamp.toIso8601String().substring(5, 10),
                                style: AppTypography.labelSmall
                                    .copyWith(color: L.sub, fontSize: 10)),
                          ],
                        ),
                      );
                    }).toList(),
                  )),
        const SizedBox(height: AppSpacing.p16),

        // Inventory Forecast (Phase 14: Stock Integration)
        SettingsSection(
            title: 'Inventory Forecast',
            child: state.meds.isEmpty
                ? PremiumEmptyState(
                    compact: true,
                    title: 'No medications tracked',
                    subtitle:
                        'Add your first medicine to start building your daily precision log.',
                    mascotFeature: 'add_med',
                    icon: Icons.medication_rounded,
                  )
                : Column(
                    children: state.getRefillForecast().take(3).map((m) {
                      final isLow = RefillHelper.isCriticallyLow(m);
                      final status = RefillHelper.getExhaustionStatus(m);

                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.p16),
                        decoration: BoxDecoration(
                          color: L.card,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppShadows.soft,
                          border: Border.all(
                              color: L.border.withValues(alpha: 0.08),
                              width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                  color: isLow
                                      ? L.red.withValues(alpha: 0.1)
                                      : L.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Center(
                                child: Text(isLow ? '⚠️' : '✅',
                                    style: const TextStyle(fontSize: 14)),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.p12),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.name,
                                        style: AppTypography.labelLarge
                                            .copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: L.text)),
                                    Text(status,
                                        style: AppTypography.labelSmall
                                            .copyWith(
                                                color: isLow ? L.red : L.sub,
                                                fontWeight: isLow
                                                    ? FontWeight.w700
                                                    : FontWeight.w500)),
                                  ]),
                            ),
                            const SizedBox(width: AppSpacing.p12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text('${m.count}',
                                            style: AppTypography.labelLarge
                                                .copyWith(
                                                    fontWeight: FontWeight.w800,
                                                    color: L.text)),
                                        Text('left',
                                            style: AppTypography.labelSmall
                                                .copyWith(
                                                    color: L.sub,
                                                    fontSize: 10)),
                                      ],
                                    ),
                                    const SizedBox(width: AppSpacing.p16),
                                    Semantics(
                                      button: true,
                                      label: 'Refill ${m.name}',
                                      child: AnimatedPressable(
                                        onTap: () =>
                                            state.refillMedication(m.id),
                                        child: Container(
                                          constraints: const BoxConstraints(
                                              minHeight:
                                                  MedAiA11y.minTapTarget),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.p12, vertical: AppSpacing.p8),
                                          decoration: BoxDecoration(
                                            color:
                                                L.text.withValues(alpha: 0.05),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: L.text
                                                    .withValues(alpha: 0.1)),
                                          ),
                                          child: Text(
                                            'Refill',
                                            style: AppTypography.labelSmall
                                                .copyWith(
                                              color: L.text,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 10,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )),
        const SizedBox(height: 120),
      ]),
    );
  }
}
