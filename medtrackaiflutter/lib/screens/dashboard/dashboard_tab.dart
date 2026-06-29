import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/common/premium_empty_state.dart';
import '../../providers/app_state.dart';
import '../../widgets/shared/shared_widgets.dart';
import '../../theme/med_ai_ui.dart';
import '../../widgets/modals/trend_drilldown_sheet.dart';
import '../../core/utils/haptic_engine.dart';

import '../../services/report_service.dart';
import '../../widgets/common/paywall_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/modals/daily_log_sheet.dart';
import '../home/widgets/streak_modal.dart';
import 'widgets/dashboard_widgets.dart';
import '../home/widgets/voice_assistant_overlay.dart';
import '../../services/voice_service.dart';
import '../../widgets/modals/clinical_report_modal.dart';
import '../../widgets/biohacking/pharma_timeline_widget.dart';
import '../../widgets/biohacking/interactive_body_map.dart';
import '../../widgets/common/app_scaffold.dart';

class DashboardTab extends StatefulWidget {
  final VoidCallback onScan;
  const DashboardTab({super.key, required this.onScan});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  bool _isScrolled = false;
  bool _showVoiceAssistant = false;
  int _selectedTimelineMedIndex = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Refresh insights when entering the tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        context.read<AppState>().fetchHealthInsights();
        VoiceService.init();
      } catch (e) {
        debugPrint('[DashboardTab] Error in post-frame initialization: $e');
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final scrolled = _scrollController.offset > 10;
    if (scrolled != _isScrolled) {
      setState(() => _isScrolled = scrolled);
    }
  }

  Widget _dashboardEntrance(Widget child, {Duration? delay}) {
    if (MedAiA11y.reducedMotion(context)) return child;
    return child
        .animate(key: ValueKey(child.hashCode), delay: delay)
        .fadeIn(duration: AppDurations.fast, curve: AppCurves.smooth)
        .slideY(begin: 0.08, end: 0, curve: AppCurves.smooth);
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final s = AppLocalizations.of(context);
    if (s == null) return const SizedBox.shrink();
    
    final state = context.read<AppState>();
    // Granular selection
    final latency = context.select<AppState, List<Map<String, dynamic>>>(
        (s) => s.getLatencyData());
    final trendData = context
        .select<AppState, List<Map<String, dynamic>>>((s) => s.getTrendData());
    final adherence =
        context.select<AppState, double>((s) => s.getAdherenceScore());
    final streak = context.select<AppState, int>((s) => s.getStreak());
    final loadingInsight =
        context.select<AppState, bool>((s) => s.loadingInsight);
    final meds = context.select<AppState, List<Medicine>>((s) => s.meds);
    final healthInsights =
        context.select<AppState, List<HealthInsight>>((s) => s.healthInsights);
        
    final activeTimelineMed = meds.isNotEmpty && _selectedTimelineMedIndex < meds.length 
        ? meds[_selectedTimelineMedIndex] 
        : (meds.isNotEmpty ? meds.first : null);

    return AppScaffold(
      showAurora: context.isDark,
      body: Stack(children: [
        // ── Main Content ──
        RefreshIndicator(
          onRefresh: () async {
            HapticEngine.selection();
            final state = context.read<AppState>();
            await state.loadFromStorage();
            await state.fetchHealthInsights();
          },
          displacement: 100,
          color: AppColors.accent,
          backgroundColor: L.bg,
          child: Scrollbar(
            controller: _scrollController,
            child: SingleChildScrollView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              child: Column(
                children: [
                  // Spacer for Header
                  SizedBox(height: 100 + MediaQuery.of(context).padding.top),
                  const SizedBox(height: AppSpacing.l),

                  // --- SUMMARY STATS (Bento) ---
                  _dashboardEntrance(
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          _buildSummaryCard(
                            context,
                            s.adherenceLabel,
                            adherence * 100,
                            '%',
                            '📈',
                            L.green,
                            onTap: () {
                              if (!mounted) return;
                              _showTrendDrilldown(context, state, L);
                            },
                          ),
                          const SizedBox(width: 16),
                          _buildSummaryCard(
                            context,
                            s.streakLabel,
                            streak.toDouble(),
                            'D',
                            '⚡',
                            AppColors.accent,
                            onTap: () {
                              if (!mounted) return;
                              StreakModal.show(context, state);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- BIOMETRIC BENTO (Task 1) ---
                  _buildBiometricBento(context, state, L, s),
                  const SizedBox(height: 32),

                  // --- PHARMACOKINETICS VISUALIZER (Hook D) ---
                  if (activeTimelineMed != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                      child: PharmaTimelineWidget(
                        medName: activeTimelineMed.name,
                        onsetMinutes: activeTimelineMed.aiSafetyProfile?.onsetMinutes != null && activeTimelineMed.aiSafetyProfile!.onsetMinutes > 0 
                            ? activeTimelineMed.aiSafetyProfile!.onsetMinutes.toDouble() 
                            : 30.0, // Fallback if no AI data
                        peakHours: activeTimelineMed.aiSafetyProfile?.peakHours != null && activeTimelineMed.aiSafetyProfile!.peakHours > 0 
                            ? activeTimelineMed.aiSafetyProfile!.peakHours 
                            : 2.5,
                        durationHours: activeTimelineMed.aiSafetyProfile?.durationHours != null && activeTimelineMed.aiSafetyProfile!.durationHours > 0 
                            ? activeTimelineMed.aiSafetyProfile!.durationHours 
                            : 6.0,
                        targetOrgans: activeTimelineMed.aiSafetyProfile?.bodySystems.isNotEmpty == true 
                            ? activeTimelineMed.aiSafetyProfile!.bodySystems 
                            : const ['Brain', 'Nervous System'],
                      ),
                    ).animate(key: const ValueKey('dashboard_pharma_timeline_anim')).fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                      child: InteractiveBodyMap(
                        activeSystems: activeTimelineMed.aiSafetyProfile?.bodySystems ?? [],
                        medName: activeTimelineMed.name,
                      ),
                    ).animate(key: const ValueKey('dashboard_interactive_body_map_anim'), delay: 200.ms).fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 32),
                  ],

                  // --- TIMELINE PILL SELECTOR ---
                  if (meds.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 20, bottom: 24),
                      child: TimelinePillSelector(
                        selectedIndex: _selectedTimelineMedIndex,
                        onSelect: (idx) {
                          HapticEngine.selection();
                          setState(() => _selectedTimelineMedIndex = idx);
                        },
                        L: L,
                      ),
                    )
                        .animate(key: const ValueKey('dashboard_timeline_selector_anim'), delay: 100.ms)
                        .fadeIn(duration: 600.ms)
                        .slideX(begin: 0.1, end: 0)
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: PremiumEmptyState(
                        title: 'No analytics',
                        subtitle: 'Add medicines to generate AI safety profiles and body maps.',
                        icon: Icons.biotech_rounded,
                      ),
                    ).animate(key: const ValueKey('dashboard_empty_state_anim')).fadeIn(duration: 800.ms),

                  // --- 30-DAY ADHERENCE TREND ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding),
                    child: Column(
                      children: [
                        AdherenceTrendChart(trendData: trendData, L: L)
                            .animate(key: const ValueKey('dashboard_adherence_trend_anim'), delay: 150.ms)
                            .fadeIn(duration: 600.ms)
                            .slideY(
                                begin: 0.1, end: 0, curve: Curves.easeOutExpo),
                        const SizedBox(height: 24),
                        InventoryStatusCard(meds: meds, L: L)
                            .animate(key: const ValueKey('dashboard_inventory_status_anim'), delay: 200.ms)
                            .fadeIn(duration: 600.ms)
                            .slideY(
                                begin: 0.1, end: 0, curve: Curves.easeOutExpo),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // --- LATENCY HEATMAP ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding),
                    child: LatencyHeatmap(latencyData: latency, L: L)
                        .animate(key: const ValueKey('dashboard_latency_heatmap_anim'))
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutExpo),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // --- AI HEALTH COACH ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding),
                    child: loadingInsight
                        ? SmartLoadingInsights(L: L)
                        : HealthCoachCard(
                            insights: healthInsights,
                            L: L,
                            onRetry: () {
                              if (!mounted) return;
                              context.read<AppState>().fetchHealthInsights();
                            },
                          ).animate(key: const ValueKey('dashboard_health_coach_anim')).fadeIn(duration: 800.ms),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // --- EXPORT PDF BUTTON (PREMIUM) ---
                  _dashboardEntrance(
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding),
                      child: MedAiCTA(
                        label: s.generateClinicalReport,
                        icon: Icons.picture_as_pdf_rounded,
                        onTap: () {
                          HapticEngine.selection();
                          final state = context.read<AppState>();
                          if (!state.isPremium) {
                            if (!mounted) return;
                            PaywallSheet.show(context);
                            return;
                          }
                          ClinicalReportModal.show(
                              context, state, adherence, streak);
                        },
                        semanticsLabel: 'Generate clinical report PDF',
                      ),
                    ),
                    delay: 100.ms,
                  ),

                  const SizedBox(height: 16),

                  // --- EXPORT CSV BUTTON ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding),
                    child: TextButton(
                      onPressed: () {
                        HapticEngine.selection();
                        final state = context.read<AppState>();
                        ReportService.generateAndShareCSV(
                          meds: state.meds,
                          history: state.history,
                        );
                      },
                      child: Text('Export data as CSV',
                          style: AppTypography.labelLarge.copyWith(
                              color: L.sub,
                              fontWeight: FontWeight.w600)),
                    ),
                  )
                      .animate(key: const ValueKey('dashboard_export_csv_anim'), delay: 150.ms)
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: AppSpacing.xxl),

                  // --- FOOTER INFO ---
                  _dashboardEntrance(
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding),
                      child: MedAiGlass(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: L.sub, size: 20),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                s.aiCoachDisclaimer,
                                style: AppTypography.bodySmall.copyWith(
                                    color: L.sub, fontSize: 12, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    delay: 150.ms,
                  ),

                  const SizedBox(height: 120), // Reduced spacer
                ],
              ),
            ),
          ),
        ),

        // ── Dashboard Header ──
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _DashboardHeader(
            isScrolled: _isScrolled,
            onDailyLog: () {
              HapticEngine.selection();
              DailyLogSheet.show(context);
            },
          ),
        ),

        if (_showVoiceAssistant)
          VoiceAssistantOverlay(
            onDismiss: () => setState(() => _showVoiceAssistant = false),
          ),
      ]),
    );
  }
}

// ── Dashboard Header Component ──
class _DashboardHeader extends StatelessWidget {
  final bool isScrolled;
  final VoidCallback onDailyLog;

  const _DashboardHeader({
    required this.isScrolled,
    required this.onDailyLog,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final topPadding = MediaQuery.of(context).padding.top;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: AnimatedContainer(
          duration: MedAiA11y.motion(context, const Duration(milliseconds: 250)),
          padding: EdgeInsets.fromLTRB(24, topPadding + 12, 24, 16),
          decoration: BoxDecoration(
            color: L.bg.withValues(alpha: isScrolled ? 0.92 : 0.0),
            border: Border(
              bottom: BorderSide(
                color: L.border.withValues(alpha: isScrolled ? 0.1 : 0.0),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ANALYTICS',
                    style: AppTypography.labelSmall.copyWith(
                      color: L.sub,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    'Health insights',
                    style: AppTypography.headlineLarge.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'How your meds are working',
                    style: AppTypography.bodySmall.copyWith(color: L.sub),
                  ),
                ],
              ),
              const Spacer(),
              // Actions
              Semantics(
                button: true,
                label: 'Daily log',
                child: _HeaderActionBtn(
                  icon: Icons.add_rounded,
                  onTap: onDailyLog,
                  isPrimary: true,
                  L: L,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  final AppThemeColors L;

  const _HeaderActionBtn({
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      onTap: onTap,
      scaleFactor: 0.9,
      child: Container(
        width: MedAiA11y.minTapTarget,
        height: MedAiA11y.minTapTarget,
        decoration: BoxDecoration(
          color: isPrimary
              ? (context.isDark ? L.text : AppColors.eatoNavy)
              : L.card,
          shape: BoxShape.circle,
          border: Border.all(
            color: L.border.withValues(alpha: isPrimary ? 0.0 : 0.1),
            width: 0.5,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            color: isPrimary ? Colors.white : L.text,
            size: 22,
          ),
        ),
      ),
    );
  }
}

void _showTrendDrilldown(
      BuildContext context, AppState state, AppThemeColors L) {
    HapticEngine.selection();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TrendDrilldownSheet(state: state, L: L),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String label, double numValue,
      String suffix, String emoji, Color color,
      {VoidCallback? onTap}) {
    final L = context.L;
    final reduceMotion = MedAiA11y.reducedMotion(context);
    return Expanded(
      child: Semantics(
        button: onTap != null,
        label: '$label ${numValue.round()}$suffix',
        child: MedAiDepthCard(
          accentGlow: context.isDark,
          onTap: onTap,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 32)),
              ),
              const SizedBox(height: 20),
              Text(label,
                  style: AppTypography.labelMedium.copyWith(
                      color: L.sub,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2)),
              const SizedBox(height: 12),
              reduceMotion
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('${numValue.round()}$suffix',
                          style: AppTypography.displayLarge.copyWith(
                              fontSize: 54,
                              color: L.text,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                              letterSpacing: -3.0)),
                    )
                  : TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: numValue),
                      duration: 2000.ms,
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('${value.round()}$suffix',
                              style: AppTypography.displayLarge.copyWith(
                                  fontSize: 54,
                                  color: L.text,
                                  fontWeight: FontWeight.w800,
                                  height: 1.0,
                                  letterSpacing: -3.0,
                                  shadows: [
                                    Shadow(
                                      color: color.withValues(alpha: 0.5),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    )
                                  ])),
                        );
                      },
                    ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: color, size: 14),
                    const SizedBox(width: 4),
                    Text('Goal 100%',
                        style: AppTypography.labelSmall.copyWith(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildBiometricBento(BuildContext context, AppState state,
      AppThemeColors L, AppLocalizations s) {
    final connected = state.healthConnected;
    final steps = state.healthSteps;
    final hr = state.healthHeartRate;
    final syncing = state.healthSyncing;
    final bg = state.healthBloodGlucose;
    final systolic = state.healthSystolic;
    final diastolic = state.healthDiastolic;

    if (!connected) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Semantics(
          button: true,
          label: 'Connect health data',
          child: MedAiDepthCard(
              accentGlow: true,
              onTap: () async {
                HapticEngine.selection();
                final ok = await state.connectHealth();
                if (ok) state.syncHealthData();
              },
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                        color: L.bg, shape: BoxShape.circle),
                    child: const Center(
                        child: Text('🩺', style: TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Connect health data',
                            style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w700, color: L.text)),
                        const SizedBox(height: 4),
                        Text(
                            'Sync vitals to see how meds affect your heart.',
                            style: AppTypography.bodySmall.copyWith(
                                color: L.sub, fontSize: 12, height: 1.3)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: L.sub, size: 22),
                ],
              ),
            ),
          ),
        );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildBentoCard(
                  context,
                  'Steps',
                  '${steps.toInt()}',
                  '👟',
                  L.secondary,
                  syncing: syncing,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildBentoCard(
                  context,
                  'BPM',
                  '${hr.toInt()}',
                  '💓',
                  L.error,
                  syncing: syncing,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildBentoCard(
                  context,
                  'Glucose',
                  bg > 0 ? '${bg.toInt()}' : '--',
                  '🩸',
                  const Color(0xFF10B981),
                  syncing: syncing,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBentoCard(
                  context,
                  'Pressure',
                  (systolic > 0 && diastolic > 0) ? '${systolic.toInt()}/${diastolic.toInt()}' : '--/--',
                  '🩺',
                  const Color(0xFF3B82F6),
                  syncing: syncing,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(key: const ValueKey('dashboard_biometric_bento_grid_anim')).fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildBentoCard(
      BuildContext context, String label, String value, String emoji, Color? c,
      {bool syncing = false}) {
    final L = context.L;
    return MedAiDepthCard(
      accentGlow: true,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (c ?? L.text).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              ),
              if (syncing)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: AppShimmer(
                    width: 12,
                    height: 12,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(value,
              style: AppTypography.displayLarge.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: c ?? L.text,
                letterSpacing: -1.0,
              )),
          const SizedBox(height: 6),
          Text(label,
              style: AppTypography.labelSmall.copyWith(
                  color: L.sub,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 0.1)),
        ],
      ),
    );
  }

// ------------------------------------------------------------------
// DASHBOARD QUICK ACTIONS
// ------------------------------------------------------------------
