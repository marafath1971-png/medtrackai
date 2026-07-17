import 'package:flutter/material.dart';

import '../../theme/design_2026.dart';

/// Onboarding palette — warm sage wellness base + electric mint accent.
/// Light/dark aware; tuned for WCAG AA contrast on text/CTA pairs.
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
    final L = context.L;
    final dark = context.isDark;
    final accent = L.accent;

    if (dark) {
      return ObPalette(
        bg: const Color(0xFF0B1411),
        bgTop: const Color(0xFF0E1A16),
        surface: const Color(0xFF15211C),
        surfaceSel: accent.withValues(alpha: 0.16),
        border: Colors.white.withValues(alpha: 0.07),
        borderSel: Design2026.electric,
        text: Colors.white,
        sub: Colors.white.withValues(alpha: 0.62),
        accent: accent,
        accentInk: Colors.white,
        // Duo system (DESIGN.md §3.1): lime is the hope/success primary CTA.
        // Sage (accent) stays the calm wellness base. Lime is light → dark ink.
        cta: AppColors.limeDeep,
        ctaInk: AppColors.limeInk,
        good: const Color(0xFF34D399),
        bad: const Color(0xFFFF6B6B),
        warmTint: accent.withValues(alpha: 0.14),
        electric: Design2026.electric,
        aurora: Design2026.aurora,
      );
    }

    return ObPalette(
      bg: const Color(0xFFF7F9F6),
      bgTop: const Color(0xFFFAFCF8),
      surface: Colors.white,
      surfaceSel: accent.withValues(alpha: 0.12),
      border: const Color(0xFFE2E8E4),
      borderSel: accent,
      text: const Color(0xFF1A2238),
      sub: const Color(0xFF6B7280),
      accent: accent,
      accentInk: Colors.white,
      // Duo system (DESIGN.md §3.1): lime hope/success primary CTA, dark ink.
      cta: AppColors.limeDeep,
      ctaInk: AppColors.limeInk,
      good: const Color(0xFF1FAE72),
      bad: const Color(0xFFE5573F),
      warmTint: AppColors.lime.withValues(alpha: 0.22),
      electric: Design2026.electric,
      aurora: Design2026.aurora,
    );
  }
}
