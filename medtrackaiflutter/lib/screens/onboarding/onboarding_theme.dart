import 'package:flutter/material.dart';

import '../../theme/design_2026.dart';

/// Onboarding palette — premium cream wellness (matches home / settings).
/// Calm, sparse, high-trust. Lime = progress & CTA; sage = clinical accents.
class ObPalette {
  final Color bg;
  final Color bgTop;
  final Color surface;
  final Color surfaceSel;
  final Color border;
  final Color borderSel;
  final Color text;
  final Color sub;
  final Color accent;
  final Color accentInk;
  final Color cta;
  final Color ctaInk;
  final Color good;
  final Color bad;
  final Color warmTint;
  final Color electric;
  final List<Color> aurora;

  const ObPalette({
    required this.bg,
    required this.bgTop,
    required this.surface,
    required this.surfaceSel,
    required this.border,
    required this.borderSel,
    required this.text,
    required this.sub,
    required this.accent,
    required this.accentInk,
    required this.cta,
    required this.ctaInk,
    required this.good,
    required this.bad,
    required this.warmTint,
    required this.electric,
    required this.aurora,
  });

  static ObPalette of(BuildContext context) {
    final dark = context.isDark;

    if (dark) {
      return ObPalette(
        bg: const Color(0xFF0B132B),
        bgTop: const Color(0xFF101A36),
        surface: const Color(0xFF1C2541),
        surfaceSel: AppColors.lime.withValues(alpha: 0.14),
        border: Colors.white.withValues(alpha: 0.08),
        borderSel: AppColors.limeDeep,
        text: Colors.white,
        sub: Colors.white.withValues(alpha: 0.62),
        accent: AppColors.sageGreen,
        accentInk: Colors.white,
        cta: AppColors.limeDeep,
        ctaInk: AppColors.limeInk,
        good: const Color(0xFF34D399),
        bad: const Color(0xFFFF6B6B),
        warmTint: AppColors.lime.withValues(alpha: 0.12),
        electric: Design2026.electric,
        aurora: const [
          Color(0xFF1A3A2E),
          Color(0xFF163040),
          Color(0xFF2A2450),
        ],
      );
    }

    return ObPalette(
      bg: const Color(0xFFF7F6F3),
      bgTop: const Color(0xFFFBFBF8),
      surface: Colors.white,
      surfaceSel: AppColors.pastelMint,
      border: const Color(0xFFE8EAE6),
      borderSel: AppColors.limeDeep,
      text: const Color(0xFF1A1D26),
      sub: const Color(0xFF8A9099),
      accent: AppColors.sageGreen,
      accentInk: Colors.white,
      cta: AppColors.limeDeep,
      ctaInk: AppColors.limeInk,
      good: const Color(0xFF10B981),
      bad: const Color(0xFFC45C5C),
      warmTint: AppColors.pastelMint,
      electric: AppColors.lime,
      aurora: const [
        Color(0xFFE4F5E7),
        Color(0xFFD9ECF7),
        Color(0xFFFFF8F2),
      ],
    );
  }
}
