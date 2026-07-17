import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/color_utils.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../core/utils/scan_safety_mapper.dart';
import '../../../providers/app_state.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';

/// Soft pastel medicine cabinet row — name, dose, emergency / important
/// safety cues, body-impact hint, and hopeful “ready for today” framing.
class MedCard extends StatelessWidget {
  final Medicine med;
  final VoidCallback onView;
  final VoidCallback onEdit;

  const MedCard({
    super.key,
    required this.med,
    required this.onView,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final showGeneric = context
        .select<AppState, bool>((s) => s.profile?.showGenericNames ?? false);
    final displayName = (showGeneric && med.genericName.isNotEmpty)
        ? med.genericName
        : med.name;
    final medColor = hexToColor(med.color);
    final isLow = med.count <= med.refillAt;
    final hasDanger = med.hasCriticalSafetyAlerts;
    final profile = med.aiSafetyProfile;
    final warningLine = profile?.warnings.isNotEmpty == true
        ? profile!.warnings.first
        : (profile?.interactions.isNotEmpty == true
            ? profile!.interactions.first
            : null);
    final bodyHint = profile?.mechanismOfAction.trim();
    final shortBody = (bodyHint != null && bodyHint.isNotEmpty)
        ? (bodyHint.length > 72 ? '${bodyHint.substring(0, 72)}…' : bodyHint)
        : null;

    final tint = hasDanger
        ? AppColors.pastelPink
        : isLow
            ? AppColors.pastelSun
            : AppColors.pastelSky;

    // Screen readers must hear the safety status, not just the name — the
    // warning is the point of the card in a medication app (DESIGN.md §6).
    final statusWord = hasDanger
        ? 'Important safety alert'
        : isLow
            ? 'Low stock, refill soon'
            : 'On track';
    final doseSpoken =
        med.dose.isNotEmpty ? ', ${med.dose}' : '';
    final semanticLabel = '$displayName$doseSpoken. $statusWord';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.p8),
      child: Semantics(
        button: true,
        label: semanticLabel,
        hint: 'Double tap to view, long press to edit',
        child: AnimatedPressable(
          onTap: () {
            HapticEngine.selection();
            onView();
          },
          onLongPress: () {
            HapticEngine.selection();
            onEdit();
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.p12),
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(AppRadius.m),
            ),
            // Visual content is excluded from semantics — the parent Semantics
            // above speaks one composed label (name + dose + status) so screen
            // readers don't re-read every chip and line as separate nodes.
            child: ExcludeSemantics(
              child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(AppRadius.s),
                  ),
                  child: Icon(
                    Icons.medication_rounded,
                    size: 22,
                    color: medColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.p12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMedium.copyWith(
                          color: L.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${med.dose.isNotEmpty ? med.dose : '—'} · ${med.form.isNotEmpty ? med.form : 'tablet'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(color: L.sub),
                      ),
                      const SizedBox(height: AppSpacing.p8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (hasDanger)
                            _StatusChip(
                              label: 'Important',
                              color: AppColors.red,
                              icon: Icons.priority_high_rounded,
                            ),
                          if (isLow)
                            _StatusChip(
                              label: 'Refill',
                              color: AppColors.amber,
                              icon: Icons.inventory_2_rounded,
                            ),
                          if (!hasDanger && !isLow)
                            _StatusChip(
                              // Positive daily status → semantic success green.
                              // Sage stays reserved for clinical surfaces (duo).
                              label: 'On track',
                              color: AppColors.successSoft,
                              icon: Icons.check_rounded,
                            ),
                          if (shortBody != null)
                            _StatusChip(
                              // Body-impact is clinical intel → sage domain.
                              label: 'Body impact',
                              color: AppColors.accentDeep,
                              icon: Icons.monitor_heart_outlined,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.p8),
                      Text(
                        hasDanger
                            ? (warningLine != null && warningLine.isNotEmpty
                                ? (warningLine.length > 88
                                    ? '${warningLine.substring(0, 88)}…'
                                    : warningLine)
                                : HopeVibe.sensitiveAlerts)
                            : isLow
                                ? HopeVibe.lowStock(med.count)
                                : (shortBody != null
                                    ? HopeVibe.bodyImpactHint(shortBody)
                                    : HopeVibe.readyForToday),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall.copyWith(
                          color: hasDanger
                              ? AppColors.red
                              : isLow
                                  ? AppColors.amber
                                  : L.sub,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(
                    Icons.arrow_outward_rounded,
                    size: 16,
                    color: L.sub.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
