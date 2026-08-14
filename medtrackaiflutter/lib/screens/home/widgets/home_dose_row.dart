import 'package:flutter/material.dart';

import '../../../core/utils/color_utils.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../core/utils/scan_safety_mapper.dart';
import '../../../providers/app_state.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';
import '../../../widgets/shared/shared_widgets.dart' show MedImage;

/// Beautiful-minimal dose card — photo thumb, clear hierarchy, lime take.
class HomeDoseRow extends StatelessWidget {
  final Medicine med;
  final ScheduleEntry sched;
  final bool taken;
  final bool overdue;
  final VoidCallback onTake;
  final VoidCallback onTap;

  const HomeDoseRow({
    super.key,
    required this.med,
    required this.sched,
    required this.taken,
    required this.overdue,
    required this.onTake,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final medColor = hexToColor(med.color);
    final timeLabel = fmtTime(sched.h, sched.m, context);
    final subtitle = [
      if (med.dose.isNotEmpty) med.dose,
      if (med.form.isNotEmpty) med.form,
    ].join(' · ');
    final displayName =
        med.name.trim().isNotEmpty ? med.name.trim() : 'Untitled medicine';

    final doseStatus = taken
        ? 'Taken'
        : overdue
            ? 'Overdue'
            : 'Due $timeLabel';
    final hook = taken ? null : _doseHook(med);
    final reviewNote = hook != null ? '. ${hook.text}' : '';

    final borderColor = taken
        ? L.border.withValues(alpha: 0.35)
        : overdue
            ? AppColors.red.withValues(alpha: 0.28)
            : AppColors.limeDeep.withValues(alpha: 0.18);

    return Semantics(
      button: true,
      label: '$displayName, $timeLabel. $doseStatus$reviewNote',
      child: AnimatedPressable(
        onTap: () {
          HapticEngine.selection();
          onTap();
        },
        scaleFactor: 0.98,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: taken ? L.card.withValues(alpha: 0.72) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: taken
                ? null
                : [
                    BoxShadow(
                      color: AppColors.eatoNavy.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Soft left accent for due / overdue
              Container(
                width: 4,
                height: 52,
                decoration: BoxDecoration(
                  color: taken
                      ? AppColors.lime.withValues(alpha: 0.45)
                      : overdue
                          ? AppColors.red
                          : AppColors.limeDeep,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: MedImage(
                    imageUrl: med.imageUrl,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    borderRadius: 14,
                    placeholder: ColoredBox(
                      color: Color.lerp(medColor, Colors.white, 0.82) ??
                          AppColors.pastelMint,
                      child: Icon(
                        Icons.medication_rounded,
                        size: 24,
                        color: medColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        color: taken
                            ? L.text.withValues(alpha: 0.45)
                            : AppColors.inkStrong,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        decoration:
                            taken ? TextDecoration.lineThrough : null,
                        decorationColor: L.text.withValues(alpha: 0.25),
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.grey600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: taken
                                ? AppColors.pastelMint
                                : overdue
                                    ? AppColors.pastelPink
                                    : AppColors.pastelSun,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            timeLabel,
                            style: AppTypography.labelSmall.copyWith(
                              color: taken
                                  ? AppColors.limeInk
                                  : overdue
                                      ? AppColors.red
                                      : const Color(0xFF8A6A1A),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (hook != null) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Row(
                              children: [
                                Icon(hook.icon, size: 12, color: hook.color),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    hook.text,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: hook.color,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _TakeButton(taken: taken, overdue: overdue, onTake: onTake),
            ],
          ),
        ),
      ),
    );
  }

  static ({IconData icon, String text, Color color})? _doseHook(Medicine med) {
    String clip(String raw) {
      final t = raw.trim();
      if (t.length <= 36) return t;
      return '${t.substring(0, 36).trimRight()}…';
    }

    final profile = med.aiSafetyProfile;
    if (med.isCritical || med.hasCriticalSafetyAlerts) {
      final warning = profile?.warnings.isNotEmpty == true
          ? profile!.warnings.first
          : (profile?.interactions.isNotEmpty == true
              ? profile!.interactions.first
              : 'Review before take');
      return (
        icon: Icons.priority_high_rounded,
        text: clip(warning),
        color: AppColors.red,
      );
    }

    final food = profile?.foodRules.isNotEmpty == true
        ? profile!.foodRules.first
        : (med.intakeInstructions.isNotEmpty &&
                med.intakeInstructions != 'None'
            ? med.intakeInstructions
            : null);
    if (food != null) {
      return (
        icon: Icons.restaurant_rounded,
        text: clip(food),
        color: AppColors.accentDeep,
      );
    }

    if (med.needsPreTakeBriefing) {
      return (
        icon: Icons.menu_book_rounded,
        text: 'Know before take',
        color: AppColors.amber,
      );
    }
    return null;
  }
}

class _TakeButton extends StatelessWidget {
  final bool taken;
  final bool overdue;
  final VoidCallback onTake;

  const _TakeButton({
    required this.taken,
    required this.overdue,
    required this.onTake,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !taken,
      label: taken ? 'Dose taken' : 'Mark dose taken',
      child: AnimatedPressable(
        onTap: taken
            ? null
            : () {
                HapticEngine.doseTaken();
                onTake();
              },
        child: Container(
          width: MedAiA11y.minTapTargetCompact,
          height: MedAiA11y.minTapTargetCompact,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: taken
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.lime, AppColors.limeDeep],
                  )
                : null,
            color: taken ? null : Colors.white,
            border: taken
                ? null
                : Border.all(
                    color: overdue
                        ? AppColors.red.withValues(alpha: 0.55)
                        : AppColors.limeDeep.withValues(alpha: 0.55),
                    width: 2.2,
                  ),
            boxShadow: taken
                ? null
                : [
                    BoxShadow(
                      color: (overdue ? AppColors.red : AppColors.limeDeep)
                          .withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: taken
              ? const Icon(Icons.check_rounded,
                  color: AppColors.limeInk, size: 18)
              : Icon(
                  Icons.add_rounded,
                  color: overdue ? AppColors.red : AppColors.limeDeep,
                  size: 20,
                ),
        ),
      ),
    );
  }
}
