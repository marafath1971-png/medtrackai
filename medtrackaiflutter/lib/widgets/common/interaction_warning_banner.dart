import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/utils/haptic_engine.dart';
import '../../providers/app_state.dart';
import '../../theme/med_ai_ui.dart';
import 'animated_pressable.dart';

/// Shown after adding a medicine when a drug–drug interaction is detected.
class InteractionWarningBanner extends StatelessWidget {
  const InteractionWarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final warning = state.interactionWarning;
    final medName = state.interactionWarningMedName;

    if (warning == null) return const SizedBox.shrink();

    final reduceMotion = MedAiA11y.reducedMotion(context);

    Widget banner = Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.p12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.p16),
        decoration: BoxDecoration(
          color: AppColors.pastelSun,
          borderRadius: BorderRadius.circular(AppRadius.l),
          border: Border.all(
            color: AppColors.amber.withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(AppRadius.s),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: const Color(0xFF9A6B1F),
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.p12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Drug interaction',
                    style: AppTypography.labelMedium.copyWith(
                      color: const Color(0xFF9A6B1F),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.p4),
                  Text(
                    warning,
                    style: AppTypography.bodyMedium.copyWith(
                      color: const Color(0xFF1A1D26),
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.p8),
                  Text(
                    'Review with your doctor or pharmacist before taking ${medName ?? 'this medicine'}.',
                    style: AppTypography.bodySmall.copyWith(
                      color: const Color(0xFF5C6570),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Semantics(
              button: true,
              label: 'Dismiss interaction warning',
              child: AnimatedPressable(
                onTap: () {
                  HapticEngine.selection();
                  context.read<AppState>().clearInteractionWarning();
                },
                child: const Padding(
                  padding: EdgeInsetsDirectional.only(start: 4),
                  child: Icon(Icons.close_rounded,
                      size: 20, color: Color(0xFF5C6570)),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (reduceMotion) return banner;
    return banner
        .animate()
        .fadeIn(duration: AppDurations.fast)
        .slideY(begin: -0.06, end: 0, curve: AppCurves.smooth);
  }
}
