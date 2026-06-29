import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../providers/app_state.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../services/smart_alert_service.dart';

class QuickLogPrnDose extends StatefulWidget {
  const QuickLogPrnDose({super.key});

  @override
  State<QuickLogPrnDose> createState() => _QuickLogPrnDoseState();
}

class _QuickLogPrnDoseState extends State<QuickLogPrnDose> {
  List<Medicine> _getPrnMeds(AppState state) {
    return state.meds.where((m) {
      return m.schedule.isEmpty ||
          m.schedule.any((s) => s.ritual == Ritual.asNeeded) ||
          m.intakeInstructions.toLowerCase().contains('as needed') ||
          m.notes.toLowerCase().contains('as needed') ||
          m.notes.toLowerCase().contains('prn');
    }).toList();
  }

  void _showPrnPicker(BuildContext context, List<Medicine> prnMeds,
      AppState state) {
    HapticEngine.selection();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PrnPickerSheet(meds: prnMeds, state: state),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final prnMeds = _getPrnMeds(state);

    if (prnMeds.isEmpty) return const SizedBox.shrink();

    final L = context.L;
    final reduceMotion = MedAiA11y.reducedMotion(context);
    final label =
        'Log as-needed dose. ${prnMeds.length} ${prnMeds.length == 1 ? 'medication' : 'medications'} available.';

    Widget card = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Semantics(
        button: true,
        label: label,
        child: MedAiDepthCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          onTap: () => _showPrnPicker(context, prnMeds, state),
          child: Row(
            children: [
              Container(
                width: MedAiA11y.minTapTarget,
                height: MedAiA11y.minTapTarget,
                decoration: BoxDecoration(
                  color: L.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child:
                      Icon(Icons.flash_on_rounded, color: L.primary, size: 22),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Log as-needed dose',
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: L.text,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${prnMeds.length} ${prnMeds.length == 1 ? 'medication' : 'medications'} available',
                      style: AppTypography.labelSmall.copyWith(
                        color: L.sub,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: MedAiA11y.minTapTarget,
                height: MedAiA11y.minTapTarget,
                decoration: BoxDecoration(
                  color: L.text,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.soft,
                ),
                child: const Center(
                  child: Icon(Icons.add_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (reduceMotion) return card;
    return card
        .animate()
        .fadeIn(duration: AppDurations.fast, curve: AppCurves.smooth)
        .slideY(begin: 0.05, end: 0, curve: AppCurves.smooth);
  }
}

class _PrnPickerSheet extends StatelessWidget {
  final List<Medicine> meds;
  final AppState state;

  const _PrnPickerSheet({required this.meds, required this.state});

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: MedAiGlass(
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
        radius: 32,
        showBorder: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: L.border.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: MedAiA11y.minTapTarget,
                  height: MedAiA11y.minTapTarget,
                  decoration: BoxDecoration(
                    color: L.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(Icons.flash_on_rounded,
                        color: L.primary, size: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Log as-needed dose',
                        style: AppTypography.titleLarge.copyWith(
                          color: L.text,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Select your as-needed medication',
                        style: AppTypography.bodySmall.copyWith(
                          color: L.sub,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: meds
                      .map((med) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Semantics(
                              button: true,
                              label: 'Log ${med.name}, ${med.dose}',
                              child: MedAiDepthCard(
                                padding: const EdgeInsets.all(16),
                                onTap: () {
                                  HapticEngine.success();
                                  final now = DateTime.now();
                                  final timeStr =
                                      "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
                                  state.logPrnDose(med.id, 'PRN', timeStr);
                                  Navigator.pop(context);

                                  SmartAlertService.show(
                                    context,
                                    title: 'Dose logged',
                                    message:
                                        'Logged ${med.name} as-needed dose',
                                    type: AlertType.success,
                                  );
                                },
                                child: Row(
                                  children: [
                                    Container(
                                      width: MedAiA11y.minTapTarget,
                                      height: MedAiA11y.minTapTarget,
                                      decoration: BoxDecoration(
                                        color: Color(int.parse(med.color
                                                .replaceFirst('#', '0xFF')))
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.medication_rounded,
                                          color: Color(int.parse(med.color
                                              .replaceFirst('#', '0xFF'))),
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            med.name,
                                            style: AppTypography.titleMedium
                                                .copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: L.text,
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            med.dose,
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                              color: L.sub,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: L.text,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: AppShadows.soft,
                                      ),
                                      child: Text(
                                        'Log',
                                        style: AppTypography.labelSmall.copyWith(
                                          color: L.bg,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
