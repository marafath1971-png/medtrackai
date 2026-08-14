import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/scan_safety_mapper.dart';
import '../../../providers/app_state.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';
import '../../../widgets/common/interaction_warning_banner.dart';

/// Home awareness strip — interaction banner + today’s “know before take” cue
/// with icon chips for the kinds of important info waiting.
class KnowMedicineStrip extends StatelessWidget {
  final VoidCallback? onReviewFirst;

  const KnowMedicineStrip({super.key, this.onReviewFirst});

  @override
  Widget build(BuildContext context) {
    final meds = context.select<AppState, List<Medicine>>((s) => s.meds);
    final critical = meds.where((m) => m.hasCriticalSafetyAlerts).toList();
    final briefing = meds.where((m) => m.needsPreTakeBriefing).toList();

    if (critical.isEmpty && briefing.isEmpty) {
      return const InteractionWarningBanner();
    }

    final focus = critical.isNotEmpty ? critical : briefing;
    final isCritical = critical.isNotEmpty;
    final tint = isCritical ? AppColors.pastelPink : AppColors.pastelSun;
    final accent = isCritical ? AppColors.red : AppColors.amber;
    // Pastel fills stay light — use dark ink, not theme text.
    const ink = AppColors.inkStrong;
    const inkSub = AppColors.grey600;

    final title =
        isCritical ? HopeVibe.stripCriticalTitle : HopeVibe.stripSoftTitle;
    final lead = focus.first;
    final profile = lead.aiSafetyProfile;
    final hookLine = () {
      if (profile?.warnings.isNotEmpty == true) {
        return profile!.warnings.first;
      }
      if (profile?.interactions.isNotEmpty == true) {
        return profile!.interactions.first;
      }
      if (profile?.foodRules.isNotEmpty == true) {
        return profile!.foodRules.first;
      }
      return isCritical
          ? '${lead.name} has important alerts — review with confidence'
          : '${lead.name} has a clarity tip before this dose';
    }();
    final clippedHook = hookLine.length > 88
        ? '${hookLine.substring(0, 88).trimRight()}…'
        : hookLine;

    final chips = <({IconData icon, String label})>[
      if (focus.any((m) => m.aiSafetyProfile?.warnings.isNotEmpty == true))
        (icon: Icons.priority_high_rounded, label: 'Warning'),
      if (focus.any((m) => m.aiSafetyProfile?.interactions.isNotEmpty == true))
        (icon: Icons.science_outlined, label: 'Interaction'),
      if (focus.any((m) =>
          m.aiSafetyProfile?.foodRules.isNotEmpty == true ||
          (m.intakeInstructions.isNotEmpty &&
              m.intakeInstructions != 'None')))
        (icon: Icons.restaurant_rounded, label: 'How to take'),
      if (focus.length > 1)
        (icon: Icons.medication_rounded, label: '${focus.length} meds'),
    ];

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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                          color: ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.p4),
                      Text(
                        clippedHook,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: inkSub,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (chips.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.p8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: chips
                              .take(3)
                              .map(
                                (c) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.72),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(c.icon, size: 11, color: accent),
                                      const SizedBox(width: 4),
                                      Text(
                                        c.label,
                                        style:
                                            AppTypography.caption.copyWith(
                                          color: accent,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
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
