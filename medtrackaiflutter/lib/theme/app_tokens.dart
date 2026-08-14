import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// WCAG 2.2 / iOS HIG minimum interactive target sizes.
abstract final class AppA11y {
  static const double minTapTarget = 48;
  static const double minTapTargetCompact = 44;
  static const double minContrastRatio = 4.5;
}

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
  /// Horizontal gutter for main shell tabs (home / dashboard / alarms / family).
  static const double gutter = p20;
  static const double fieldPadding = p16;
  static const double cardPadding = p16;
  static const double sectionGap = p32;
  static const double bottomBuffer = 120; // For floating nav
  static const double cardGap = p12; // Card-to-card gap in bento grids
}

class AppDurations {
  /// Button press, micro feedback (Emil: 100–160ms).
  static const Duration micro = Duration(milliseconds: 150);
  /// Dropdowns, cards, tab fades (Emil: 150–250ms).
  static const Duration fast = Duration(milliseconds: 220);
  /// Modals, drawers enter (Emil: 200–500ms).
  static const Duration medium = Duration(milliseconds: 320);
  /// Modal/sheet exit — snappier than enter (asymmetric timing).
  static const Duration exit = Duration(milliseconds: 180);
  static const Duration slow = Duration(milliseconds: 1000);
  static const Duration shimmer = Duration(milliseconds: 2000);
  static const Duration bounce = Duration(milliseconds: 800);
  static const Duration breathe = Duration(milliseconds: 3000);
  /// First-time / hero entrances only — not for tabs or daily UI.
  static const Duration hero = Duration(milliseconds: 350);
  /// Bottom-tab crossfade — seen often; keep under 200ms.
  static const Duration tab = Duration(milliseconds: 180);
}

class AppRadius {
  static const double xs = 8;
  static const double s = 12;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 28; 
  static const double squircle = 32; 
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
  /// Emil strong ease-out — default for enter/exit UI (cubic-bezier 0.23, 1, 0.32, 1).
  static const Curve emilOut = Cubic(0.23, 1.0, 0.32, 1.0);
  /// Emil ease-in-out for on-screen movement (0.77, 0, 0.175, 1).
  static const Curve emilInOut = Cubic(0.77, 0.0, 0.175, 1.0);
  /// iOS drawer / sheet curve (Ionic-style).
  static const Curve drawer = Cubic(0.32, 0.72, 0.0, 1.0);
  /// Material 3 Expressive emphasized decelerate.
  static const Curve expressive = Cubic(0.05, 0.7, 0.1, 1.0);
  /// iOS HIG standard ease-out for transitions.
  static const Curve iosEaseOut = Cubic(0.25, 0.1, 0.25, 1.0);
  /// General UI — prefer emilOut over easeInOutCirc.
  static const Curve smooth = emilOut;
  /// Rare celebrations / onboarding only — never on tabs or settings rows.
  static const Curve spring = ElasticOutCurve(0.9);
  static const Curve liquid = ElasticOutCurve(0.7);
  static const Curve bouncy = ElasticOutCurve(0.5);
}

class AppTypography {
  static TextStyle get displayXL => GoogleFonts.outfit(
        fontSize: 72,
        fontWeight: FontWeight.w800,
        letterSpacing: -2.5,
        height: 1.0,
      );
  static TextStyle get displayLarge => GoogleFonts.outfit(
        fontSize: 64,
        fontWeight: FontWeight.w800,
        letterSpacing: -2.0,
        height: 1.0,
      );
  static TextStyle get displayMedium => GoogleFonts.outfit(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
        height: 1.1,
      );
  static TextStyle get displaySmall => GoogleFonts.outfit(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        height: 1.2,
      );

  static TextStyle get headlineLarge => GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      );
  static TextStyle get headlineMedium => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.6,
      );
  static TextStyle get headlineSmall => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      );
  static TextStyle get titleLarge => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      );
  static TextStyle get titleMedium => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.2,
      );
  static TextStyle get bodyLarge => GoogleFonts.outfit(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
      );
  static TextStyle get bodyMedium => GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.0,
      );
  static TextStyle get labelLarge => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      );
  static TextStyle get labelMedium => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      );
  static TextStyle get labelSmall => GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      );
  static TextStyle get bodySmall => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        letterSpacing: 0.2,
      );

  /// Micro caption / overline — use instead of ad-hoc fontSize 9–11.
  static TextStyle get caption => GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        height: 1.3,
      );

  static TextStyle get monoNumber => GoogleFonts.spaceGrotesk(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      );
      
  static TextStyle get sectionLabel => GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      );
}

class AppShadows {
  /// Default elevated surface — Cal AI / Apple Health style ambient lift.
  static List<BoxShadow> get soft => [
        BoxShadow(
          color: const Color(0xFF1A2621).withValues(alpha: 0.04),
          blurRadius: 24,
          spreadRadius: -4,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 1,
          offset: const Offset(0, 1),
        ),
      ];

  /// Hero cards and primary modules on home.
  static List<BoxShadow> get premium => [
        BoxShadow(
          color: const Color(0xFF3A7D6A).withValues(alpha: 0.08),
          blurRadius: 24,
          spreadRadius: -8,
          offset: const Offset(0, 16),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
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

  // ── Hero accent gradient (sage → lime — matches reference home) ──
  static const LinearGradient accentHero = LinearGradient(
    colors: [Color(0xFF4A9E86), Color(0xFF8FD14F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Deprecated: misnamed (it's sage→lime, never orange). Use [accentHero].
  @Deprecated('Use accentHero — this gradient is sage→lime, not orange')
  static const LinearGradient accentOrange = accentHero;

  static const LinearGradient ringProgress = LinearGradient(
    colors: [Color(0xFF8FD14F), Color(0xFF4A9E86)],
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

  // Aliases → sage/lime brand system
  static LinearGradient get cyanFlash => accentHero;
  static LinearGradient get purpleDusk   => _flat(const Color(0xFFBF5AF2));
  static LinearGradient get goldLegend   => _flat(const Color(0xFFFF9F0A));
  static LinearGradient get sunrise      => accentHero;
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

// ── Motion presets (Emil Kowalski / Apple HIG — never scale from 0) ──
extension MotionPresets on Widget {
  Widget entranceHero() => animate()
      .fadeIn(duration: AppDurations.hero, curve: AppCurves.emilOut)
      .slideY(begin: 0.04, end: 0, duration: AppDurations.hero, curve: AppCurves.emilOut);

  /// Stagger delay 50ms — Emil: 30–80ms between items.
  Widget entranceCard(int index) => animate(delay: (index * 50).ms)
      .fadeIn(duration: AppDurations.fast, curve: AppCurves.emilOut)
      .slideY(begin: 0.03, end: 0, duration: AppDurations.fast, curve: AppCurves.emilOut);

  Widget entranceCTA() => animate()
      .fadeIn(duration: AppDurations.micro, curve: AppCurves.emilOut)
      .scaleXY(begin: 0.95, end: 1.0, duration: AppDurations.fast, curve: AppCurves.emilOut);

  Widget entranceSlideX({double begin = 0.06}) => animate()
      .fadeIn(duration: AppDurations.fast, curve: AppCurves.emilOut)
      .slideX(begin: begin, end: 0, duration: AppDurations.fast, curve: AppCurves.emilOut);
}

