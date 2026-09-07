import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/utils/haptic_engine.dart';
import '../widgets/common/animated_pressable.dart';
import 'design_2026.dart';

export 'app_theme.dart';
export 'app_tokens.dart';
export 'app_inputs.dart';
export 'design_2026.dart';
export 'hope_vibe.dart';

// ════════════════════════════════════════════════════════════════
// MED AI UI — June 2026 design system
// iOS HIG + Material 3 Expressive · WCAG-safe · gesture-first
// ════════════════════════════════════════════════════════════════

/// WCAG 2.2 AA minimum contrast helpers and tap-target sizing.
abstract final class MedAiA11y {
  static const double minTapTarget = 48;
  static const double minTapTargetCompact = 44;

  /// Clamp dynamic type so layouts stay usable (iOS HIG guidance).
  static MediaQueryData clampTextScale(MediaQueryData mq) {
    final scale = mq.textScaler.scale(1.0).clamp(0.85, 1.35);
    return mq.copyWith(textScaler: TextScaler.linear(scale));
  }

  static bool reducedMotion(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  static Duration motion(BuildContext context, Duration normal) =>
      reducedMotion(context) ? Duration.zero : normal;
}

/// Motion choreography that respects system reduced-motion settings.
abstract final class MedAiMotion {
  static Duration entrance(BuildContext context) =>
      MedAiA11y.motion(context, AppDurations.hero);

  static List<Effect> cardEntrance(BuildContext context, int index) {
    if (MedAiA11y.reducedMotion(context)) return const [];
    return [
      FadeEffect(
        duration: AppDurations.fast,
        curve: AppCurves.smooth,
        delay: (index * 50).ms,
      ),
      SlideEffect(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
        duration: AppDurations.fast,
        curve: AppCurves.smooth,
        delay: (index * 50).ms,
      ),
    ];
  }

  /// Apply a flutter_animate chain only when motion is enabled.
  static Widget chain(
    BuildContext context,
    Widget child,
    Widget Function(Widget w) animate,
  ) {
    if (MedAiA11y.reducedMotion(context)) return child;
    return animate(child);
  }
}

extension MedAiWidgetMotion on Widget {
  /// `child.medAiChain(context, (w) => w.animate().fadeIn())`
  Widget medAiChain(
    BuildContext context,
    Widget Function(Widget w) animate,
  ) =>
      MedAiMotion.chain(context, this, animate);
}

// ────────────────────────────────────────────────────────────────
// FROSTED GLASS SURFACE — iOS liquid glass / M3 expressive layer
// ────────────────────────────────────────────────────────────────
class MedAiGlass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final Color? tint;
  final bool showBorder;
  final VoidCallback? onTap;

  const MedAiGlass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.p16),
    this.radius = AppRadius.xl,
    this.blur = 12,
    this.tint,
    this.showBorder = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final isDark = context.isDark;
    final reduceMotion = MedAiA11y.reducedMotion(context);
    final baseTint = tint ?? (isDark ? Colors.white : L.card);
    // Cap blur for 60fps; skip BackdropFilter on light mode / reduce motion
    // (Apple HIG: prefer solid materials when motion is reduced).
    final effectiveBlur = blur > 12 ? 12.0 : blur;
    final useBlur = isDark && !reduceMotion && effectiveBlur > 0;

    // NOTE: light mode intentionally ignores [tint] and paints L.card — ~45
    // call sites pass pastel tints that are only meant to show in dark mode.
    // A dark "selected state" tint therefore will NOT render here: use a solid
    // surface for that (see _SurfaceWrap in auth_screen.dart), or the selected
    // item will be invisible if its content color also flips.
    final decoration = BoxDecoration(
      color: useBlur
          ? null
          : (isDark
              ? baseTint.withValues(alpha: 0.14)
              : L.card.withValues(alpha: 0.97)),
      gradient: useBlur
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseTint.withValues(alpha: 0.12),
                baseTint.withValues(alpha: 0.06),
              ],
            )
          : null,
      borderRadius: BorderRadius.circular(radius),
      border: showBorder
          ? Border.all(
              color: L.glassBorder.withValues(alpha: isDark ? 0.14 : 0.22),
              width: 0.5,
            )
          : null,
      boxShadow: isDark ? AppShadows.glass : AppShadows.soft,
    );

    final content = Padding(padding: padding, child: child);

    Widget surface = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: useBlur
          ? BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: effectiveBlur,
                sigmaY: effectiveBlur,
              ),
              child: DecoratedBox(decoration: decoration, child: content),
            )
          : DecoratedBox(decoration: decoration, child: content),
    );

    if (onTap != null) {
      surface = Semantics(
        button: true,
        child: AnimatedPressable(
          onTap: onTap,
          scaleFactor: 0.98,
          child: surface,
        ),
      );
    }
    return surface;
  }
}

// ────────────────────────────────────────────────────────────────
// DEPTH CARD — layered elevation with accent rim glow
// ────────────────────────────────────────────────────────────────
class MedAiDepthCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final bool accentGlow;
  final VoidCallback? onTap;

  const MedAiDepthCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.p20),
    this.radius = AppRadius.xl,
    this.color,
    this.accentGlow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    Widget card = DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? L.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: L.border.withValues(alpha: 0.45), width: 0.5),
        boxShadow: accentGlow
            ? [...AppShadows.premium, ...L.accentGlow(intensity: 0.2)]
            : AppShadows.premium,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap != null) {
      card = AnimatedPressable(onTap: onTap, scaleFactor: 0.985, child: card);
    }
    return card;
  }
}

// ────────────────────────────────────────────────────────────────
// PRIMARY CTA — high-conversion pill button (48dp min height)
// ────────────────────────────────────────────────────────────────
class MedAiCTA extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final bool loading;
  final IconData? icon;
  final bool secondary;
  final bool fullWidth;
  final String? semanticsLabel;

  const MedAiCTA({
    super.key,
    required this.label,
    this.onTap,
    this.enabled = true,
    this.loading = false,
    this.icon,
    this.secondary = false,
    this.fullWidth = true,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final active = enabled && !loading && onTap != null;

    final bg = secondary ? L.fill : L.text;
    final fg = secondary ? L.text : L.bg;
    // Cal AI: primary button is near-black with a soft neutral shadow — no
    // brand-color glow (accent is reserved for data viz + streak).
    final glow = secondary
        ? <BoxShadow>[]
        : AppShadows.glow(L.text.withValues(alpha: 0.35), intensity: 0.2);

    return Semantics(
      button: true,
      enabled: active,
      label: semanticsLabel ?? label,
      child: AnimatedPressable(
        onTap: active ? onTap : null,
        disabled: !active,
        scaleFactor: 0.96,
        lightHaptic: false,
        child: AnimatedContainer(
          duration: MedAiA11y.motion(context, AppDurations.micro),
          curve: Curves.easeOutCubic,
          width: fullWidth ? double.infinity : null,
          constraints: const BoxConstraints(minHeight: MedAiA11y.minTapTarget),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: active ? bg : bg.withValues(alpha: 0.45),
            borderRadius: AppRadius.roundXL,
            border: secondary
                ? Border.all(color: L.border.withValues(alpha: 0.5), width: 0.5)
                : null,
            boxShadow: active ? glow : const [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (loading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: fg.withValues(alpha: 0.8),
                  ),
                )
              else if (icon != null) ...[
                Icon(icon, color: fg, size: 20),
                const SizedBox(width: 8),
              ],
              // Flexible, not a bare Text: a label sized by the user's text
              // scale — or simply longer in another language — overflowed the
              // button's own Row. It shrinks to fit before it clips.
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.labelLarge.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// GRADIENT HERO TEXT — kinetic display headline
// ────────────────────────────────────────────────────────────────
class MedAiHeroText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign align;

  const MedAiHeroText(
    this.text, {
    super.key,
    this.style,
    this.align = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final base = style ?? AppTypography.displayMedium.copyWith(color: L.text);

    if (MedAiA11y.reducedMotion(context)) {
      return Text(text, style: base, textAlign: align);
    }
    return KineticText(text, style: base, align: align);
  }
}

// ────────────────────────────────────────────────────────────────
// SWIPE TAB NAV — horizontal velocity gesture for tab switching
// ────────────────────────────────────────────────────────────────
class MedAiSwipeTabs extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final int tabCount;
  final ValueChanged<int> onTabChanged;

  const MedAiSwipeTabs({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.tabCount,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v.abs() < 280) return;
        if (v < 0 && currentIndex < tabCount - 1) {
          HapticEngine.selection();
          onTabChanged(currentIndex + 1);
        } else if (v > 0 && currentIndex > 0) {
          HapticEngine.selection();
          onTabChanged(currentIndex - 1);
        }
      },
      child: child,
    );
  }
}

// ────────────────────────────────────────────────────────────────
// SECTION HEADER — clear hierarchy label + optional action
// ────────────────────────────────────────────────────────────────
/// A quiet label for a single form field.
///
/// [MedAiSectionHeader] is sized for page sections — headlineSmall, w700. On a
/// form every field carried one, so "Full name", "Choose avatar" and
/// "Relationship" all shouted at the same volume as the page title and the
/// screen read as a wall of headings with the inputs hiding between them.
/// Field labels are supporting text: small, medium weight, muted.
class MedAiFieldLabel extends StatelessWidget {
  final String text;

  /// Rendered as a muted suffix rather than an asterisk — "*" has no meaning
  /// to a reader who has not been taught it, and this ships in 7 locales.
  final String? hint;

  const MedAiFieldLabel({super.key, required this.text, this.hint});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.p8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Flexible(
            child: Text(
              text,
              style: AppTypography.labelLarge.copyWith(
                color: L.text,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
          ),
          if (hint != null) ...[
            const SizedBox(width: AppSpacing.p8),
            Text(
              hint!,
              style: AppTypography.bodySmall.copyWith(
                color: L.sub,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MedAiSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const MedAiSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.p12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.headlineSmall.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTypography.bodySmall.copyWith(color: L.sub),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
