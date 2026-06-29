import 'package:flutter/material.dart';
import '../../core/constants/med_ai_assets.dart';
import '../../theme/design_2026.dart';

/// Branded Med AI logo from PNG assets with a painted fallback.
class MedAiLogo extends StatelessWidget {
  final double size;
  final String asset;
  final double borderRadius;
  final BoxFit fit;

  const MedAiLogo({
    super.key,
    required this.size,
    this.asset = MedAiAssets.illustrationAppIconBlue,
    this.borderRadius = 0,
    this.fit = BoxFit.contain,
  });

  const MedAiLogo.badge({
    super.key,
    required this.size,
    this.borderRadius = 13,
    this.fit = BoxFit.cover,
  }) : asset = MedAiAssets.illustrationAppIconBlue;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      asset,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (_, __, ___) => _FallbackLogo(size: size),
    );

    if (borderRadius <= 0) return image;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: image,
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  final double size;

  const _FallbackLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [L.accent, Design2026.electric],
        ),
      ),
      child: Icon(
        Icons.medication_rounded,
        color: Colors.white,
        size: size * 0.48,
      ),
    );
  }
}
