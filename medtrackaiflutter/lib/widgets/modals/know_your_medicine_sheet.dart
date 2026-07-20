import 'package:flutter/material.dart';

import '../../core/utils/haptic_engine.dart';
import '../../core/utils/scan_safety_mapper.dart';
import '../../domain/entities/medicine.dart';
import '../../theme/med_ai_ui.dart';
import '../common/animated_pressable.dart';

/// Pre-take "Know your medicine" gate — danger / sensitive info before logging.
///
/// Returns `true` if the user confirms take, `false` if dismissed / cancelled.
class KnowYourMedicineSheet extends StatelessWidget {
  final Medicine med;
  final String? doseTimeLabel;

  const KnowYourMedicineSheet({
    super.key,
    required this.med,
    this.doseTimeLabel,
  });

  /// Shows the sheet when [med.needsPreTakeBriefing]; otherwise returns true.
  static Future<bool> confirmTake(
    BuildContext context, {
    required Medicine med,
    String? doseTimeLabel,
  }) async {
    if (!med.needsPreTakeBriefing) return true;

    HapticEngine.alertWarning();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => KnowYourMedicineSheet(
        med: med,
        doseTimeLabel: doseTimeLabel,
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final profile = med.aiSafetyProfile;
    final critical = med.hasCriticalSafetyAlerts;
    final bottom = MediaQuery.paddingOf(context).bottom;

    final warnings = profile?.warnings ?? const <String>[];
    final interactions = profile?.interactions ?? const <String>[];
    final foodRules = profile?.foodRules ??
        (med.intakeInstructions.isNotEmpty && med.intakeInstructions != 'None'
            ? [med.intakeInstructions]
            : const <String>[]);
    final tips = profile?.ahaMoments ?? const <String>[];

    final meta = [
      if (med.dose.isNotEmpty) med.dose,
      if (med.form.isNotEmpty) med.form,
      if (doseTimeLabel != null) doseTimeLabel!,
    ].join(' · ');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: BoxDecoration(
        color: L.bg,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.p12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: L.border.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.p20,
                AppSpacing.gutter,
                AppSpacing.p16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    HopeVibe.knowTitle,
                    style: AppTypography.displaySmall.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      letterSpacing: -0.6,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.p8),
                  Text(
                    critical ? HopeVibe.knowCritical : HopeVibe.knowSoft,
                    style: AppTypography.bodyMedium.copyWith(
                      color: L.sub,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.p20),

                  Container(
                    padding: const EdgeInsets.all(AppSpacing.p16),
                    decoration: BoxDecoration(
                      color: AppColors.pastelSky,
                      borderRadius: BorderRadius.circular(AppRadius.l),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(AppRadius.s),
                          ),
                          child: Icon(Icons.medication_rounded,
                              color: L.text, size: 26),
                        ),
                        const SizedBox(width: AppSpacing.p12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                med.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.titleMedium.copyWith(
                                  color: L.text,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (meta.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.p4),
                                Text(
                                  meta,
                                  style: AppTypography.bodySmall
                                      .copyWith(color: L.sub),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.p8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.p12,
                                  vertical: AppSpacing.p4,
                                ),
                                decoration: BoxDecoration(
                                  color: critical
                                      ? AppColors.pastelPink
                                      : AppColors.pastelMint,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.max),
                                ),
                                child: Text(
                                  critical
                                      ? 'Review carefully'
                                      : 'Ready when you are',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: critical
                                        ? const Color(0xFF9B3D45)
                                        : const Color(0xFF3D6B45),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (critical) ...[
                    const SizedBox(height: AppSpacing.p16),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.p16),
                      decoration: BoxDecoration(
                        color: AppColors.pastelPink,
                        borderRadius: BorderRadius.circular(AppRadius.l),
                        border: Border.all(
                          color: AppColors.red.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: AppColors.red, size: 22),
                          const SizedBox(width: AppSpacing.p12),
                          Expanded(
                            child: Text(
                              'Sensitive alerts on file — read these before you take this dose.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: L.text,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (warnings.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.p16),
                    _AlertBlock(
                      title: 'Warnings',
                      items: warnings,
                      tint: AppColors.pastelSun,
                      accent: const Color(0xFF9A6B1F),
                      icon: Icons.shield_rounded,
                    ),
                  ],
                  if (interactions.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.p12),
                    _AlertBlock(
                      title: 'Interactions',
                      items: interactions,
                      tint: AppColors.pastelPink,
                      accent: const Color(0xFF9B3D45),
                      icon: Icons.link_off_rounded,
                    ),
                  ],
                  if (foodRules.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.p12),
                    _AlertBlock(
                      title: 'Before you take',
                      items: foodRules,
                      tint: AppColors.pastelMint,
                      accent: const Color(0xFF3D6B45),
                      icon: Icons.restaurant_rounded,
                    ),
                  ],
                  if (tips.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.p12),
                    _AlertBlock(
                      title: 'Good to know',
                      items: tips.take(3).toList(),
                      tint: AppColors.pastelLilac,
                      accent: L.text.withValues(alpha: 0.7),
                      icon: Icons.lightbulb_outline_rounded,
                    ),
                  ],

                  const SizedBox(height: AppSpacing.p16),
                  Text(
                    'AI guidance — always verify with your pharmacist or doctor.',
                    textAlign: TextAlign.center,
                    style: AppTypography.labelSmall.copyWith(
                      color: L.sub.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sticky confirm / dismiss
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.p12,
              AppSpacing.gutter,
              AppSpacing.p16 + bottom,
            ),
            decoration: BoxDecoration(
              color: L.bg,
              border: Border(
                top: BorderSide(color: L.border.withValues(alpha: 0.45)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MedAiCTA(
                  label: critical ? 'I understand — take dose' : 'Take dose',
                  icon: Icons.check_rounded,
                  onTap: () {
                    HapticEngine.success();
                    Navigator.of(context).pop(true);
                  },
                ),
                const SizedBox(height: AppSpacing.p8),
                Semantics(
                  button: true,
                  label: 'Not now',
                  child: AnimatedPressable(
                    onTap: () {
                      HapticEngine.selection();
                      Navigator.of(context).pop(false);
                    },
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      constraints: const BoxConstraints(
                        minHeight: MedAiA11y.minTapTarget,
                      ),
                      child: Text(
                        'Not now',
                        style: AppTypography.labelMedium.copyWith(
                          color: L.sub,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertBlock extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color tint;
  final Color accent;
  final IconData icon;

  const _AlertBlock({
    required this.title,
    required this.items,
    required this.tint,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.p16),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(AppRadius.l),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: AppSpacing.p8),
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.p12),
          for (final item in items.take(5))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.p8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.p12),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTypography.bodyMedium.copyWith(
                        color: L.text,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Be honest about truncation — never let a pre-take safety gate
          // silently hide warnings/interactions beyond the first five.
          if (items.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.p4),
              child: Text(
                '+${items.length - 5} more — open medicine details to read all',
                style: AppTypography.labelSmall.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
