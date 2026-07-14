import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app_routes.dart';
import '../../../providers/app_state.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../services/export_service.dart';
import '../paywall/premium_paywall_overlay.dart';
import '../../../widgets/common/animated_ring_hero.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/animated_pressable.dart';
import '../../../widgets/common/premium_page_header.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  Widget _analyticsEntrance(Widget child, {Duration? delay}) {
    if (MedAiA11y.reducedMotion(context)) return child;
    return child
        .animate(delay: delay)
        .fadeIn(duration: AppDurations.fast, curve: AppCurves.smooth)
        .slideY(begin: 0.06, end: 0, curve: AppCurves.smooth);
  }

  /// Generates the doctor-ready PDF and opens the share sheet. Premium-gated:
  /// non-premium users get the paywall (report is a top retention/upsell hook).
  Future<void> _shareDoctorReport(BuildContext context, AppState state) async {
    HapticEngine.selection();
    final ok = await ExportService.exportAdherenceReport(state);
    if (!ok && context.mounted) {
      PremiumPaywallOverlay.show(context, triggerSource: 'doctor_report');
    }
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final state = context.watch<AppState>();

    final adherence = state.getAdherenceScore();
    final streak = state.getStreak();
    final totalSymptoms = state.symptoms.length;
    final canPop = Navigator.of(context).canPop();

    // Real today counts for the ring (was adherence×10 fake math).
    final todayDoses = state.getDoses();
    final takenMap = state.getTakenMapForDate(DateTime.now());
    final takenToday =
        todayDoses.where((d) => takenMap[d.key] ?? false).length;

    return AppScaffold(
      showAurora: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PremiumPageHeader(
              title: 'Analytics',
              subtitle: 'Your medication insights',
              onBack: canPop ? () => Navigator.pop(context) : null,
            ),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  _analyticsEntrance(
                    CalAiRingHero(
                      takenCount: takenToday,
                      total: todayDoses.length,
                      dosePct: todayDoses.isEmpty
                          ? 1.0
                          : takenToday / todayDoses.length,
                      streak: streak,
                      remaining: todayDoses.length - takenToday,
                    ),
                  ),

                  const SizedBox(height: 20),

                  _analyticsEntrance(
                    _DoctorReportCard(
                      onTap: () => _shareDoctorReport(context, state),
                      L: L,
                    ),
                  ),

                  const SizedBox(height: 20),

                  _analyticsEntrance(
                    Row(
                      children: [
                        Expanded(
                          child: _StatMiniCard(
                            title: 'Adherence',
                            value: '${(adherence * 100).round()}%',
                            subtitle: 'All time',
                            icon: Icons.pie_chart_outline_rounded,
                            color: L.success,
                            L: L,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatMiniCard(
                            title: 'Symptoms',
                            value: '$totalSymptoms',
                            subtitle: 'Total logs',
                            icon: Icons.monitor_heart_outlined,
                            color: L.error,
                            L: L,
                          ),
                        ),
                      ],
                    ),
                    delay: 80.ms,
                  ),

                  const SizedBox(height: 28),

                  const MedAiSectionHeader(title: 'Trend analysis'),
                  const SizedBox(height: 4),
                  _analyticsEntrance(
                    _TrendGraph(L: L, trend: state.getTrendData()),
                    delay: 160.ms,
                  ),

                  const SizedBox(height: 28),

                  const MedAiSectionHeader(title: 'Explore'),
                  const SizedBox(height: 4),

                  _analyticsEntrance(
                    _NavCard(
                      L: L,
                      icon: Icons.inventory_2_rounded,
                      label: 'Inventory',
                      title: 'Stock levels & refill alerts',
                      onTap: () {
                        HapticEngine.selection();
                        context.push(AppRoutes.statsInventory);
                      },
                    ),
                    delay: 220.ms,
                  ),
                  const SizedBox(height: 12),

                  _analyticsEntrance(
                    _NavCard(
                      L: L,
                      icon: Icons.play_arrow_rounded,
                      label: 'Monthly wrapped',
                      title: 'View your stats',
                      filled: true,
                      onTap: () {
                        HapticEngine.heavyImpact();
                        context.push(AppRoutes.statsWrapped);
                      },
                    ),
                    delay: 280.ms,
                  ),
                  const SizedBox(height: 12),

                  _analyticsEntrance(
                    _NavCard(
                      L: L,
                      icon: Icons.groups_rounded,
                      label: 'Social',
                      title: 'Med buddies & leaderboards',
                      onTap: () {
                        HapticEngine.heavyImpact();
                        context.push(AppRoutes.statsBuddies);
                      },
                    ),
                    delay: 340.ms,
                  ),
                  const SizedBox(height: 12),

                  _analyticsEntrance(
                    _NavCard(
                      L: L,
                      icon: Icons.emoji_events_rounded,
                      label: 'Achievements',
                      title: 'Trophy case',
                      onTap: () {
                        HapticEngine.heavyImpact();
                        context.push(AppRoutes.statsTrophy);
                      },
                    ),
                    delay: 400.ms,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final AppThemeColors L;
  final IconData icon;
  final String label;
  final String title;
  final bool filled;
  final VoidCallback onTap;

  const _NavCard({
    required this.L,
    required this.icon,
    required this.label,
    required this.title,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : L.text;
    final sub = filled ? Colors.white.withValues(alpha: 0.85) : L.sub;
    final body = _NavCardBody(
      icon: icon,
      label: label,
      title: title,
      fg: fg,
      sub: sub,
      filled: filled,
      L: L,
    );

    if (filled) {
      return Semantics(
        button: true,
        label: '$label. $title',
        child: AnimatedPressable(
          onTap: onTap,
          child: Container(
            constraints:
                const BoxConstraints(minHeight: MedAiA11y.minTapTarget),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [L.accent, L.accent.withValues(alpha: 0.85)],
              ),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: L.accentGlow(intensity: 0.25),
            ),
            child: body,
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      label: '$label. $title',
      child: MedAiDepthCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: body,
      ),
    );
  }
}

class _NavCardBody extends StatelessWidget {
  final IconData icon;
  final String label;
  final String title;
  final Color fg;
  final Color sub;
  final bool filled;
  final AppThemeColors L;

  const _NavCardBody({
    required this.icon,
    required this.label,
    required this.title,
    required this.fg,
    required this.sub,
    required this.filled,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled
                ? Colors.white.withValues(alpha: 0.2)
                : L.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: filled ? Colors.white : L.accent, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: sub,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.chevron_right_rounded,
            color: filled ? Colors.white : L.sub, size: 22),
      ],
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final AppThemeColors L;

  const _StatMiniCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title: $value. $subtitle',
      child: MedAiDepthCard(
        accentGlow: true,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: AppTypography.headlineLarge.copyWith(
                color: L.text,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                color: L.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(color: L.sub),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendGraph extends StatefulWidget {
  final AppThemeColors L;

  /// Last-30-day adherence trend from AppState.getTrendData():
  /// [{'date': 'yyyy-MM-dd', 'value': 0..1}, ...]. The graph shows the
  /// final 7 days — real data, not the demo bars this screen used to ship.
  final List<Map<String, dynamic>> trend;

  const _TrendGraph({required this.L, required this.trend});

  @override
  State<_TrendGraph> createState() => _TrendGraphState();
}

class _TrendGraphState extends State<_TrendGraph> {
  bool _animate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _animate = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final L = widget.L;
    final week = widget.trend.length > 7
        ? widget.trend.sublist(widget.trend.length - 7)
        : widget.trend;
    final data = week.isEmpty
        ? List<double>.filled(7, 0)
        : week
            .map((d) =>
                ((d['value'] as num?) ?? 0).toDouble().clamp(0.0, 1.0))
            .toList();
    final reduceMotion = MedAiA11y.reducedMotion(context);

    return Semantics(
      label: 'Weekly performance trend chart',
      child: MedAiDepthCard(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Weekly performance',
                    style: AppTypography.titleMedium.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(Icons.show_chart_rounded, color: L.accent, size: 20),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(data.length, (index) {
                  // Min height 6 so zero-adherence days still render a stub.
                  final targetHeight =
                      (100.0 * data[index]).clamp(6.0, 100.0);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: AnimatedContainer(
                        duration: reduceMotion
                            ? Duration.zero
                            : Duration(milliseconds: 500 + index * 100),
                        curve: Curves.easeOutBack,
                        height: _animate ? targetHeight : 0,
                        decoration: BoxDecoration(
                          gradient: index == data.length - 1
                              ? LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    L.accent,
                                    L.accent.withValues(alpha: 0.7),
                                  ],
                                )
                              : null,
                          color: index == data.length - 1
                              ? null
                              : L.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// DOCTOR-READY PDF REPORT CTA (retention/upsell hook)
// ══════════════════════════════════════════════
class _DoctorReportCard extends StatelessWidget {
  final VoidCallback onTap;
  final AppThemeColors L;

  const _DoctorReportCard({required this.onTap, required this.L});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Share medication report with your doctor',
      child: AnimatedPressable(
        onTap: onTap,
        child: MedAiDepthCard(
          accentGlow: true,
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: L.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.assignment_rounded, color: L.accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share with your doctor',
                      style: AppTypography.titleMedium.copyWith(
                        color: L.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Export a clinical PDF of your adherence & meds',
                      style: AppTypography.bodySmall
                          .copyWith(color: L.sub, height: 1.3),
                    ),
                  ],
                ),
              ),
              Icon(Icons.ios_share_rounded, color: L.sub, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
