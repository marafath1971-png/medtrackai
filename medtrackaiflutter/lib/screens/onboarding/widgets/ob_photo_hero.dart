import 'package:flutter/material.dart';

import '../../../theme/med_ai_ui.dart';
import '../onboarding_theme.dart';

/// Minimal full-bleed photo hero — soft cream fade, optional brand chip.
class ObPhotoHero extends StatelessWidget {
  final String asset;
  final double height;
  final String? badge;
  final String? overlayLine;
  final BoxFit fit;

  const ObPhotoHero({
    super.key,
    required this.asset,
    this.height = 260,
    this.badge,
    this.overlayLine,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              asset,
              fit: fit,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => ColoredBox(
                color: AppColors.pastelMint,
                child: Icon(
                  Icons.medication_rounded,
                  size: 48,
                  color: p.accent.withValues(alpha: 0.45),
                ),
              ),
            ),
            // Soft vignette so type over photo stays readable.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x14000000),
                    Color(0x00000000),
                    Color(0x99000000),
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
            if (badge != null)
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 5.5),
                  decoration: BoxDecoration(
                    color: AppColors.lime,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.limeDeep.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        size: 11,
                        color: AppColors.limeInk,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        badge!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.limeInk,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (overlayLine != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.32),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.lime,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          overlayLine!,
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            fontSize: 14,
                            height: 1.25,
                            shadows: const [
                              Shadow(
                                color: Color(0x66000000),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Subtle crisp border overlay for high-definition edge rendering
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                    width: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
