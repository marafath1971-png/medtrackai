import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/utils/haptic_engine.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../providers/app_state.dart';

class HomeMissedAlertsBanner extends StatelessWidget {
  final AppState state;
  final AppThemeColors L;

  const HomeMissedAlertsBanner({
    super.key,
    required this.state,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MedAiA11y.reducedMotion(context);

    Widget banner = Semantics(
      button: true,
      label: 'Missed doses. Tap to clear recent alerts.',
      child: MedAiDepthCard(
        padding: const EdgeInsets.all(AppSpacing.p16),
        onTap: () {
          HapticEngine.alertWarning();
          state.markAlertsAsSeen();
        },
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: L.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.notifications_active_rounded,
                  color: L.error, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Missed doses',
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: L.text,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to clear recent alerts',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: L.sub,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: L.sub.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );

    if (reduceMotion) return banner;
    return banner
        .animate()
        .fadeIn(duration: AppDurations.fast)
        .slideY(begin: -0.1, end: 0);
  }
}

class HomeLowStockBanner extends StatelessWidget {
  final AppState state;
  final AppThemeColors L;
  final VoidCallback onTap;

  const HomeLowStockBanner({
    super.key,
    required this.state,
    required this.L,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lowMeds = state.getLowMeds();
    if (lowMeds.isEmpty) return const SizedBox();

    final reduceMotion = MedAiA11y.reducedMotion(context);

    Widget banner = Semantics(
      button: true,
      label:
          '${lowMeds.length} ${lowMeds.length == 1 ? 'item' : 'items'} low on stock. Tap to review.',
      child: MedAiDepthCard(
        padding: const EdgeInsets.all(AppSpacing.p20),
        accentGlow: true,
        onTap: () {
          HapticEngine.selection();
          onTap();
        },
        child: Row(
          children: [
            Container(
              width: MedAiA11y.minTapTarget,
              height: MedAiA11y.minTapTarget,
              decoration: BoxDecoration(
                color: L.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.medication_liquid_rounded,
                  color: L.error, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: L.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Needs attention',
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: L.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${lowMeds.length} ${lowMeds.length == 1 ? 'item' : 'items'} low on stock',
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: L.text,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to review and restock before you run out.',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 12,
                      color: L.sub,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: L.sub.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );

    banner = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: banner,
    );

    if (reduceMotion) return banner;
    return banner
        .animate()
        .fadeIn(duration: AppDurations.fast, curve: AppCurves.smooth)
        .slideY(begin: 0.1, end: 0, curve: AppCurves.smooth);
  }
}
