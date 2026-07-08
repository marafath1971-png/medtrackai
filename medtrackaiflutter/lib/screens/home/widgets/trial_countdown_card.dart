import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../theme/med_ai_ui.dart';
import '../../../providers/app_state.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../services/remote_config_service.dart';

class TrialCountdownCard extends StatelessWidget {
  const TrialCountdownCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final profile = state.profile;

    if (profile == null || profile.isPremium) return const SizedBox.shrink();

    final scansUsed = profile.scansUsed;
    final scanLimit = RemoteConfigService.freeTierScanLimit;
    final remaining = (scanLimit - scansUsed).clamp(0, scanLimit);
    final isExhausted = scansUsed >= scanLimit;
    final L = context.L;
    final reduceMotion = MedAiA11y.reducedMotion(context);

    Widget card = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Semantics(
        button: true,
        label: isExhausted
            ? 'Free scans used. Upgrade to unlock unlimited scanning.'
            : '$remaining of $scanLimit free AI scans remaining. Upgrade to Pro.',
        child: MedAiDepthCard(
          padding: const EdgeInsets.all(AppSpacing.p20),
          onTap: () {
            HapticEngine.selection();
            state.purchasePremium('annual');
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: MedAiA11y.minTapTarget,
                    height: MedAiA11y.minTapTarget,
                    decoration: BoxDecoration(
                      color: L.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Icon(Icons.document_scanner_rounded,
                          color: L.primary, size: 22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isExhausted ? 'Free scans used' : 'Free AI scans',
                          style: AppTypography.titleMedium.copyWith(
                            color: L.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isExhausted
                              ? 'Upgrade to unlock unlimited scanning'
                              : '$remaining of $scanLimit free scans remaining',
                          style: AppTypography.bodySmall.copyWith(
                            color: L.sub,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: L.text,
                      borderRadius: BorderRadius.circular(AppRadius.m),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Text(
                      'Go Pro',
                      style: AppTypography.labelMedium.copyWith(
                        color: L.bg,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: List.generate(scanLimit, (i) {
                  final used = i < scansUsed;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i < scanLimit - 1 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: used
                            ? (isExhausted ? L.error : L.primary)
                            : L.fill.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              if (isExhausted) ...[
                const SizedBox(height: 14),
                MedAiGlass(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  radius: AppRadius.s,
                  tint: L.fill.withValues(alpha: 0.5),
                  child: Row(
                    children: [
                      Icon(Icons.star_rounded, color: L.primary, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Unlock unlimited scans, interaction checks, and more with Pro.',
                          style: AppTypography.bodySmall.copyWith(
                            color: L.sub,
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (reduceMotion) return card;
    return card
        .animate()
        .fadeIn(duration: AppDurations.fast, curve: AppCurves.smooth)
        .slideY(begin: 0.08, end: 0, curve: AppCurves.smooth);
  }
}
