import 'package:flutter/material.dart';

import '../../../core/utils/color_utils.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../core/utils/scan_safety_mapper.dart';
import '../../../providers/app_state.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';
import '../../../widgets/common/premium_texture.dart';

/// Reference-style dose card — vial, info, time, take circle.
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

  static Color _vialTint(Color medColor) {
    return Color.lerp(medColor, Colors.white, 0.82) ?? medColor;
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final medColor = hexToColor(med.color);
    final vialBg = _vialTint(medColor);
    final timeLabel = fmtTime(sched.h, sched.m, context);
    final subtitle = [
      if (med.dose.isNotEmpty) med.dose,
      if (med.form.isNotEmpty) med.form,
    ].join(' · ');

    final doseStatus = taken
        ? 'Taken'
        : overdue
            ? 'Overdue'
            : 'Due $timeLabel';
    final reviewNote = (!taken && med.hasCriticalSafetyAlerts)
        ? '. Review before taking'
        : '';

    return Semantics(
      button: true,
      label: '${med.name}, $timeLabel. $doseStatus$reviewNote',
      child: AnimatedPressable(
        onTap: () {
          HapticEngine.selection();
          onTap();
        },
        scaleFactor: 0.98,
        child: PremiumTextureCard(
          padding: const EdgeInsets.all(AppSpacing.p16),
          radius: AppRadius.l,
          texture: PremiumTextureStyle.fineGrain,
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: vialBg,
                  borderRadius: BorderRadius.circular(AppRadius.m),
                ),
                child: Icon(
                  Icons.medication_rounded,
                  size: 24,
                  color: medColor,
                ),
              ),
              const SizedBox(width: AppSpacing.p16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        color: taken ? L.text.withValues(alpha: 0.4) : L.text,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
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
                          color: L.sub,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (!taken && med.hasCriticalSafetyAlerts) ...[
                      const SizedBox(height: AppSpacing.p4),
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 12, color: AppColors.amber),
                          const SizedBox(width: 4),
                          Text(
                            'Review before take',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.amber,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(
                width: 52,
                child: Text(
                  timeLabel,
                  textAlign: TextAlign.end,
                  style: AppTypography.bodySmall.copyWith(
                    color: overdue && !taken
                        ? L.error
                        : L.sub.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.p12),
              _TakeButton(taken: taken, onTake: onTake),
            ],
          ),
        ),
      ),
    );
  }
}

class _TakeButton extends StatelessWidget {
  final bool taken;
  final VoidCallback onTake;

  const _TakeButton({required this.taken, required this.onTake});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
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
            color: taken ? null : L.card,
            border: taken
                ? null
                : Border.all(
                    color: L.border.withValues(alpha: 0.65),
                    width: 2,
                  ),
          ),
          // Dark ink on lime — lime is light, white check fails WCAG (DESIGN.md).
          child: taken
              ? const Icon(Icons.check_rounded,
                  color: AppColors.limeInk, size: 18)
              : null,
        ),
      ),
    );
  }
}
