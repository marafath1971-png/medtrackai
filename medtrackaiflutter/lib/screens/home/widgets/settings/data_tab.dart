import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../models/constants.dart';
import '../../../../providers/app_state.dart';
import '../../../../services/export_service.dart';
import '../../../../theme/med_ai_ui.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/haptic_engine.dart';
import '../../../paywall/premium_paywall_overlay.dart';
import 'settings_shared.dart';

class DataTab extends StatefulWidget {
  final AppState state;
  final AppThemeColors L;
  final VoidCallback onClose;

  const DataTab({
    super.key,
    required this.state,
    required this.L,
    required this.onClose,
  });

  @override
  State<DataTab> createState() => _DataTabState();
}

class _DataTabState extends State<DataTab> {
  bool _confirming = false;

  Future<void> _exportCSV() async {
    await widget.state.exportDataCSV();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final L = widget.L;
    final s = AppLocalizations.of(context)!;
    final reduceMotion = MedAiA11y.reducedMotion(context);

    final history = context
        .select<AppState, Map<String, List<DoseEntry>>>((s) => s.history);
    final medsCount = context.select<AppState, int>((s) => s.meds.length);

    final totalTaken =
        history.values.expand((e) => e).where((e) => e.taken).length;
    final totalDoses = history.values.expand((e) => e).length;
    final daysTracked = history.keys.length;
    final symptomsCount =
        context.select<AppState, int>((s) => s.symptoms.length);

    Widget heroCard = MedAiDepthCard(
      padding: const EdgeInsets.all(AppSpacing.p24),
      radius: 28,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Your data',
                style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: L.text,
                    letterSpacing: -0.2)),
            Icon(Icons.analytics_rounded, color: L.text, size: 16),
          ],
        ),
        const SizedBox(height: AppSpacing.p20),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: [
            _SummaryBox(l: s.dataMedicinesLabel, v: '$medsCount', L: L),
            _SummaryBox(l: 'Symptoms', v: '$symptomsCount', L: L),
            _SummaryBox(l: s.dataDaysTrackedLabel, v: '$daysTracked', L: L),
            _SummaryBox(l: s.dataDosesLoggedLabel, v: '$totalDoses', L: L),
          ],
        ),
      ]),
    );
    if (!reduceMotion) {
      heroCard = heroCard
          .animate()
          .fadeIn(duration: AppDurations.fast, curve: AppCurves.smooth);
    }

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.p4, 0, AppSpacing.p40),
      child: Column(children: [
        heroCard,
        const SizedBox(height: AppSpacing.p16),

        SettingsSection(
            title: s.exportAndBackup,
            child: Column(children: [
              SettingsModalRow(
                  icon: '📄',
                  iconBg: AppColors.pastelSky,
                  label: s.exportPdfReport,
                  sub: s.exportPdfSubtitle,
                  onClick: () async {
                    final success = await ExportService.exportAdherenceReport(
                        context.read<AppState>());
                    if (!success && context.mounted) {
                      PremiumPaywallOverlay.show(
                        context,
                        triggerSource: 'export_pdf',
                      );
                    }
                  },
                  border: true),
              SettingsModalRow(
                  icon: '📥',
                  iconBg: const Color(0xFF22C55E).withValues(alpha: 0.1),
                  label: s.exportCsv,
                  sub: s.exportCsvSubtitle(totalTaken),
                  onClick: _exportCSV,
                  border: false),
            ])),

        SettingsSection(
            title: s.resetSection,
            child: SettingsModalRow(
                icon: '🗑️',
                iconBg: const Color(0xFFEF4444).withValues(alpha: 0.1),
                label: s.deleteAllData,
                sub: s.deleteAllDataSubtitle,
                onClick: () => setState(() => _confirming = true),
                border: false)),

        if (_confirming) ...[
          const SizedBox(height: AppSpacing.p12),
          MedAiDepthCard(
            padding: const EdgeInsets.all(AppSpacing.p16),
            radius: 24,
            color: L.card,
            child: Column(children: [
              Text(s.deleteConfirmTitle,
                  style: AppTypography.titleMedium
                      .copyWith(fontWeight: FontWeight.w800, color: L.red)),
              const SizedBox(height: AppSpacing.p8),
              Text(s.deleteConfirmBody,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(color: L.sub)),
              const SizedBox(height: AppSpacing.p16),
              Row(children: [
                Expanded(
                  child: MedAiCTA(
                    label: s.cancel,
                    secondary: true,
                    onTap: () {
                      HapticEngine.selection();
                      setState(() => _confirming = false);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.p8),
                Expanded(
                  child: Semantics(
                    button: true,
                    label: s.deleteAllData,
                    child: MedAiDepthCard(
                      color: L.red,
                      radius: AppRadius.max,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.p16),
                      onTap: () {
                        HapticEngine.alertWarning();
                        context.read<AppState>().deleteAllData();
                        widget.onClose();
                      },
                      child: Center(
                        child: Text(s.deleteButton,
                            style: AppTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ]),
            ]),
          ),
        ],

        const SizedBox(height: AppSpacing.p16),

        SettingsSection(
            title: s.legalSection,
            child: Column(children: [
              SettingsModalRow(
                  icon: '🔐',
                  iconBg: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                  label: s.privacyPolicy,
                  sub: s.privacyPolicySubtitle,
                  onClick: () => _launchUrl(kPrivacyPolicyUrl),
                  border: true),
              SettingsModalRow(
                  icon: '⚖️',
                  iconBg: AppColors.pastelMint,
                  label: s.termsOfService,
                  sub: s.termsOfServiceSubtitle,
                  onClick: () => _launchUrl(kTermsOfServiceUrl),
                  border: false),
            ])),

        const SizedBox(height: AppSpacing.p16),

        Center(
          child: Text('${s.appVersionLabel}: ${s.appVersionValue}',
              style: AppTypography.labelSmall
                  .copyWith(color: L.sub, letterSpacing: 0.5)),
        ),
        const SizedBox(height: 80),
      ]),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String l, v;
  final AppThemeColors L;
  const _SummaryBox({required this.l, required this.v, required this.L});
  @override
  Widget build(BuildContext context) {
    return MedAiDepthCard(
      padding: const EdgeInsets.all(AppSpacing.p12),
      radius: 16,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(v,
                style: AppTypography.displaySmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: L.text,
                    fontSize: 24,
                    letterSpacing: -0.5)),
            const SizedBox(height: 2),
            Text(l,
                style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: L.sub,
                    fontSize: 11,
                    letterSpacing: 0.1)),
          ]),
    );
  }
}
