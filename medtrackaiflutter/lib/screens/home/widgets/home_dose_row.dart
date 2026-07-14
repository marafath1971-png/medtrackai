import 'package:flutter/material.dart';

import '../../../core/utils/color_utils.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
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

    return Semantics(
      button: true,
      label: '${med.name}, $timeLabel',
      child: GestureDetector(
        onTap: () {
          HapticEngine.selection();
          onTap();
        },
        child: PremiumTextureCard(
          padding: const EdgeInsets.all(14),
          radius: 22,
          texture: PremiumTextureStyle.fineGrain,
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: vialBg,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.medication_rounded,
                  size: 24,
                  color: medColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        color: taken ? L.text.withValues(alpha: 0.4) : L.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
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
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(
                width: 52,
                child: Text(
                  timeLabel,
                  textAlign: TextAlign.right,
                  style: AppTypography.labelSmall.copyWith(
                    color: overdue && !taken
                        ? L.error
                        : L.sub.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
    return AnimatedPressable(
      onTap: taken
          ? null
          : () {
              HapticEngine.doseTaken();
              onTake();
            },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: taken
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFB9EA6E), Color(0xFF8FD14F)],
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
        child: taken
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
            : null,
      ),
    );
  }
}
