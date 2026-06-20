import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/utils/color_utils.dart';
import 'app_tokens.dart';

export 'app_tokens.dart';

// ══════════════════════════════════════════════
// CAL AI EXACT COLOR SYSTEM
// Viral 2025-2026 — Single accent, OLED black
// ══════════════════════════════════════════════

class AppColors {
  // ── Core Backgrounds (Cal AI OLED Black) ──────
  static const Color black = Color(0xFF000000);      // True OLED black BG
  static const Color white = Color(0xFFFFFFFF);
  
  // ── Card Surfaces ──────────────────────────────
  static const Color bgLight  = Color(0xFFF5F5F0);  // Light mode BG (Cal AI Light-Olive)
  static const Color bgDark   = Color(0xFF0B132B);  // Deep Slate Blue
  static const Color cardLight  = Color(0xFFFFFFFF);
  static const Color cardDark   = Color(0xFF1C2541); // Midnight Navy
  static const Color cardLight2 = Color(0xFFEBEBE5); // Light mode fill/container card
  static const Color cardDark2  = Color(0xFF283353); // Lighter Midnight Navy

  // ── Greyscale (2026 Premium Slate / Alpha) ──────
  static const Color grey50  = Color(0xFFF8FAFC); // Slate 50
  static const Color grey100 = Color(0xFFF1F5F9); // Slate 100
  static const Color grey200 = Color(0xFFE2E8F0); // Slate 200
  static const Color grey300 = Color(0xFFCBD5E1); // Slate 300
  static const Color grey400 = Color(0xFF94A3B8); // Slate 400
  static const Color grey500 = Color(0xFF64748B); // Slate 500
  static const Color grey600 = Color(0xFF475569); // Slate 600
  static const Color grey700 = Color(0xFF334155); // Slate 700
  static const Color grey800 = Color(0xFF1E293B); // Slate 800
  static const Color grey900 = Color(0xFF0F172A); // Slate 900

  // ── ⭐ HERO ACCENT — Premium Sage Green ─────────────
  // This is the ONLY accent color in the entire app
  static const Color accent      = Color(0xFF4A9E86); // Premium Vibrant Sage Green
  static const Color accentLight = Color(0xFF8EDABF); // Lighter variant

  // ── Semantic: Success / Error ──────────────────
  static const Color green      = Color(0xFF00C853); // Vibrant iOS-style green
  static const Color greenDark  = Color(0xFF00E676);
  static const Color red        = Color(0xFFFF3B30); // iOS red
  static const Color redDark    = Color(0xFFFF453A);
  static const Color amber      = Color(0xFFFF9F0A);
  static const Color amberDark  = Color(0xFFFFB340);
  static const Color blue       = Color(0xFF0A84FF);
  static const Color blueDark   = Color(0xFF0A84FF);
  static const Color purple     = Color(0xFFBF5AF2);
  static const Color purpleDark = Color(0xFFBF5AF2);

  // ── Backwards Compatibility Aliases ───────────
  static const Color primaryBlue      = bgDark;
  static const Color primaryBlueDark  = cardDark;
  static const Color primaryBlueLight = cardDark2;
  static const Color cyanAccent     = accent; // map to orange
  static const Color coralAccent    = accent;
  static const Color lavenderAccent = purple;
  static const Color cyberPink      = accent;
  static const Color acidGreen      = green;
  static const Color electricBlue   = blue;
  static const Color meshBg         = bgLight;

  static const Color success     = green;
  static const Color warning     = amber;
  static const Color error       = red;
  static const Color successDark = greenDark;
  static const Color warningDark = amberDark;
  static const Color errorDark   = redDark;

  static const Color lRed    = red;
  static const Color dRed    = redDark;
  static const Color oBg     = bgDark;
  static const Color oText   = white;
  static const Color oBorder = grey800;
  static const Color oFill   = grey900;
  static const Color oLime   = accent;
  static const Color oLimeDark = accent;
}

class AppTheme {
  static final String? _fontFamily = GoogleFonts.outfit().fontFamily;

  static ThemeData light({String? accentHex}) {
    final acc = accentHex != null ? hexToColor(accentHex) : const Color(0xFF3A7D6A);
    return ThemeData(
      useMaterial3: true,
      fontFamily: _fontFamily,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgLight,
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF1A2621),
        onPrimary: AppColors.white,
        secondary: acc,
        onSecondary: AppColors.white,
        surface: AppColors.cardLight,
        onSurface: const Color(0xFF1A2621),
        error: AppColors.red,
        outline: const Color(0xFFE2E8E4),
        surfaceContainer: AppColors.cardLight2,
      ),
      textTheme: _buildTextTheme(const Color(0xFF1A2621)),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((_) => AppColors.white),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? const Color(0xFF3A7D6A) : const Color(0xFFEBEBE5)),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        splashRadius: 0,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.roundXL,
          side: const BorderSide(color: Color(0xFFE2E8E4)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A2621),
          foregroundColor: AppColors.white,
          textStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundXL),
          elevation: 0,
        ),
      ),
    ).copyWith(
      extensions: [
        AppThemeColors.fromColorScheme(
          ColorScheme.light(primary: const Color(0xFF1A2621), secondary: acc),
          Brightness.light,
        ),
      ],
    );
  }

  static ThemeData dark({bool isAmoled = true, String? accentHex}) {
    final acc = accentHex != null ? hexToColor(accentHex) : AppColors.accent;
    return ThemeData(
      useMaterial3: true,
      fontFamily: _fontFamily,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark, // True OLED black
      colorScheme: ColorScheme.dark(
        primary: AppColors.white,
        onPrimary: AppColors.black,
        secondary: acc,
        onSecondary: AppColors.black,
        surface: AppColors.cardDark,
        onSurface: AppColors.white,
        error: AppColors.redDark,
        outline: AppColors.grey800,
        surfaceContainer: AppColors.cardDark,
      ),
      textTheme: _buildTextTheme(AppColors.white),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((_) => AppColors.white),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? AppColors.green : AppColors.grey800),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        splashRadius: 0,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.roundXL,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.black,
          textStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundXL),
          elevation: 0,
        ),
      ),
    ).copyWith(
      extensions: [
        AppThemeColors.fromColorScheme(
          ColorScheme.dark(primary: AppColors.white, secondary: acc),
          Brightness.dark,
          isAmoled: isAmoled,
        ),
      ],
    );
  }

  static TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      displayLarge:  AppTypography.displayLarge.copyWith(color: textColor),
      displayMedium: AppTypography.displayMedium.copyWith(color: textColor),
      headlineLarge: AppTypography.headlineLarge.copyWith(color: textColor),
      headlineMedium:AppTypography.headlineMedium.copyWith(color: textColor),
      titleLarge:    AppTypography.titleLarge.copyWith(color: textColor),
      titleMedium:   AppTypography.titleMedium.copyWith(color: textColor),
      bodyLarge:     AppTypography.bodyLarge.copyWith(color: textColor),
      bodyMedium:    AppTypography.bodyMedium.copyWith(color: textColor),
      labelLarge:    AppTypography.labelLarge.copyWith(color: textColor),
      labelMedium:   AppTypography.labelMedium.copyWith(color: textColor),
      labelSmall:    AppTypography.labelMedium.copyWith(color: textColor),
    );
  }
}

class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color bg;
  final Color onBg;
  final Color card;
  final Color onCard;
  final Color card2;
  final Color onCard2;
  final Color border;
  final Color text;
  final Color sub;
  final Color fill;
  final Color onFill;
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color error;
  final Color red;
  final Color redLight;
  final Color success;
  final Color green;
  final Color greenLight;
  final Color warning;
  final Color amber;
  final Color info;
  final Color purple;
  final Color meshBg;
  final Color glass;
  final Color glassBorder;
  final List<BoxShadow> shadowSoft;
  final LinearGradient mainGradient;
  // Cal AI additions
  final Color accent;        // #FF6B35 orange — only accent
  final Color accentLight;   // Orange 15% fill

  const AppThemeColors({
    required this.bg,
    required this.onBg,
    required this.card,
    required this.onCard,
    required this.card2,
    required this.onCard2,
    required this.border,
    required this.text,
    required this.sub,
    required this.fill,
    required this.onFill,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.error,
    required this.red,
    required this.redLight,
    required this.success,
    required this.green,
    required this.greenLight,
    required this.warning,
    required this.amber,
    required this.info,
    required this.purple,
    required this.meshBg,
    required this.glass,
    required this.glassBorder,
    required this.shadowSoft,
    required this.mainGradient,
    required this.accent,
    required this.accentLight,
  });

  factory AppThemeColors.fromColorScheme(
      ColorScheme colorScheme, Brightness brightness,
      {bool isAmoled = false}) {
    final isDark = brightness == Brightness.dark;
    final bg    = isDark ? AppColors.bgDark    : AppColors.bgLight;
    final card  = isDark ? AppColors.cardDark  : AppColors.cardLight;
    final card2 = isDark ? AppColors.cardDark2 : AppColors.cardLight2;

    return AppThemeColors(
      bg:     bg,
      onBg:   isDark ? AppColors.white : const Color(0xFF1A2621),
      card:   card,
      onCard: isDark ? AppColors.white : const Color(0xFF1A2621),
      card2:  card2,
      onCard2:isDark ? AppColors.white : const Color(0xFF1A2621),
      border: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFE2E8E4),
      text: isDark ? AppColors.white : const Color(0xFF1A2621),
      sub:  isDark
          ? Colors.white.withValues(alpha: 0.65) // 2026 pure alpha blending instead of muddy grey
          : const Color(0xFF64736D),
      fill: isDark
          ? Colors.white.withValues(alpha: 0.07)
          : const Color(0xFFEBEBE5),
      onFill:    isDark ? AppColors.white : const Color(0xFF1A2621),
      primary:   colorScheme.primary,
      onPrimary: colorScheme.onPrimary,
      secondary: colorScheme.secondary,
      error:     isDark ? AppColors.redDark  : AppColors.red,
      red:       isDark ? AppColors.redDark  : AppColors.red,
      redLight:  isDark
          ? AppColors.redDark.withValues(alpha: 0.15)
          : AppColors.red.withValues(alpha: 0.12),
      success:   isDark ? AppColors.greenDark : AppColors.green,
      green:     isDark ? AppColors.greenDark : AppColors.green,
      greenLight:isDark
          ? AppColors.greenDark.withValues(alpha: 0.15)
          : AppColors.green.withValues(alpha: 0.12),
      warning: isDark ? AppColors.amberDark : AppColors.amber,
      amber:   isDark ? AppColors.amberDark : AppColors.amber,
      info:    isDark ? AppColors.blueDark  : AppColors.blue,
      purple:  isDark ? AppColors.purpleDark: AppColors.purple,
      meshBg:  isDark ? AppColors.bgDark : AppColors.bgLight,
      // Cal AI glass: barely visible — no color tint
      glass:      isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.white.withValues(alpha: 0.85),
      glassBorder:isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFF3A7D6A).withValues(alpha: 0.1),
      shadowSoft:  [], // Cal AI: zero shadows everywhere
      mainGradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary]),
      // Cal AI signature orange — always constant regardless of mode
      accent:      isDark ? AppColors.accent : const Color(0xFF3A7D6A),
      accentLight: (isDark ? AppColors.accent : const Color(0xFF3A7D6A)).withValues(alpha: 0.15),
    );
  }

  @override
  AppThemeColors copyWith({
    Color? bg, Color? onBg, Color? card, Color? onCard, Color? card2, Color? onCard2,
    Color? border, Color? text, Color? sub, Color? fill, Color? onFill,
    Color? primary, Color? onPrimary, Color? secondary,
    Color? error, Color? red, Color? redLight,
    Color? success, Color? green, Color? greenLight,
    Color? warning, Color? amber, Color? info, Color? purple,
    Color? meshBg, Color? glass, Color? glassBorder,
    List<BoxShadow>? shadowSoft, LinearGradient? mainGradient,
    Color? accent, Color? accentLight,
  }) => AppThemeColors(
    bg: bg ?? this.bg, onBg: onBg ?? this.onBg,
    card: card ?? this.card, onCard: onCard ?? this.onCard,
    card2: card2 ?? this.card2, onCard2: onCard2 ?? this.onCard2,
    border: border ?? this.border, text: text ?? this.text,
    sub: sub ?? this.sub, fill: fill ?? this.fill, onFill: onFill ?? this.onFill,
    primary: primary ?? this.primary, onPrimary: onPrimary ?? this.onPrimary,
    secondary: secondary ?? this.secondary, error: error ?? this.error,
    red: red ?? this.red, redLight: redLight ?? this.redLight,
    success: success ?? this.success, green: green ?? this.green,
    greenLight: greenLight ?? this.greenLight,
    warning: warning ?? this.warning, amber: amber ?? this.amber,
    info: info ?? this.info, purple: purple ?? this.purple,
    meshBg: meshBg ?? this.meshBg, glass: glass ?? this.glass,
    glassBorder: glassBorder ?? this.glassBorder,
    shadowSoft: shadowSoft ?? this.shadowSoft,
    mainGradient: mainGradient ?? this.mainGradient,
    accent: accent ?? this.accent,
    accentLight: accentLight ?? this.accentLight,
  );

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      bg: Color.lerp(bg, other.bg, t)!, onBg: Color.lerp(onBg, other.onBg, t)!,
      card: Color.lerp(card, other.card, t)!, onCard: Color.lerp(onCard, other.onCard, t)!,
      card2: Color.lerp(card2, other.card2, t)!, onCard2: Color.lerp(onCard2, other.onCard2, t)!,
      border: Color.lerp(border, other.border, t)!, text: Color.lerp(text, other.text, t)!,
      sub: Color.lerp(sub, other.sub, t)!, fill: Color.lerp(fill, other.fill, t)!,
      onFill: Color.lerp(onFill, other.onFill, t)!,
      primary: Color.lerp(primary, other.primary, t)!, onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!, error: Color.lerp(error, other.error, t)!,
      red: Color.lerp(red, other.red, t)!, redLight: Color.lerp(redLight, other.redLight, t)!,
      success: Color.lerp(success, other.success, t)!, green: Color.lerp(green, other.green, t)!,
      greenLight: Color.lerp(greenLight, other.greenLight, t)!,
      warning: Color.lerp(warning, other.warning, t)!, amber: Color.lerp(amber, other.amber, t)!,
      info: Color.lerp(info, other.info, t)!, purple: Color.lerp(purple, other.purple, t)!,
      meshBg: Color.lerp(meshBg, other.meshBg, t)!, glass: Color.lerp(glass, other.glass, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      shadowSoft: BoxShadow.lerpList(shadowSoft, other.shadowSoft, t)!,
      mainGradient: LinearGradient.lerp(mainGradient, other.mainGradient, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentLight: Color.lerp(accentLight, other.accentLight, t)!,
    );
  }
}

extension ThemeContextExtension on BuildContext {
  AppThemeColors get L =>
      Theme.of(this).extension<AppThemeColors>() ??
      AppThemeColors.fromColorScheme(Theme.of(this).colorScheme, Theme.of(this).brightness);
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
