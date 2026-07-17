import 'package:flutter/material.dart';
import '../../../domain/entities/entities.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';

class CourseCompletionDialog extends StatelessWidget {
  final Medicine med;
  final VoidCallback onArchive;

  const CourseCompletionDialog(
      {super.key, required this.med, required this.onArchive});

  static Future<void> show(
      BuildContext context, Medicine med, VoidCallback onArchive) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CourseCompletionDialog(med: med, onArchive: onArchive),
    );
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.p20),
      child: MedAiDepthCard(
        accentGlow: true,
        padding: const EdgeInsets.all(AppSpacing.p24),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🎉',
                  style: AppTypography.headlineLarge.copyWith(fontSize: 64)),
              const SizedBox(height: AppSpacing.p16),
              Text(
                'Course Completed!',
                style: AppTypography.titleLarge
                    .copyWith(fontWeight: FontWeight.w800, color: L.text),
              ),
              const SizedBox(height: AppSpacing.p8),
              Text(
                'Great job finishing your course of ${med.name}. You\'ve successfully completed all prescribed doses.',
                textAlign: TextAlign.center,
                style:
                    AppTypography.bodyMedium.copyWith(color: L.sub, height: 1.5),
              ),
              const SizedBox(height: AppSpacing.p24),
              MedAiGlass(
                radius: AppRadius.l,
                padding: const EdgeInsets.all(AppSpacing.p16),
                tint: L.green.withValues(alpha: 0.08),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration:
                          BoxDecoration(color: L.green, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: AppSpacing.p12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Achievement Unlocked',
                              style: AppTypography.labelMedium.copyWith(
                                  fontWeight: FontWeight.w800, color: L.green)),
                          Text('100% Adherence for this course',
                              style: AppTypography.labelSmall
                                  .copyWith(color: L.sub.withValues(alpha: 0.8))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.p24),
              MedAiCTA(
                label: 'ARCHIVE & FINISH',
                onTap: () {
                  Navigator.pop(context);
                  onArchive();
                },
                semanticsLabel: 'Archive and finish course',
              ),
              const SizedBox(height: AppSpacing.p12),
              Semantics(
                button: true,
                label: 'Close',
                child: AnimatedPressable(
                  onTap: () => Navigator.pop(context),
                  child: SizedBox(
                    height: MedAiA11y.minTapTarget,
                    child: Center(
                      child: Text(
                        'Close',
                        style: AppTypography.labelLarge
                            .copyWith(color: L.sub, fontWeight: FontWeight.w600),
                      ),
                    ),
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
