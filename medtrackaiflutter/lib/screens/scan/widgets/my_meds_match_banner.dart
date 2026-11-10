import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/haptic_engine.dart';
import '../../../core/utils/pill_matcher.dart';
import '../../../providers/app_state.dart';
import '../../../theme/med_ai_ui.dart';

/// "Is this one of my pills?" — the verdict of [matchScannedPill], shown on
/// top of a pill scan result, with one-tap logging when it is the dose due.
///
/// Logging is only offered for a confident match. A low-confidence or
/// wrong-strength result asks the user to check first: this banner may make a
/// match easier to act on, but never easier to act on wrongly.
class MyMedsMatchBanner extends StatefulWidget {
  final PillMatch match;
  const MyMedsMatchBanner({super.key, required this.match});

  @override
  State<MyMedsMatchBanner> createState() => _MyMedsMatchBannerState();
}

class _MyMedsMatchBannerState extends State<MyMedsMatchBanner> {
  bool _logging = false;
  String? _loggedLabel;

  String _clock(DoseItem d) {
    final h = d.sched.h % 12 == 0 ? 12 : d.sched.h % 12;
    final ampm = d.sched.h < 12 ? 'AM' : 'PM';
    return '$h:${d.sched.m.toString().padLeft(2, '0')} $ampm';
  }

  Future<void> _log(AppState state, DoseItem dose) async {
    setState(() => _logging = true);
    HapticEngine.medium();
    try {
      await state.toggleDose(dose);
      if (!mounted) return;
      HapticEngine.success();
      setState(() => _loggedLabel = dose.sched.label);
    } finally {
      if (mounted) setState(() => _logging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final m = widget.match;
    final state = context.watch<AppState>();

    final Color tint;
    final IconData icon;
    final String title;
    final String body;
    DoseItem? due;

    switch (m.kind) {
      case PillMatchKind.unidentified:
        return const SizedBox.shrink();
      case PillMatchKind.notMine:
        if (state.meds.isEmpty) return const SizedBox.shrink();
        tint = L.fill;
        icon = Icons.help_outline_rounded;
        title = 'Not one of your medicines';
        body = 'Nothing in your list matches this pill. If you expected it to '
            'be one of yours, don\'t take it until you\'ve checked the label '
            'or asked a pharmacist. If it\'s new, you can add it below.';
      case PillMatchKind.strengthMismatch:
        tint = context.isDark
            ? AppColors.red.withValues(alpha: 0.16)
            : const Color(0xFFFFEEEC);
        icon = Icons.report_rounded;
        title = 'Different from your ${m.med!.name}';
        body =
            'This looks like ${m.scannedStrength.isEmpty ? 'a different strength' : m.scannedStrength}, '
            'but your list says ${m.listedStrength.isEmpty ? 'something else' : m.listedStrength}. '
            'Don\'t take it until a pharmacist confirms which is right.';
      case PillMatchKind.match when !m.confident:
        tint = context.isDark
            ? AppColors.amber.withValues(alpha: 0.16)
            : AppColors.pastelSun;
        icon = Icons.visibility_rounded;
        title = 'Might be your ${m.med!.name}';
        body = 'The scan wasn\'t certain. Compare the imprint on the pill '
            'with your pharmacy label before taking it.';
      case PillMatchKind.match:
        tint = context.isDark
            ? AppColors.limeDeep.withValues(alpha: 0.16)
            : AppColors.pastelMint;
        icon = Icons.verified_rounded;
        title = 'This is your ${m.med!.name}';
        body = m.strengthVerified
            ? '${m.scannedStrength} matches your list. As always, the '
                'imprint should match your pharmacy label.'
            : 'The name matches your list, but the strength wasn\'t '
                'readable — check the label before taking it.';
        due = doseToLog(
          doses: state.getDoses(),
          takenToday: state.takenToday,
          medId: m.med!.id,
          now: DateTime.now(),
        );
    }

    return Semantics(
      container: true,
      label: '$title. $body',
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.p16),
        padding: const EdgeInsets.all(AppSpacing.p16),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(AppRadius.l),
          border: Border.all(color: L.border.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: L.text, size: 22),
                const SizedBox(width: AppSpacing.p12),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style:
                  AppTypography.bodySmall.copyWith(color: L.sub, height: 1.4),
            ),
            if (_loggedLabel != null) ...[
              const SizedBox(height: AppSpacing.p12),
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.limeDeep, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '$_loggedLabel dose logged',
                    style: AppTypography.labelMedium.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ] else if (due != null) ...[
              const SizedBox(height: AppSpacing.p12),
              MedAiCTA(
                label: 'Log ${due.sched.label} dose · ${_clock(due)}',
                icon: Icons.check_rounded,
                loading: _logging,
                onTap: _logging ? null : () => _log(state, due!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
