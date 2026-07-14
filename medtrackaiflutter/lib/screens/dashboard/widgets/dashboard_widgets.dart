import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../../providers/app_state.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/premium_graphics.dart';
import '../../../widgets/common/premium_illustration_banner.dart';
import '../../../widgets/shared/shared_widgets.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/smoothing_text.dart';

// ══════════════════════════════════════════════════
// TIMELINE PILL SELECTOR — Animated Sliding Pill
// ══════════════════════════════════════════════════
class TimelinePillSelector extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final AppThemeColors L;
  final List<String> tabs;

  const TimelinePillSelector({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.L,
    required this.tabs,
  });

  @override
  State<TimelinePillSelector> createState() => _TimelinePillSelectorState();
}

class _TimelinePillSelectorState extends State<TimelinePillSelector> {
  @override
  Widget build(BuildContext context) {
    final L = widget.L;
    return SingleChildScrollView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: L.border.withValues(alpha: context.isDark ? 0.2 : 0.5),
          ),
        ),
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.tabs.length, (index) {
                final isSelected = widget.selectedIndex == index;
                return Semantics(
                  button: true,
                  selected: isSelected,
                  label: widget.tabs[index],
                  child: AnimatedPressable(
                    onTap: () => widget.onSelect(index),
                    child: AnimatedContainer(
                      duration: MedAiA11y.motion(
                          context, const Duration(milliseconds: 260)),
                      curve: AppCurves.smooth,
                      constraints: const BoxConstraints(
                          minHeight: MedAiA11y.minTapTargetCompact),
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (context.isDark ? L.card : AppColors.eatoNavy)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: isSelected && !context.isDark
                          ? [
                              BoxShadow(
                                color: AppColors.eatoNavy.withValues(alpha: 0.12),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : (isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                    spreadRadius: -2,
                                  ),
                                ]
                              : null),
                    ),
                    child: Text(
                      widget.tabs[index],
                      style: AppTypography.labelLarge.copyWith(
                        color: isSelected
                            ? (context.isDark ? L.text : Colors.white)
                            : L.sub.withValues(alpha: 0.6),
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
              }),
            );
          },
        ),
      ),
    );
  }
}

class LatencyHeatmap extends StatelessWidget {
  final List<Map<String, dynamic>> latencyData;
  final AppThemeColors L;

  const LatencyHeatmap({super.key, required this.latencyData, required this.L});

  @override
  Widget build(BuildContext context) {
    if (latencyData.isEmpty) return _buildEmptyState(L);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('⏱️', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              'Timing consistency',
              style: AppTypography.titleMedium.copyWith(
                fontSize: 15,
                color: L.text,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 180,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: L.card.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: L.border.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: L.bg.withValues(alpha: 0.5),
                blurRadius: 24,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final date = DateTime.now().subtract(Duration(days: 6 - i));
              final dateStr = date.toIso8601String().substring(0, 10);
              final dayLatency =
                  latencyData.where((e) => e['date'] == dateStr).toList();

              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 0.5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  L.border.withValues(alpha: 0.1),
                                  Colors.transparent
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          ...dayLatency.map((d) {
                            final latency = (d['latency'] as int?) ?? 0;
                            final color = latency.abs() < 15
                                ? L.text
                                : (latency.abs() < 60 ? L.sub : L.error);
                            final bottomPos = ((latency + 60) / 120 * 100)
                                .clamp(0.0, 100.0);

                            return Positioned(
                              bottom: bottomPos,
                              child: Container(
                                width: 10,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: L.bg, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                        color: color.withValues(alpha: 0.5),
                                        blurRadius: 12,
                                        spreadRadius: 2),
                                  ],
                                ),
                              ),
                            );
                          }),
                          // Viral Laser Line Scan
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: L.accent.withValues(alpha: 0.8),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    )
                                  ],
                                  color: L.accent,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                          [date.weekday % 7],
                      style: AppTypography.labelSmall.copyWith(
                          fontSize: 10,
                          color: L.sub,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppThemeColors L) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Timing consistency',
            style: AppTypography.titleMedium.copyWith(
                color: L.text,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2)),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: Container(
            decoration: ShapeDecoration(
              color: L.card,
              shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.circular(48),
                  side: BorderSide(color: L.border.withValues(alpha: 0.1))),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PremiumIllustrationBanner(
                  asset: PremiumGraphics.healthInsights,
                  height: 88,
                  padding: const EdgeInsets.all(12),
                ),
                const SizedBox(height: 16),
                Text('Log doses to see timing patterns',
                    style: AppTypography.bodySmall
                        .copyWith(color: L.sub, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class HealthCoachCard extends StatelessWidget {
  final List<HealthInsight> insights;
  final AppThemeColors L;
  final VoidCallback onRetry;

  const HealthCoachCard(
      {super.key,
      required this.insights,
      required this.L,
      required this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return _buildEmptyState(L);

    return Column(
      children: insights.map((ins) {
        final cat = ins.category.toLowerCase();
        // Cal AI de-noise: keep a real status color ONLY for safety/warnings;
        // everything else (adherence, optimization, etc.) uses one neutral tone
        // so the insight list reads calm instead of rainbow-tagged. (Was:
        // lime-green for adherence, purple for optimization.)
        final isWarning = cat.contains('safe') || cat.contains('warn');
        final color = isWarning ? L.error : L.sub;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: L.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: L.border.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        cat,
                        style: AppTypography.labelSmall.copyWith(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        ins.title,
                        style: AppTypography.titleMedium.copyWith(
                          color: L.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Refresh AI insights',
                      child: AnimatedPressable(
                        onTap: onRetry,
                        child: Icon(Icons.refresh_rounded,
                            size: 20, color: L.sub.withValues(alpha: 0.6)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SmoothingText(
                  text: ins.body,
                  style: AppTypography.bodySmall.copyWith(
                    color: L.sub,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                if (ins.steps.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ins.steps
                        .map((step) => AnimatedPressable(
                              onTap: () => context
                                  .read<AppState>()
                                  .executeStepAction(step, context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: L.fill.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  step,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: L.text,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(AppThemeColors L) {
    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: L.border.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          PremiumIllustrationBanner(
            asset: PremiumGraphics.healthInsights,
            height: 100,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
          ),
          Text(
            'AI insights will appear here',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: L.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Log doses and add medicines to get personalized tips.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: L.sub,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class AdherenceTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> trendData;
  final AppThemeColors L;

  const AdherenceTrendChart(
      {super.key, required this.trendData, required this.L});

  @override
  Widget build(BuildContext context) {
    if (trendData.isEmpty) return _buildEmptyState(L);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppColors.eatoCard(
        L,
        isDark: context.isDark,
        radius: 32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('📈', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          'Adherence trend',
                          style: AppTypography.labelSmall.copyWith(
                            color: L.sub.withValues(alpha: 0.8),
                            fontSize: 11,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '30-Day Progress',
                      style: AppTypography.headlineSmall.copyWith(
                        color: L.text,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: L.text.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '30D',
                  style: AppTypography.labelSmall.copyWith(
                    color: L.text,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: trendData.asMap().entries.map((entry) {
                final i = entry.key;
                final day = entry.value;
                final val = (day['value'] as double).clamp(0.0, 1.0);
                final scheduled = (day['scheduled'] as int?) ?? 0;
                final isEmpty = scheduled == 0;
                final Color barColor = isEmpty
                    ? L.fill
                    : (val >= 0.8
                        ? L.text
                        : (val >= 0.4
                            ? L.sub.withValues(alpha: 0.6)
                            : L.error));

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: FractionallySizedBox(
                      heightFactor: isEmpty ? 0.04 : val.clamp(0.08, 1.0),
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: isEmpty
                              ? null
                              : LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    barColor.withValues(alpha: 0.6),
                                    barColor,
                                  ],
                                ),
                          color: isEmpty ? L.fill.withValues(alpha: 0.3) : null,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                            bottom: Radius.circular(2),
                          ),
                          boxShadow: !isEmpty && val >= 0.8 ? [
                            BoxShadow(
                              color: barColor.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, -2),
                            )
                          ] : null,
                        ),
                      ).animate(
                            key: ValueKey('trend_bar_$i'),
                            delay: (i * 20).ms,
                          ).scaleY(
                            begin: 0.0,
                            end: 1.0,
                            duration: 1000.ms,
                            curve: Curves.elasticOut, // snappy bounce
                            alignment: Alignment.bottomCenter,
                          ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '30 days ago',
                style: AppTypography.labelSmall.copyWith(
                  color: L.sub.withValues(alpha: 0.45),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Today',
                style: AppTypography.labelSmall.copyWith(
                  color: L.text,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppThemeColors L) {
    return MedAiDepthCard(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: SizedBox(
        height: 120,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PremiumIllustrationBanner(
              asset: PremiumGraphics.onboardingThriving,
              height: 88,
              padding: const EdgeInsets.all(12),
            ),
            const SizedBox(height: 16),
            Text(
              'Trend data generating...',
              style: AppTypography.bodySmall.copyWith(
                color: L.sub,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InventoryStatusCard extends StatelessWidget {
  final List<Medicine> meds;
  final AppThemeColors L;
  final bool embedded;

  const InventoryStatusCard({
    super.key,
    required this.meds,
    required this.L,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final trackedMeds = meds.where((m) => m.count > 0).toList();
    if (trackedMeds.isEmpty) return const SizedBox.shrink();

    final content = Column(
        children: trackedMeds.asMap().entries.map((entry) {
          final i = entry.key;
          final med = entry.value;
          final isLow = med.count <= med.refillAt;
          final color = isLow ? L.error : AppColors.limeDeep;
          final pct = (med.count / (med.totalCount > 0 ? med.totalCount : 30))
              .clamp(0.01, 1.0);

          return Padding(
            padding:
                EdgeInsets.only(bottom: i == trackedMeds.length - 1 ? 0 : 14),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    med.name,
                    style: AppTypography.labelMedium.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: L.fill.withValues(alpha: 0.5),
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 28,
                  child: Text(
                    '${med.count}',
                    style: AppTypography.labelMedium.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
    );

    if (embedded) return content;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: L.border.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: content,
    );
  }
}

class SmartLoadingInsights extends StatefulWidget {
  final AppThemeColors L;
  const SmartLoadingInsights({super.key, required this.L});

  @override
  State<SmartLoadingInsights> createState() => _SmartLoadingInsightsState();
}

class _SmartLoadingInsightsState extends State<SmartLoadingInsights> {
  int _messageIndex = 0;
  Timer? _timer;

  static const List<String> _smartLoadingMessages = [
    'Synthesizing biometrics & heart rate stability data...',
    'Analyzing pharmacokinetic curves & onset parameters...',
    'Consulting clinical drug safety guidelines...',
    'Evaluating daily medication adherence progress...',
    'Formulating personalized AI medical insights...',
    'Calibrating smart reminder schedules for you...',
    'Checking drug-drug interaction safety profiles...',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _smartLoadingMessages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final L = widget.L;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: L.border.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: L.purple,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analyzing your data',
                  style: AppTypography.titleMedium.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: Text(
                    _smartLoadingMessages[_messageIndex],
                    key: ValueKey<int>(_messageIndex),
                    style: AppTypography.bodySmall.copyWith(
                      color: L.sub,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
