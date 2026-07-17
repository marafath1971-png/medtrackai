import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/haptic_engine.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../services/report_service.dart';
import '../../theme/med_ai_ui.dart';
import '../../widgets/common/paywall_sheet.dart';
import '../../widgets/modals/clinical_report_modal.dart';
import '../../widgets/modals/daily_log_sheet.dart';
import '../../widgets/common/premium_texture.dart';
import 'widgets/dashboard_adherence_hero.dart';
import 'widgets/dashboard_purrent_ui.dart';
import 'widgets/dashboard_widgets.dart';

class DashboardTab extends StatefulWidget {
  final VoidCallback onScan;
  const DashboardTab({super.key, required this.onScan});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _insightsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().fetchHealthInsights();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int _dosesThisWeek(AppState state) {
    return _weeklyDoseCounts(state).fold<int>(0, (a, b) => a + b);
  }

  /// Oldest → newest dose counts for the last 7 days.
  List<int> _weeklyDoseCounts(AppState state) {
    final now = DateTime.now();
    final counts = <int>[];
    for (var i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      counts.add((state.history[key] ?? [])
          .where((e) => e.taken && !e.label.startsWith('PRN-'))
          .length);
    }
    return counts;
  }

  /// Last 7 adherence points from trend data (oldest → newest).
  List<double> _weeklyAdherence(List<Map<String, dynamic>> trendData) {
    if (trendData.isEmpty) return const [];
    final slice = trendData.length >= 7
        ? trendData.sublist(trendData.length - 7)
        : trendData;
    return slice
        .map((e) => ((e['value'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0))
        .toList();
  }

  void _scrollToInsights() {
    final ctx = _insightsKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final s = AppLocalizations.of(context);
    if (s == null) return const SizedBox.shrink();

    final state = context.read<AppState>();
    final trendData =
        context.select<AppState, List<Map<String, dynamic>>>((s) => s.getTrendData());
    final adherence =
        context.select<AppState, double>((s) => s.getAdherenceScore());
    final streak = context.select<AppState, int>((s) => s.getStreak());
    final loadingInsight =
        context.select<AppState, bool>((s) => s.loadingInsight);
    final meds = context.select<AppState, List<Medicine>>((s) => s.meds);
    final history = context.select<AppState, Map<String, List<DoseEntry>>>(
      (s) => s.history,
    );
    final healthInsights =
        context.select<AppState, List<HealthInsight>>((s) => s.healthInsights);
    final healthConnected =
        context.select<AppState, bool>((s) => s.healthConnected);
    final dosesWeek = _dosesThisWeek(state);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PremiumHomeSurface(
        child: RefreshIndicator(
          onRefresh: () async {
            HapticEngine.selection();
            await state.checkConnectivity();
            await state.loadFromStorage();
            await state.fetchHealthInsights();
          },
          color: AppColors.limeDeep,
          backgroundColor: L.card,
          displacement: 48,
          strokeWidth: 2.5,
          child: Scrollbar(
            controller: _scrollController,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: DashboardPurrentTopBar(
                    onMenu: _scrollToInsights,
                    onDailyLog: () {
                      HapticEngine.selection();
                      DailyLogSheet.show(context);
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.p16, AppSpacing.gutter, 0),
                    child: DashboardAdherenceHero(
                      trendData: trendData,
                      adherence: adherence,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: DashboardPurrentMetricGrid(
                    streak: streak,
                    dosesWeek: dosesWeek,
                    weeklyDoseCounts: _weeklyDoseCounts(state),
                    weeklyAdherence: _weeklyAdherence(trendData),
                  ),
                ),
                if (!healthConnected)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.p16, AppSpacing.gutter, 0),
                    sliver: SliverToBoxAdapter(
                      child: _ConnectHealthCard(
                        onConnect: () async {
                          HapticEngine.selection();
                          final ok = await state.connectHealth();
                          if (ok) state.syncHealthData();
                        },
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: DashboardMedicationDiary(
                    history: history,
                    meds: meds,
                  ),
                ),
                if (meds.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.gutter, AppSpacing.gutter, AppSpacing.p8),
                      child: Text(
                        'Supply status',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: L.text,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, 0),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.p16),
                        decoration: BoxDecoration(
                          color: L.card,
                          borderRadius: BorderRadius.circular(24),
                          border:
                              Border.all(color: L.border.withValues(alpha: 0.25)),
                        ),
                        child: InventoryStatusCard(
                          meds: meds,
                          L: L,
                          embedded: true,
                        ),
                      ),
                    ),
                  ),
                ],
                SliverToBoxAdapter(
                  key: _insightsKey,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.gutter, AppSpacing.gutter, AppSpacing.p8),
                    child: Text(
                      'AI insights',
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: L.text,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.p16),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.p16),
                      decoration: BoxDecoration(
                        color: L.card,
                        borderRadius: BorderRadius.circular(24),
                        border:
                            Border.all(color: L.border.withValues(alpha: 0.25)),
                      ),
                      child: loadingInsight
                          ? SmartLoadingInsights(L: L)
                          : HealthCoachCard(
                              insights: healthInsights,
                              L: L,
                              onRetry: () => state.fetchHealthInsights(),
                            ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.p12),
                  sliver: SliverToBoxAdapter(
                    child: MedAiCTA(
                      label: s.generateClinicalReport,
                      icon: Icons.picture_as_pdf_rounded,
                      onTap: () {
                        HapticEngine.selection();
                        if (!state.isPremium) {
                          PaywallSheet.show(context);
                          return;
                        }
                        ClinicalReportModal.show(
                          context,
                          state,
                          adherence,
                          streak,
                        );
                      },
                      semanticsLabel: 'Generate clinical report PDF',
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.p16),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: TextButton(
                        onPressed: () {
                          HapticEngine.selection();
                          ReportService.generateAndShareCSV(
                            meds: state.meds,
                            history: state.history,
                          );
                        },
                        child: Text(
                          'Export data as CSV',
                          style: AppTypography.labelLarge.copyWith(
                            color: L.sub,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, 0),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.p16),
                      decoration: BoxDecoration(
                        color: L.card,
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: L.border.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: L.sub,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.p12),
                          Expanded(
                            child: Text(
                              s.aiCoachDisclaimer,
                              style: AppTypography.bodySmall.copyWith(
                                color: L.sub,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectHealthCard extends StatelessWidget {
  final VoidCallback onConnect;

  const _ConnectHealthCard({required this.onConnect});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return GestureDetector(
      onTap: onConnect,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.p16),
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: L.border.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.badgeFill(AppColors.limeDeep),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.monitor_heart_outlined,
                size: 22,
                color: AppColors.limeDeep,
              ),
            ),
            const SizedBox(width: AppSpacing.p16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connect health data',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: L.text,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.p4),
                  Text(
                    'Sync steps and heart rate alongside your meds.',
                    style: AppTypography.bodySmall.copyWith(
                      color: L.sub,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: L.sub.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
