import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';
import '../common/refined_sheet_wrapper.dart';
import '../../services/report_service.dart';
import '../../l10n/app_localizations.dart';
import '../shared/shared_widgets.dart';

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

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final s = AppLocalizations.of(context)!;

    return RefinedSheetWrapper(
      title: 'Value Realization',
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        children: [
          // Header Holographic Illustration/Icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.2), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  blurRadius: 30,
                  spreadRadius: -10,
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: AppColors.accent, size: 48),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(duration: 2.seconds, color: AppColors.accent.withValues(alpha: 0.5))
              .scaleXY(
                  begin: 0.95,
                  end: 1.05,
                  duration: 2.seconds,
                  curve: Curves.easeInOut),

          const SizedBox(height: 24),
          Text(
            'Clinical Report Ready',
            style: AppTypography.titleLarge
                .copyWith(fontWeight: FontWeight.w900, color: L.text),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ve synthesized your last 30 days of medical data into a professional clinical summary.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: L.sub, height: 1.5),
          ),

          const SizedBox(height: 32),

          // Stats Bento Grid
          Row(
            children: [
              _buildStatCard(L, 'ADHERENCE', '${(widget.adherence * 100).round()}%',
                  Icons.analytics_rounded),
              const SizedBox(width: 16),
              _buildStatCard(L, 'STREAK', '${widget.streak} DAYS',
                  Icons.local_fire_department_rounded),
            ],
          ),

          const SizedBox(height: 32),

          // Info List
          _buildInfoRow(L, Icons.medication_rounded,
              '${widget.state.meds.length} active medications tracked'),
          _buildInfoRow(
              L, Icons.favorite_rounded, 'Biometric trends (Heart Rate, Steps)'),
          _buildInfoRow(L, Icons.assignment_turned_in_rounded,
              'Daily logging checklist & notes'),

          const SizedBox(height: 48),

          // Generate Button
          BouncingButton(
            scaleFactor: 0.95,
            onTap: () async {
              if (_isGenerating) return;
              HapticEngine.selection();
              setState(() => _isGenerating = true);
              
              try {
                // Simulate generation delay for UX
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
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Failed to generate report: $e'),
                    backgroundColor: AppColors.red,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              } finally {
                if (context.mounted) {
                  setState(() => _isGenerating = false);
                  Navigator.pop(context);
                }
              }
            },
            child: Container(
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                gradient: AppGradients.accentOrange,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: _isGenerating 
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.picture_as_pdf_rounded,
                            color: Colors.black, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'GENERATE PDF REPORT',
                          style: AppTypography.labelLarge.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
              ),
            ),
          ).animate().shimmer(
              delay: 1.seconds,
              duration: 2.seconds,
              color: Colors.white.withValues(alpha: 0.3)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      AppThemeColors L, String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: L.card.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: L.border.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: L.text, size: 20),
            const SizedBox(height: 12),
            Text(value,
                style: AppTypography.titleLarge
                    .copyWith(fontWeight: FontWeight.w900, color: L.text)),
            const SizedBox(height: 4),
            Text(label,
                style: AppTypography.labelSmall.copyWith(
                    fontSize: 10,
                    color: L.sub,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(AppThemeColors L, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: L.sub),
          const SizedBox(width: 16),
          Expanded(
            child: Text(text,
                style: AppTypography.bodySmall
                    .copyWith(color: L.text, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
