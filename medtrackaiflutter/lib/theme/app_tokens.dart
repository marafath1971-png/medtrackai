import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSpacing {
  static const double zero = 0;
  static const double p4 = 4;
  static const double p8 = 8;
  static const double p12 = 12;
  static const double p16 = 16;
  static const double p20 = 20;
  static const double p24 = 24;
  static const double p32 = 32;
  static const double p40 = 40;
  static const double p48 = 48;
  static const double p64 = 64;
  static const double p80 = 80;

  // Legacy compatibility / Aliases
  static const double xxs = p4;
  static const double xs = p4;
  static const double s = p8;
  static const double m = p16;
  static const double l = p24;
  static const double xl = p32;
  static const double xxl = p48;
  static const double xxxl = p64;

  // Semantic spacing
  static const double screenPadding = p24;
  static const double fieldPadding = p16;
  static const double cardPadding = p16;
  static const double sectionGap = p32;
  static const double bottomBuffer = 120; // For floating nav
  static const double cardGap = p12; // Card-to-card gap in bento grids
}

class AppDurations {
  static const Duration micro = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 800);
  static const Duration shimmer = Duration(milliseconds: 1500);
  static const Duration bounce = Duration(milliseconds: 600);
  static const Duration breathe = Duration(milliseconds: 2500); // For idle pulsing animations
  static const Duration hero = Duration(milliseconds: 350); // Page hero transitions
}

class AppRadius {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 16; // Changed from 20 to 16 for premium sharpness
  static const double squircle = 20; // Reduced from 24
  static const double max = 999;

  static BorderRadius get roundXS => BorderRadius.circular(xs);
  static BorderRadius get roundS => BorderRadius.circular(s);
  static BorderRadius get roundM => BorderRadius.circular(m);
  static BorderRadius get roundL => BorderRadius.circular(l);
  static BorderRadius get roundXL => BorderRadius.circular(xl);
  static BorderRadius get roundSquircle => BorderRadius.circular(squircle);
  static BorderRadius get circle => BorderRadius.circular(max);
}

class AppCurves {
  // Spring transition: damping 0.8, response 0.4 approximation
  static const Curve spring = ElasticOutCurve(0.8);
  static const Curve smooth = Curves.fastOutSlowIn;
  // 2026 Liquid physics
  static const Curve liquid = ElasticOutCurve(0.6); // more bouncy/fluid
  static const Curve bouncy = ElasticOutCurve(0.4);
}

class AppTypography {
  static TextStyle get displayXL => GoogleFonts.inter(
        fontSize: 72,
        fontWeight: FontWeight.w700,
        letterSpacing: -2.0,
        height: 1.0,
      );
  static TextStyle get displayLarge => GoogleFonts.inter(
        fontSize: 64,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
        height: 1.0,
      );
  static TextStyle get displayMedium => GoogleFonts.inter(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        height: 1.1,
      );
  static TextStyle get displaySmall => GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.8,
        height: 1.2,
      );

  // ── Headings & Body: Inter (Minimal & Premium) ──
  static TextStyle get headlineLarge => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      );
  static TextStyle get headlineMedium => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      );
  static TextStyle get headlineSmall => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      );
  static TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      );
  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.2,
      );
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
      );
  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.0,
      );
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      );
  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      );
  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );
  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        letterSpacing: 0.2,
      );

  // ── Specialty Fonts ──
  static TextStyle get monoNumber => GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        letterSpacing: -0.5,
      );
      
  static TextStyle get sectionLabel => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
      );
}

class AppShadows {
  static List<BoxShadow> get soft => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get glass => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 30,
          spreadRadius: -5,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> get subtle => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get navBar => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 32,
          offset: const Offset(0, -4),
        ),
      ];

  static List<BoxShadow> get neumorphic => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  /// Atmospheric colored glow for primary actions
  static List<BoxShadow> glow(Color color, {double intensity = 0.4}) => [
        BoxShadow(
          color: color.withValues(alpha: intensity * 0.4),
          blurRadius: 24,
          spreadRadius: 2,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: color.withValues(alpha: intensity * 0.15),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
}

class AppGradients {
  static LinearGradient _flat(Color color) => LinearGradient(
        colors: [color, color],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // ── Cal AI Hero Gradient — orange accent ──
  static const LinearGradient accentOrange = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF8A60)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Progress Ring gradient (orange → green for completion feel) ──
  static const LinearGradient ringProgress = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF9A5C)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient get main => _flat(const Color(0xFF1C1C1E));
  static LinearGradient glass([Color? color]) => _flat(Colors.transparent);
  static LinearGradient get lightCard => _flat(const Color(0xFFFFFFFF));
  static LinearGradient get darkSurface => _flat(const Color(0xFF1C1C1E));

  // Semantic — kept as solids
  static LinearGradient get healthGreen  => _flat(const Color(0xFF00C853));
  static LinearGradient get warningAmber => _flat(const Color(0xFFFF9F0A));
  static LinearGradient get dangerRed    => _flat(const Color(0xFFFF3B30));
  static LinearGradient get darkCard     => _flat(const Color(0xFF2C2C2E));
  static LinearGradient get actionRed    => _flat(const Color(0xFFFF3B30));

  // All formerly-distinct accents now point to the single orange
  static LinearGradient get cyanFlash    => accentOrange;
  static LinearGradient get purpleDusk   => _flat(const Color(0xFFBF5AF2));
  static LinearGradient get goldLegend   => _flat(const Color(0xFFFF9F0A));
  static LinearGradient get sunrise      => accentOrange;
  static LinearGradient get midnightBlue => _flat(const Color(0xFF0A84FF));
  static LinearGradient get oliveOnboarding => _flat(const Color(0xFF00C853));
  static LinearGradient get oliveBg      => _flat(const Color(0xFFF7F7F7));

  static LinearGradient glow(Color color) => _flat(color);

  static RadialGradient radialGlow(Color color, {double intensity = 0.0}) =>
      const RadialGradient(
        colors: [Colors.transparent, Colors.transparent],
        radius: 0.8,
      );
}

