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
        cta: Colors.white,
        ctaInk: const Color(0xFF0B1411),
        good: const Color(0xFF34D399),
        bad: const Color(0xFFFF6B6B),
        warmTint: accent.withValues(alpha: 0.14),
        electric: Design2026.electric,
        aurora: Design2026.aurora,
      );
    }

    return ObPalette(
      bg: const Color(0xFFFFF8F2),
      bgTop: const Color(0xFFFFFBF7),
      surface: Colors.white,
      surfaceSel: const Color(0xFFFFF3E0),
      border: const Color(0xFFE8E0D6),
      borderSel: const Color(0xFFE8943A),
      text: const Color(0xFF1A2238),
      sub: const Color(0xFF6B7280),
      accent: const Color(0xFFE8943A),
      accentInk: Colors.white,
      cta: const Color(0xFF1A2238),
      ctaInk: Colors.white,
      good: const Color(0xFF1FAE72),
      bad: const Color(0xFFE5573F),
      warmTint: const Color(0xFFFFF3E0),
      electric: const Color(0xFFF0A04B),
      aurora: [
        const Color(0xFFFFF3E0),
        const Color(0xFFFFE8CC),
        const Color(0xFFF5E6D8),
        const Color(0xFFE8F4F0),
      ],
    );
  }
}
