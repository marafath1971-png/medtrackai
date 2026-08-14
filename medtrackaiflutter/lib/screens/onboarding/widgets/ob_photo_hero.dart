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
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.lime,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.limeInk,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            if (overlayLine != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Text(
                  overlayLine!,
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.2,
                    shadows: const [
                      Shadow(
                        color: Color(0x66000000),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
