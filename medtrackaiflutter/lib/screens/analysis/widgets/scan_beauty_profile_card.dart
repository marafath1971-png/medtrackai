import 'package:flutter/material.dart';

import '../../../models/product_analysis.dart';
import '../../../theme/med_ai_ui.dart';

/// Cal AI / Apple-inspired Beauty, Skincare & Formulation Intelligence Card.
///
/// Gives youth, Gen Z, patients, and skincare enthusiasts instant clarity on:
/// - Clean Purity Score (0-100 rating)
/// - Comedogenic Risk (Pore-clogging index 0-5)
/// - Key Active Ingredients
/// - Targeted Skin & Body Benefits
/// - AM/PM Routine Integration
class ScanBeautyProfileCard extends StatelessWidget {
  final ProductAnalysis product;

  const ScanBeautyProfileCard({
    super.key,
    required this.product,
  });

  bool get shouldShow {
    return product.cleanScore != null ||
        product.comedogenicRating != null ||
        product.activeIngredients.isNotEmpty ||
        product.skinBenefits.isNotEmpty ||
        product.routineType != null ||
        product.category.toLowerCase().contains('skin') ||
        product.category.toLowerCase().contains('cosmetic');
  }

  @override
  Widget build(BuildContext context) {
    if (!shouldShow) return const SizedBox.shrink();

    final L = context.L;
    final cleanScore = product.cleanScore ?? 90;
    final comedogenic = product.comedogenicRating ?? 0;
    final routine = product.routineType ??
        (product.timing.toLowerCase().contains('night')
            ? 'PM Routine'
            : 'Daily Routine');

    final (scoreColor, scoreLabel) = _cleanScoreDetails(cleanScore);
    final (poreColor, poreLabel) = _comedogenicDetails(comedogenic);

    return Container(
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: L.border.withValues(alpha: 0.65),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.eatoNavy.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header banner
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.p20,
              AppSpacing.p16,
              AppSpacing.p20,
              AppSpacing.p12,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.pastelMint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.accentDeep,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Beauty & Clean Profile',
                        style: AppTypography.titleMedium.copyWith(
                          color: L.text,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Clean formulation · Active ingredients',
                        style: AppTypography.caption.copyWith(
                          color: L.sub,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Routine pill
                if (routine.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: L.bg,
                      borderRadius: BorderRadius.circular(AppRadius.max),
                      border: Border.all(
                        color: L.border.withValues(alpha: 0.8),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          routine.toLowerCase().contains('pm') ||
                                  routine.toLowerCase().contains('night')
                              ? Icons.nightlight_round
                              : Icons.wb_sunny_rounded,
                          size: 13,
                          color: AppColors.amber,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          routine,
                          style: AppTypography.labelSmall.copyWith(
                            color: L.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // Scores row (Clean Purity & Comedogenic Pore Scale)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.p20,
              vertical: AppSpacing.p16,
            ),
            child: Row(
              children: [
                // Clean Score Badge
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: scoreColor.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.eco_rounded,
                                size: 16, color: scoreColor),
                            const SizedBox(width: 6),
                            Text(
                              'Clean Score',
                              style: AppTypography.caption.copyWith(
                                color: L.sub,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$cleanScore',
                              style: AppTypography.headlineSmall.copyWith(
                                color: scoreColor,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              '/100',
                              style: AppTypography.caption.copyWith(
                                color: L.sub,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          scoreLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelSmall.copyWith(
                            color: L.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Comedogenic Rating
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: poreColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: poreColor.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.face_retouching_natural_rounded,
                                size: 16, color: poreColor),
                            const SizedBox(width: 6),
                            Text(
                              'Pore Clog Risk',
                              style: AppTypography.caption.copyWith(
                                color: L.sub,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$comedogenic',
                              style: AppTypography.headlineSmall.copyWith(
                                color: poreColor,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              '/5 scale',
                              style: AppTypography.caption.copyWith(
                                color: L.sub,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          poreLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelSmall.copyWith(
                            color: L.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Active Ingredients
          if (product.activeIngredients.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Ingredients',
                    style: AppTypography.labelMedium.copyWith(
                      color: L.sub,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final active in product.activeIngredients)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.pastelSky.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(AppRadius.max),
                            border: Border.all(
                              color: AppColors.blue.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            active,
                            style: AppTypography.bodySmall.copyWith(
                              color: L.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.p16),
          ],

          // Targeted Skin & Body Benefits
          if (product.skinBenefits.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Skin & Body Benefits',
                    style: AppTypography.labelMedium.copyWith(
                      color: L.sub,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final benefit in product.skinBenefits)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.pastelMint.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(AppRadius.max),
                            border: Border.all(
                              color: AppColors.limeDeep.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 14,
                                color: AppColors.accentDeep,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                benefit,
                                style: AppTypography.bodySmall.copyWith(
                                  color: L.text,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.p16),
          ],
        ],
      ),
    );
  }

  static (Color, String) _cleanScoreDetails(int score) {
    if (score >= 85) {
      return (AppColors.limeDeep, 'Clean Formulation');
    } else if (score >= 70) {
      return (AppColors.accent, 'Good Standard');
    } else if (score >= 50) {
      return (AppColors.amber, 'Moderate Additives');
    } else {
      return (AppColors.red, 'Caution / Harsh Additives');
    }
  }

  static (Color, String) _comedogenicDetails(int rating) {
    switch (rating) {
      case 0:
        return (AppColors.limeDeep, 'Won’t Clog Pores (0/5)');
      case 1:
        return (AppColors.accent, 'Very Low Risk (1/5)');
      case 2:
        return (AppColors.blue, 'Low Risk (2/5)');
      case 3:
        return (AppColors.amber, 'Moderate (3/5)');
      default:
        return (AppColors.red, 'High Clog Risk ($rating/5)');
    }
  }
}
