import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../widgets/shared/shared_widgets.dart';
import '../../../services/smart_alert_service.dart';

class QuickLogPrnDose extends StatefulWidget {
  const QuickLogPrnDose({super.key});

  @override
  State<QuickLogPrnDose> createState() => _QuickLogPrnDoseState();
}

class _QuickLogPrnDoseState extends State<QuickLogPrnDose> {
  // Finds any medication that qualifies as PRN (as-needed)
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
      AppState state, AppThemeColors L) {
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: BouncingButton(
        onTap: () => _showPrnPicker(context, prnMeds, state, L),
        scaleFactor: 0.98,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppShadows.neumorphic,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(Icons.flash_on_rounded, color: L.text, size: 22),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Log "As Needed" Dose',
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: L.text,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${prnMeds.length} PRN MEDS AVAILABLE',
                        style: AppTypography.labelMedium.copyWith(
                          color: L.sub,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: L.text,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.add_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.05, end: 0, curve: Curves.easeOutQuart);
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
      borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
          decoration: BoxDecoration(
            color: L.bg.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.05),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: L.border.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppGradients.accentOrange,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppShadows.glow(AppColors.accent, intensity: 0.3),
                    ),
                    child: const Center(
                      child: Icon(Icons.flash_on_rounded, color: Colors.black, size: 22),
                    ),
                  ).animate().scaleXY(begin: 0.8, end: 1.0, duration: 400.ms, curve: Curves.easeOutBack),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Log PRN Dose',
                          style: AppTypography.titleLarge.copyWith(
                            color: L.text,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Select your "as needed" medication',
                          style: AppTypography.bodySmall.copyWith(
                            color: L.sub.withValues(alpha: 0.7),
                            fontSize: 13,
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
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: meds
                        .map((med) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: BouncingButton(
                                onTap: () {
                                  HapticEngine.success();
                                  final now = DateTime.now();
                                  final timeStr =
                                      "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
                                  state.logPrnDose(med.id, 'PRN', timeStr);
                                  Navigator.pop(context);

                                  SmartAlertService.show(
                                    context,
                                    title: 'Dose Logged',
                                    message: 'Logged ${med.name} PRN dose',
                                    type: AlertType.success,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: L.fill.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: L.border.withValues(alpha: 0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: Color(int.parse(med.color.replaceFirst('#', '0xFF'))).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.medication_rounded,
                                            color: Color(int.parse(med.color.replaceFirst('#', '0xFF'))),
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              med.name,
                                              style: AppTypography.titleMedium.copyWith(
                                                fontWeight: FontWeight.w900,
                                                color: L.text,
                                                letterSpacing: -0.3,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              med.dose,
                                              style: AppTypography.bodySmall.copyWith(
                                                color: L.sub.withValues(alpha: 0.7),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          gradient: AppGradients.accentOrange,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: AppShadows.glow(AppColors.accent, intensity: 0.2),
                                        ),
                                        child: Text(
                                          'LOG',
                                          style: AppTypography.labelSmall.copyWith(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
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
      ),
    );
  }
}
