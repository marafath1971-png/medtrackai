import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/premium_graphics.dart';
import '../../../core/constants/med_ai_assets.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../core/utils/manual_add_medicine.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';
import '../../../widgets/common/premium_illustration_banner.dart';
import '../../../widgets/common/premium_texture.dart';

class HomeScheduleEmpty extends StatelessWidget {
  final bool hasMeds;
  final VoidCallback? onAdd;

  const HomeScheduleEmpty({
    super.key,
    required this.hasMeds,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final reduceMotion = MedAiA11y.reducedMotion(context);
    final title =
        hasMeds ? 'Nothing scheduled today' : 'Add your first medicine';
    final subtitle = hasMeds
        ? 'No doses are set for this day. Check another date or edit your schedule.'
        : 'Scan or add a medicine to build your daily schedule.';

    return PremiumTextureCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      radius: 22,
      texture: PremiumTextureStyle.fineGrain,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Feature-matched ghost mascot (home_heart = welcoming first-med
          // moment; happy_pill = nothing-scheduled). Small garnish size, with a
          // subtle one-shot fade+scale entrance (skipped under reduced-motion).
          // Falls back to the SVG banner if the PNG isn't bundled yet.
          Center(
            child: _MascotEntrance(
              reduceMotion: reduceMotion,
              child: Image.asset(
                hasMeds
                    ? MedAiAssets.mascotHappyPill
                    : MedAiAssets.mascotHomeHeart,
                height: 72,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => PremiumIllustrationBanner(
                  asset: hasMeds
                      ? PremiumGraphics.healthInsights
                      : PremiumGraphics.onboardingDiagnose,
                  height: 100,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color: L.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: L.sub,
              height: 1.4,
            ),
          ),
          if (!hasMeds && onAdd != null) ...[
            const SizedBox(height: 14),
            AnimatedPressable(
              onTap: () {
                HapticEngine.selection();
                onAdd!();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: L.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Scan a medicine',
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            AnimatedPressable(
              onTap: () =>
                  startManualAddMedicine(context, source: 'home_empty'),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Text(
                  'Or enter it manually',
                  style: AppTypography.labelMedium.copyWith(
                    color: L.sub,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A subtle one-shot entrance for a small mascot: fade + gentle scale-in.
/// No looping — daily UI should not bounce. Fully skipped under reduced-motion.
class _MascotEntrance extends StatelessWidget {
  final Widget child;
  final bool reduceMotion;
  const _MascotEntrance({required this.child, required this.reduceMotion});

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) return child;
    return child
        .animate()
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        .scale(
          begin: const Offset(0.85, 0.85),
          end: const Offset(1, 1),
          duration: 500.ms,
          curve: Curves.easeOutBack,
        );
  }
}
