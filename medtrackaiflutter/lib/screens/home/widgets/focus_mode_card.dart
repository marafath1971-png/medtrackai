import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../l10n/app_localizations.dart';

class FocusModeCard extends StatelessWidget {
  const FocusModeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final L = context.L;
    final icon = Container(
      width: MedAiA11y.minTapTarget,
      height: MedAiA11y.minTapTarget,
      decoration: BoxDecoration(
        color: AppColors.cyanAccent.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(Icons.self_improvement_rounded,
            color: AppColors.cyanAccent, size: 24),
      ),
    );

    return Semantics(
      button: true,
      label: l10n.homeFocusModeBreatheRelaxAndCenter,
      child: MedAiDepthCard(
        accentGlow: false,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.p20),
        onTap: () {
          HapticEngine.selection();
          context.push(AppRoutes.focusMode);
        },
        child: Row(
          children: [
            icon,
            const SizedBox(width: AppSpacing.p16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.focusFocusMode,
                    style: AppTypography.titleMedium.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.p4),
                  Text(
                    l10n.homeBreatheRelaxAndCenterYourself,
                    style: AppTypography.bodySmall.copyWith(
                      color: L.sub.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: L.bg,
                shape: BoxShape.circle,
                border: Border.all(color: L.border.withValues(alpha: 0.1)),
              ),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  color: L.text, size: 12),
            ),
          ],
        ),
      ),
    );
  }
}
