import 'package:flutter/cupertino.dart';
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
  static const Color bgLight  = Color(0xFFFFF8F2);  // Eato cream canvas
  static const Color eatoNavy = Color(0xFF1A2238); // PDF / onboarding CTA ink
  static const Color eatoGold = Color(0xFFE8943A); // PDF selection accent
  static const Color bgDark   = Color(0xFF0B132B);  // Deep Slate Blue
  static const Color cardLight  = Color(0xFFFFFFFF);
  static const Color cardDark   = Color(0xFF1C2541); // Midnight Navy
  static const Color cardLight2 = Color(0xFFF1F3F5); // Light mode fill/container card
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

  // ── ⭐ ACCENT DUO (see DESIGN.md §3.1) ─────────────
  // TWO accents, split strictly by domain — never three, never ad-hoc:
  //   • SAGE (this)  → clinical / scan / medicine detail / safety / caregiver / AI
  //   • LIME (below) → daily / home / dashboard / success / streaks / CTAs
  // Danger stays red; orange is RETIRED. Pick by what the surface is ABOUT.
  static const Color accent      = Color(0xFF4A9E86); // Sage — clinical primary
  static const Color accentLight = Color(0xFF8EDABF); // Lighter sage variant
  static const Color sageGreen   = accent;
  static const Color oceanBlue   = Color(0xFF0C2D48); // Deep Luxury Blue
  static const Color coralRed    = Color(0xFFFF5E5B); // Premium Soft Red

  // ── ⭐ LIME — daily / success accent (accent duo, see DESIGN.md §3.1) ─────
  // Lime-green signature + soft pastel category tints on pure white, from the
  // reference design set. Owns home/dashboard/streaks/success/primary CTAs.
  static const Color lime        = Color(0xFFB4E869); // signature hero card
  static const Color limeDeep    = Color(0xFF8FD14F); // lime, higher contrast
  static const Color limeInk     = Color(0xFF2E3D1B); // text on lime
  static const Color pastelMint  = Color(0xFFE4F5E7);
  static const Color pastelSky   = Color(0xFFD9ECF7);
  static const Color pastelPink  = Color(0xFFFCE4E6);
  static const Color pastelSun   = Color(0xFFFFF3D1);
  static const Color pastelLilac = Color(0xFFEDE7F9);
  static const Color inkStrong   = Color(0xFF1A1D26); // near-black headings
  static const Color inkSoft     = Color(0xFF9AA0A6); // muted captions

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
  static const Color cyanAccent     = accent; // legacy alias → sage (orange retired)
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

  /// Electric CTA cyan (2026 accent system). Prefer over raw `0xFF6CF2D2`.
  static const Color electric = Color(0xFF6CF2D2);
  /// Deeper sage for pressed/onboarding ink variants.
  static const Color accentDeep = Color(0xFF3D8A72);

  // Drift aliases — same hue family as brand tokens (kills Tailwind/ad-hoc hex).
  static const Color dangerSoft = Color(0xFFEF4444); // maps ← Tailwind red-500
  static const Color successSoft = Color(0xFF10B981); // maps ← Tailwind emerald
  static const Color warningSoft = Color(0xFFF59E0B); // maps ← Tailwind amber
  static const Color infoSoft = Color(0xFF0A84FF); // maps ← AppColors.blue
  static const Color indigo = Color(0xFF6366F1);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color orangeIos = Color(0xFFFF9500); // iOS system orange
  static const Color pinkSystem = Color(0xFFFF2D55);

  /// Cal AI icon-badge fill opacity (~12%). Use [badgeFill] — never scatter alphas.
  static const double badgeFillOpacity = 0.12;

  /// Soft chip behind icons on neutral cards (Cal AI pattern).
  static Color badgeFill(Color ink) =>
      ink.withValues(alpha: badgeFillOpacity);

  static const Color lRed    = red;
  static const Color dRed    = redDark;
  static const Color oBg     = bgDark;
  static const Color oText   = white;
  static const Color oBorder = grey800;
  static const Color oFill   = grey900;
  static const Color oLime   = accent;
  static const Color oLimeDark = accent;

  /// Cream-card surface matching onboarding / home (light mode).
  static BoxDecoration eatoCard(
    AppThemeColors L, {
    bool isDark = false,
    double radius = 28,
    bool goldBorder = true,
  }) {
    return BoxDecoration(
      color: L.card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark
            ? L.border.withValues(alpha: 0.35)
            : (goldBorder
                ? eatoGold.withValues(alpha: 0.14)
                : L.border.withValues(alpha: 0.55)),
        width: isDark ? 0.5 : 1,
      ),
      boxShadow: isDark
          ? AppShadows.premium
          : [
              BoxShadow(
                color: eatoNavy.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
    );
  }
}

class AppTheme {
  static final String? _fontFamily = GoogleFonts.outfit().fontFamily;

  static ThemeData light({String? accentHex}) {
    final acc = accentHex != null ? hexToColor(accentHex) : const Color(0xFF3A7D6A);
    final scheme = ColorScheme.light(
      primary: AppColors.eatoNavy,
      onPrimary: AppColors.white,
      secondary: acc,
      onSecondary: AppColors.white,
      surface: AppColors.cardLight,
      onSurface: AppColors.eatoNavy,
      error: AppColors.red,
      outline: const Color(0xFFE8E0D6),
      surfaceContainer: AppColors.cardLight2,
      surfaceContainerHighest: AppColors.cardLight2,
    );
    return ThemeData(
      useMaterial3: true,
      fontFamily: _fontFamily,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgLight,
      colorScheme: scheme,
      textTheme: _buildTextTheme(AppColors.eatoNavy),
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
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
        showDragHandle: true,
        dragHandleColor: Color(0xFFD1D5DB),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: AppColors.cardLight.withValues(alpha: 0.92),
        indicatorColor: acc.withValues(alpha: 0.12),
        labelTextStyle: WidgetStatePropertyAll(
          AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.eatoNavy : AppColors.grey500,
            size: 22,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardLight2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppRadius.roundXL,
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.roundXL,
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.roundXL,
          borderSide: BorderSide(color: acc, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.roundXL,
          borderSide: const BorderSide(color: AppColors.red),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, AppA11y.minTapTarget),
          backgroundColor: AppColors.eatoNavy,
          foregroundColor: AppColors.white,
          textStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundXL),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, AppA11y.minTapTarget),
          foregroundColor: const Color(0xFF1A2621),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.7)),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundXL),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, AppA11y.minTapTarget),
          foregroundColor: acc,
          textStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
        ),
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
          minimumSize: const Size(double.infinity, AppA11y.minTapTarget),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundXL),
          elevation: 0,
        ),
      ),
    ).copyWith(
      extensions: [
        AppThemeColors.fromColorScheme(scheme, Brightness.light),
      ],
    );
  }

  static ThemeData dark({bool isAmoled = true, String? accentHex}) {
    final acc = accentHex != null ? hexToColor(accentHex) : AppColors.accent;
    final scheme = ColorScheme.dark(
      primary: AppColors.white,
      onPrimary: AppColors.black,
      secondary: acc,
      onSecondary: AppColors.black,
      surface: AppColors.cardDark,
      onSurface: AppColors.white,
      error: AppColors.redDark,
      outline: AppColors.grey800,
      surfaceContainer: AppColors.cardDark,
      surfaceContainerHighest: AppColors.cardDark2,
    );
    return ThemeData(
      useMaterial3: true,
      fontFamily: _fontFamily,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: scheme,
      textTheme: _buildTextTheme(AppColors.white),
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
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
        showDragHandle: true,
        dragHandleColor: Color(0xFF475569),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: AppColors.cardDark.withValues(alpha: 0.88),
        indicatorColor: acc.withValues(alpha: 0.18),
        labelTextStyle: WidgetStatePropertyAll(
          AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.white : AppColors.grey400,
            size: 22,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardDark2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppRadius.roundXL,
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.roundXL,
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.roundXL,
          borderSide: BorderSide(color: acc, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.roundXL,
          borderSide: const BorderSide(color: AppColors.redDark),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, AppA11y.minTapTarget),
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.black,
          textStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundXL),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, AppA11y.minTapTarget),
          foregroundColor: AppColors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundXL),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, AppA11y.minTapTarget),
          foregroundColor: acc,
          textStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
        ),
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
          minimumSize: const Size(double.infinity, AppA11y.minTapTarget),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundXL),
          elevation: 0,
        ),
      ),
    ).copyWith(
      extensions: [
        AppThemeColors.fromColorScheme(scheme, Brightness.dark, isAmoled: isAmoled),
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
  // Accent duo (DESIGN.md §3.1): theme `accent` resolves to SAGE (clinical
  // primary). Lime (daily/success) is applied at the surface via AppColors.lime.
  final Color accent;        // sage — clinical primary (orange retired)
  final Color accentLight;   // sage 15% fill

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
      onBg:   isDark ? AppColors.white : AppColors.eatoNavy,
      card:   card,
      onCard: isDark ? AppColors.white : AppColors.eatoNavy,
      card2:  card2,
      onCard2:isDark ? AppColors.white : AppColors.eatoNavy,
      border: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFE8E0D6),
      text: isDark ? AppColors.white : AppColors.eatoNavy,
      sub:  isDark
          ? Colors.white.withValues(alpha: 0.65) // 2026 pure alpha blending instead of muddy grey
          : const Color(0xFF5C6B64),
      fill: isDark
          ? Colors.white.withValues(alpha: 0.07)
          : const Color(0xFFF1F3F5),
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
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [colorScheme.secondary.withValues(alpha: 0.35), colorScheme.primary]
            : [colorScheme.secondary.withValues(alpha: 0.25), colorScheme.primary],
      ),
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

/// 2026 unified accent tokens — electric CTA on sage wellness base.
extension AppThemeColors2026 on AppThemeColors {
  static const Color electric = AppColors.electric;
  static const Color wellness = AppColors.accent;

  Color get accentElectric => electric;
  Color get accentWellness => wellness;
  Color get accentGlowColor => electric.withValues(alpha: 0.35);

  List<BoxShadow> accentGlow({double intensity = 0.4}) =>
      AppShadows.glow(electric, intensity: intensity);
}

/// A high-performance 2D shared-axis transition (slight vertical translation + cross-fade)
/// designed to meet the 250ms easeOutCubic specification for Android.
class MaterialSharedAxisFadePageTransitionsBuilder extends PageTransitionsBuilder {
  const MaterialSharedAxisFadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final slideIn = Tween<Offset>(
      begin: const Offset(0.0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Cubic(0.215, 0.610, 0.355, 1.000), // easeOutCubic
    ));

    final fadeIn = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Cubic(0.215, 0.610, 0.355, 1.000), // easeOutCubic
    ));

    final slideOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, -0.04),
    ).animate(CurvedAnimation(
      parent: secondaryAnimation,
      curve: const Cubic(0.215, 0.610, 0.355, 1.000), // easeOutCubic
    ));

    final fadeOut = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: secondaryAnimation,
      curve: const Cubic(0.215, 0.610, 0.355, 1.000), // easeOutCubic
    ));

    return SlideTransition(
      position: slideIn,
      child: FadeTransition(
        opacity: fadeIn,
        child: SlideTransition(
          position: slideOut,
          child: FadeTransition(
            opacity: fadeOut,
            child: child,
          ),
        ),
      ),
    );
  }
}
