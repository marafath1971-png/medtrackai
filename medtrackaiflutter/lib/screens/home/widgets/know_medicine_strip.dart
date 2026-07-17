import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/scan_safety_mapper.dart';
import '../../../providers/app_state.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';
import '../../../widgets/common/interaction_warning_banner.dart';

/// Home awareness strip — interaction banner + today’s “know before take” cue.
class KnowMedicineStrip extends StatelessWidget {
  final VoidCallback? onReviewFirst;

  const KnowMedicineStrip({super.key, this.onReviewFirst});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final meds = context.select<AppState, List<Medicine>>((s) => s.meds);
    final critical = meds.where((m) => m.hasCriticalSafetyAlerts).toList();
    final briefing = meds.where((m) => m.needsPreTakeBriefing).toList();

    if (critical.isEmpty && briefing.isEmpty) {
      return const InteractionWarningBanner();
    }

    final focus = critical.isNotEmpty ? critical : briefing;
    final isCritical = critical.isNotEmpty;
    final tint = isCritical ? AppColors.pastelPink : AppColors.pastelSun;
    final accent =
        isCritical ? const Color(0xFF9B3D45) : const Color(0xFF9A6B1F);
    final title =
        isCritical ? HopeVibe.stripCriticalTitle : HopeVibe.stripSoftTitle;
    final subtitle = focus.length == 1
        ? isCritical
            ? '${focus.first.name} has important alerts — review with confidence'
            : '${focus.first.name} has a clarity tip before this dose'
        : isCritical
            ? '${focus.length} medicines need a safety review — you’ve got this'
            : '${focus.length} medicines have take tips to help you succeed';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const InteractionWarningBanner(),
        AnimatedPressable(
          onTap: onReviewFirst,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.p16),
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(AppRadius.l),
              border: Border.all(color: accent.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(AppRadius.s),
                  ),
                  child: Icon(
                    isCritical
                        ? Icons.shield_rounded
                        : Icons.menu_book_rounded,
                    size: 22,
                    color: accent,
                  ),
                ),
                const SizedBox(width: AppSpacing.p12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.titleMedium.copyWith(
                          color: L.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.p4),
                      Text(
                        subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: L.sub,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.p8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
