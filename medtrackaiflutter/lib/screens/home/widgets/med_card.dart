import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/color_utils.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../core/utils/scan_safety_mapper.dart';
import '../../../providers/app_state.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';
import '../../../widgets/shared/shared_widgets.dart' show MedImage;

/// Soft pastel medicine cabinet row — name, dose, and icon-led important
/// cues (warnings, how-to-take, next dose, body impact) so users feel hooked
/// and informed at a glance.
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

  static String _clip(String raw, [int max = 56]) {
    final t = raw.trim();
    if (t.isEmpty) return '';
    if (t.length <= max) return t;
    return '${t.substring(0, max).trimRight()}…';
  }

  /// Priority-ordered hooks — max 3 so the card stays glanceable.
  static List<_MedInfoCue> _importantCues(Medicine med, BuildContext context) {
    final profile = med.aiSafetyProfile;
    final cues = <_MedInfoCue>[];

    void add(IconData icon, String text, Color color) {
      final clipped = _clip(text);
      if (clipped.isEmpty || cues.length >= 3) return;
      if (cues.any((c) => c.text == clipped)) return;
      cues.add(_MedInfoCue(icon: icon, text: clipped, color: color));
    }

    if (med.isCritical) {
      add(
        Icons.emergency_rounded,
        'Critical med — review before every dose',
        AppColors.red,
      );
    }

    final warning = profile?.warnings.isNotEmpty == true
        ? profile!.warnings.first
        : null;
    if (warning != null) {
      add(Icons.priority_high_rounded, warning, AppColors.red);
    }

    final interaction = profile?.interactions.isNotEmpty == true
        ? profile!.interactions.first
        : null;
    if (interaction != null) {
      add(Icons.science_outlined, interaction, AppColors.accentDeep);
    }

    final food = profile?.foodRules.isNotEmpty == true
        ? profile!.foodRules.first
        : (med.intakeInstructions.isNotEmpty &&
                med.intakeInstructions != 'None'
            ? med.intakeInstructions
            : null);
    if (food != null) {
      add(Icons.restaurant_rounded, food, AppColors.inkStrong);
    }

    final next = _nextDoseCue(med, context);
    if (next != null) {
      add(Icons.schedule_rounded, next, AppColors.limeDeep);
    }

    final body = profile?.mechanismOfAction.trim();
    final bodyOk = body != null &&
        body.isNotEmpty &&
        !body.startsWith('Details about how this medication');
    if (bodyOk) {
      add(Icons.monitor_heart_outlined, body, AppColors.accentDeep);
    } else if (profile?.ahaMoments.isNotEmpty == true) {
      add(
        Icons.lightbulb_outline_rounded,
        profile!.ahaMoments.first,
        AppColors.accentDeep,
      );
    } else if (profile?.bodySystems.isNotEmpty == true) {
      add(
        Icons.accessibility_new_rounded,
        'Supports ${profile!.bodySystems.first}',
        AppColors.accentDeep,
      );
    }

    if (med.count <= med.refillAt && cues.length < 3) {
      add(
        Icons.inventory_2_rounded,
        HopeVibe.lowStock(med.count),
        AppColors.amber,
      );
    }

    if (cues.isEmpty) {
      add(
        Icons.check_circle_outline_rounded,
        HopeVibe.readyForToday,
        AppColors.successSoft,
      );
    }

    return cues;
  }

  static String? _nextDoseCue(Medicine med, BuildContext context) {
    final enabled = med.schedule.where((s) => s.enabled).toList();
    if (enabled.isEmpty) return null;

    final now = DateTime.now();
    final todayIdx = dayIdx();
    final nowM = now.hour * 60 + now.minute;
    final today = enabled.where((s) => s.days.contains(todayIdx)).toList()
      ..sort((a, b) => (a.h * 60 + a.m).compareTo(b.h * 60 + b.m));

    for (final s in today) {
      if (s.h * 60 + s.m >= nowM) {
        return 'Next dose · ${fmtTime(s.h, s.m, context)}';
      }
    }
    if (today.isNotEmpty) {
      return 'Today\'s doses done · ${med.frequency}';
    }

    final first = enabled.first;
    return '${med.frequency} · ${fmtTime(first.h, first.m, context)}';
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final showGeneric = context
        .select<AppState, bool>((s) => s.profile?.showGenericNames ?? false);
    final rawName = (showGeneric && med.genericName.isNotEmpty)
        ? med.genericName
        : med.name;
    final displayName =
        rawName.trim().isNotEmpty ? rawName.trim() : 'Untitled medicine';
    final medColor = hexToColor(med.color);
    final isLow = med.count <= med.refillAt;
    final hasDanger = med.hasCriticalSafetyAlerts || med.isCritical;
    final profile = med.aiSafetyProfile;
    final hasBody = () {
      final m = profile?.mechanismOfAction.trim() ?? '';
      return m.isNotEmpty && !m.startsWith('Details about how this medication');
    }();
    final cues = _importantCues(med, context);

    final tint = hasDanger
        ? AppColors.pastelPink
        : isLow
            ? AppColors.pastelSun
            : AppColors.pastelSky;
    // Pastel fills stay light in dark mode — always use dark ink on them.
    const ink = AppColors.inkStrong;
    const inkSub = AppColors.grey600;

    final statusWord = hasDanger
        ? 'Important safety alert'
        : isLow
            ? 'Low stock, refill soon'
            : 'On track';
    final doseSpoken = med.dose.isNotEmpty ? ', ${med.dose}' : '';
    final cueSpoken = cues.map((c) => c.text).join('. ');
    final semanticLabel = '$displayName$doseSpoken. $statusWord. $cueSpoken';
    final doseLine = [
      if (med.dose.isNotEmpty) med.dose,
      if (med.form.isNotEmpty) med.form,
    ].join(' · ');
    final doseLabel = doseLine.isNotEmpty ? doseLine : 'Details coming soon';

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
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: hasDanger
                    ? AppColors.red.withValues(alpha: 0.22)
                    : L.border.withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.eatoNavy.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ExcludeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 56,
                    decoration: BoxDecoration(
                      color: hasDanger
                          ? AppColors.red
                          : isLow
                              ? AppColors.amber
                              : AppColors.limeDeep,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: tint.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: MedImage(
                      imageUrl: med.imageUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      borderRadius: 14,
                      placeholder: Center(
                        child: Icon(
                          Icons.medication_rounded,
                          size: 24,
                          color: medColor,
                        ),
                      ),
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
                            color: ink,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          doseLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              AppTypography.bodySmall.copyWith(color: inkSub),
                        ),
                        const SizedBox(height: AppSpacing.p8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (hasDanger)
                              const _StatusChip(
                                label: 'Important',
                                color: AppColors.red,
                                icon: Icons.priority_high_rounded,
                              ),
                            if (isLow)
                              const _StatusChip(
                                label: 'Refill',
                                color: AppColors.amber,
                                icon: Icons.inventory_2_rounded,
                              ),
                            if (!hasDanger && !isLow)
                              const _StatusChip(
                                label: 'On track',
                                color: AppColors.successSoft,
                                icon: Icons.check_rounded,
                              ),
                            if (hasBody)
                              const _StatusChip(
                                label: 'Body impact',
                                color: AppColors.accentDeep,
                                icon: Icons.monitor_heart_outlined,
                              ),
                            if (profile?.foodRules.isNotEmpty == true ||
                                (med.intakeInstructions.isNotEmpty &&
                                    med.intakeInstructions != 'None'))
                              const _StatusChip(
                                label: 'How to take',
                                color: AppColors.inkStrong,
                                icon: Icons.restaurant_rounded,
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.p8),
                        ...cues.map(
                          (cue) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _InfoCueRow(cue: cue),
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
                      color: AppColors.inkStrong.withValues(alpha: 0.35),
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

class _MedInfoCue {
  final IconData icon;
  final String text;
  final Color color;

  const _MedInfoCue({
    required this.icon,
    required this.text,
    required this.color,
  });
}

class _InfoCueRow extends StatelessWidget {
  final _MedInfoCue cue;

  const _InfoCueRow({required this.cue});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: cue.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(cue.icon, size: 13, color: cue.color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            cue.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.inkStrong,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
      ],
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
        color: color.withValues(alpha: 0.12),
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
