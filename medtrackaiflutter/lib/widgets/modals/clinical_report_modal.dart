import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/app_state.dart';
import '../../theme/med_ai_ui.dart';
import '../../core/utils/haptic_engine.dart';
import '../common/refined_sheet_wrapper.dart';
import '../common/app_feedback.dart';
import '../../services/report_service.dart';
import '../../l10n/app_localizations.dart';
class ClinicalReportModal extends StatefulWidget {
  final AppState state;
  final double adherence;
  final int streak;

  const ClinicalReportModal({
    super.key,
    required this.state,
    required this.adherence,
    required this.streak,
  });

  static void show(
      BuildContext context, AppState state, double adherence, int streak) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClinicalReportModal(
        state: state,
        adherence: adherence,
        streak: streak,
      ),
    );
  }

  @override
  State<ClinicalReportModal> createState() => _ClinicalReportModalState();
}

class _ClinicalReportModalState extends State<ClinicalReportModal> {
  bool _isGenerating = false;

  Widget _entrance(Widget child, {List<Effect>? effects}) {
    if (MedAiA11y.reducedMotion(context)) return child;
    return child.animate(effects: effects ?? MedAiMotion.cardEntrance(context, 0));
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final s = AppLocalizations.of(context)!;
    final reduceMotion = MedAiA11y.reducedMotion(context);

    Widget heroIcon = Container(
      width: MedAiA11y.minTapTarget * 2,
      height: MedAiA11y.minTapTarget * 2,
      decoration: BoxDecoration(
        color: L.accent.withValues(alpha: 0.08),
        shape: BoxShape.circle,
        border: Border.all(color: L.accent.withValues(alpha: 0.2), width: 1.5),
        boxShadow: L.accentGlow(intensity: 0.15),
      ),
      child: Icon(Icons.auto_awesome_rounded, color: L.accent, size: 40),
    );

    if (!reduceMotion) {
      heroIcon = heroIcon
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(
            begin: 0.97,
            end: 1.03,
            duration: 2.seconds,
            curve: Curves.easeInOut,
          );
    }

    return RefinedSheetWrapper(
      title: 'Value Realization',
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        children: [
          Semantics(
            label: 'Clinical report ready',
            child: heroIcon,
          ),
          const SizedBox(height: 24),
          Text(
            'Clinical Report Ready',
            style: AppTypography.titleLarge
                .copyWith(fontWeight: FontWeight.w800, color: L.text),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ve synthesized your last 30 days of medical data into a professional clinical summary.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: L.sub, height: 1.5),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _buildStatCard(L, 'ADHERENCE',
                  '${(widget.adherence * 100).round()}%', Icons.analytics_rounded),
              const SizedBox(width: 16),
              _buildStatCard(L, 'STREAK', '${widget.streak} DAYS',
                  Icons.local_fire_department_rounded),
            ],
          ),
          const SizedBox(height: 32),
          _buildInfoRow(L, Icons.medication_rounded,
              '${widget.state.meds.length} active medications tracked'),
          _buildInfoRow(
              L, Icons.favorite_rounded, 'Biometric trends (Heart Rate, Steps)'),
          _buildInfoRow(L, Icons.assignment_turned_in_rounded,
              'Daily logging checklist & notes'),
          const SizedBox(height: 32),
          MedAiCTA(
            label: 'Generate PDF Report',
            icon: Icons.picture_as_pdf_rounded,
            loading: _isGenerating,
            semanticsLabel: 'Generate PDF clinical report',
            onTap: () async {
              if (_isGenerating) return;
              HapticEngine.selection();
              setState(() => _isGenerating = true);

              try {
                await Future.delayed(const Duration(milliseconds: 1200));
                ReportService.generateAndShareReport(
                  s: s,
                  userName: widget.state.profile?.name ?? s.greetingHero,
                  adherence: widget.adherence,
                  meds: widget.state.meds,
                  symptoms: widget.state.symptoms,
                  history: widget.state.history,
                  avgHeartRate: widget.state.healthHeartRate,
                  avgSteps: widget.state.healthSteps,
                  currentStreak: widget.streak,
                  trendData: widget.state.getTrendData(),
                );
              } catch (e) {
                if (context.mounted) {
                  AppFeedback.toast(
                    context,
                    'Failed to generate report: $e',
                    type: 'error',
                  );
                }
              } finally {
                if (context.mounted) {
                  setState(() => _isGenerating = false);
                  Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      AppThemeColors L, String label, String value, IconData icon) {
    return Expanded(
      child: _entrance(
        Semantics(
          label: '$label $value',
          child: MedAiDepthCard(
            padding: const EdgeInsets.all(20),
            radius: AppRadius.xl,
            accentGlow: true,
            child: Column(
              children: [
                Icon(icon, color: L.accent, size: 20),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: AppTypography.titleLarge
                      .copyWith(fontWeight: FontWeight.w800, color: L.text),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 10,
                    color: L.sub,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(AppThemeColors L, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        label: text,
        child: MedAiGlass(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          radius: AppRadius.l,
          showBorder: true,
          child: Row(
            children: [
              Icon(icon, size: 18, color: L.accent),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
                  style: AppTypography.bodySmall
                      .copyWith(color: L.text, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
