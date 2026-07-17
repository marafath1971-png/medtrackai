import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/utils/haptic_engine.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';
import '../../../widgets/common/ghost_mascot.dart';
import '../onboarding_theme.dart';

// ════════════════════════════════════════════════════════════════════════
// OB SCAFFOLD — aurora atmosphere + glass footer CTA dock
// ════════════════════════════════════════════════════════════════════════
class ObScaffold extends StatelessWidget {
  final double progress;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final Widget child;
  final String ctaLabel;
  final bool ctaEnabled;
  final VoidCallback? onCta;
  final Widget? secondaryCta;

  const ObScaffold({
    super.key,
    required this.progress,
    required this.child,
    this.onBack,
    this.onSkip,
    this.ctaLabel = 'Continue',
    this.ctaEnabled = true,
    this.onCta,
    this.secondaryCta,
  });

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    final reduceMotion = MedAiA11y.reducedMotion(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.bgTop, p.bg],
          stops: const [0.0, 0.45],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (!reduceMotion)
              AuroraBackground(colors: p.aurora, opacity: context.isDark ? 0.38 : 0.22),
            SafeArea(
              child: Column(
                children: [
                  _TopBar(progress: progress, onBack: onBack, onSkip: onSkip),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                      child: child,
                    ),
                  ),
                  ClipRect(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: p.surface,
                        border: Border(
                          top: BorderSide(color: p.border.withValues(alpha: 0.65)),
                        ),
                        boxShadow: AppShadows.soft,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (secondaryCta != null) ...[
                              secondaryCta!,
                              const SizedBox(height: 10),
                            ],
                            ObPrimaryButton(
                              label: ctaLabel,
                              enabled: ctaEnabled,
                              onTap: onCta,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final double progress;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  const _TopBar({required this.progress, this.onBack, this.onSkip});

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          _CircleIcon(
            icon: Icons.arrow_back_ios_new_rounded,
            color: p.text,
            bg: p.surface,
            border: p.border,
            onTap: onBack == null
                ? null
                : () {
                    HapticEngine.light();
                    onBack!();
                  },
          ),
          const SizedBox(width: 12),
          Expanded(child: ObProgressBar(progress: progress)),
          const SizedBox(width: 12),
          if (onSkip != null)
            Semantics(
              button: true,
              label: 'Skip onboarding',
              child: AnimatedPressable(
                onTap: () {
                  HapticEngine.light();
                  onSkip!();
                },
                hitTestPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Text(
                    'Skip',
                    style: AppTypography.labelLarge.copyWith(color: p.sub),
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 28),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final Color border;
  final VoidCallback? onTap;
  const _CircleIcon({
    required this.icon,
    required this.color,
    required this.bg,
    required this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (onTap == null) {
      return const SizedBox(width: AppA11y.minTapTargetCompact, height: AppA11y.minTapTargetCompact);
    }
    return Semantics(
      button: true,
      label: 'Go back',
      child: AnimatedPressable(
        onTap: onTap,
        scaleFactor: 0.94,
        child: Container(
          width: AppA11y.minTapTargetCompact,
          height: AppA11y.minTapTargetCompact,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: border, width: 0.5),
            boxShadow: AppShadows.soft,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// PROGRESS BAR — gradient fill with expressive easing
// ════════════════════════════════════════════════════════════════════════
class ObProgressBar extends StatelessWidget {
  final double progress;
  const ObProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    final reduceMotion = MedAiA11y.reducedMotion(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress.clamp(0, 1)),
        duration: reduceMotion ? Duration.zero : AppDurations.medium,
        curve: AppCurves.expressive,
        builder: (context, value, _) => SizedBox(
          height: 6,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: p.border),
              FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: value,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [p.accent, p.electric],
                    ),
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: AppShadows.glow(p.electric, intensity: 0.25),
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

// ════════════════════════════════════════════════════════════════════════
// PRIMARY BUTTON — high-conversion ink pill with accent glow
// ════════════════════════════════════════════════════════════════════════
class ObPrimaryButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback? onTap;
  const ObPrimaryButton({
    super.key,
    required this.label,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    final active = enabled && onTap != null;

    return Semantics(
      button: true,
      enabled: active,
      label: label,
      child: AnimatedOpacity(
        duration: MedAiA11y.motion(context, AppDurations.fast),
        opacity: active ? 1 : 0.4,
        child: AnimatedPressable(
          hapticEnabled: false,
          onTap: active
              ? () {
                  HapticEngine.selection();
                  onTap!();
                }
              : () => HapticEngine.light(),
          scaleFactor: 0.96,
          child: Container(
            constraints: const BoxConstraints(minHeight: AppA11y.minTapTarget),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              gradient: active
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [p.cta, p.cta.withValues(alpha: 0.88)],
                    )
                  : null,
              color: active ? null : p.cta.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: p.cta.withValues(alpha: 0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: AppTypography.titleMedium.copyWith(
                color: p.ctaInk,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// HEADLINE — kinetic accent keywords via *asterisks*
// ════════════════════════════════════════════════════════════════════════
class ObHeadline extends StatelessWidget {
  final String text;
  final String? subtitle;
  final TextAlign align;
  const ObHeadline(
    this.text, {
    super.key,
    this.subtitle,
    this.align = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    final spans = <TextSpan>[];
    final parts = text.split('*');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      final highlight = i.isOdd;
      spans.add(TextSpan(
        text: parts[i],
        style: TextStyle(color: highlight ? p.accent : p.text),
      ));
    }

    return Column(
      crossAxisAlignment: align == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        RichText(
          textAlign: align,
          text: TextSpan(
            style: AppTypography.headlineLarge.copyWith(
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
            children: spans,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 10),
          Text(
            subtitle!,
            textAlign: align,
            style: AppTypography.bodyMedium.copyWith(
              color: p.sub,
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// OB MASCOT — feature-matched ghost sticker on a soft halo (onboarding hero)
// ════════════════════════════════════════════════════════════════════════
/// Drops a ghost mascot (from [MedAiAssets.mascotFor]) into a step as the
/// emotional anchor. Ask by intent — `feature: 'welcome' | 'caregiver' |
/// 'streak' | 'success' | 'calm' | 'family'…` — so the same character logic is
/// shared with the rest of the app. One-shot fade + gentle float entrance
/// (never loops — a step hero shouldn't bounce), fully skipped under
/// reduced-motion. Degrades to a soft tinted disc if the PNG isn't bundled.
class ObMascot extends StatelessWidget {
  final String feature;
  final double size;
  const ObMascot({super.key, required this.feature, this.size = 96});

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    final reduceMotion = MedAiA11y.reducedMotion(context);

    final halo = Container(
      width: size + 44,
      height: size + 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            p.accent.withValues(alpha: 0.12),
            p.accent.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: GhostMascot.feature(
        feature,
        size: size,
        // Idle float gives the hero life; the outer one-shot entrance below
        // handles the reveal. Both are suppressed under reduced-motion.
        idle: !reduceMotion,
      ),
    );

    final hero = Center(child: halo);
    if (reduceMotion) return hero;
    return hero
        .animate()
        .fadeIn(duration: 450.ms, curve: Curves.easeOut)
        .scale(
          begin: const Offset(0.82, 0.82),
          end: const Offset(1, 1),
          duration: 550.ms,
          curve: Curves.easeOutBack,
        )
        .slideY(begin: 0.06, end: 0, duration: 500.ms, curve: Curves.easeOut);
  }
}

// ════════════════════════════════════════════════════════════════════════
// OPTION CARD — glass-depth selectable row, 48dp min height
// ════════════════════════════════════════════════════════════════════════
class ObOptionCard extends StatelessWidget {
  final String label;
  final String? subtitle;
  final String? emoji;
  final IconData? icon;
  final bool selected;
  final bool multiSelect;
  final VoidCallback onTap;
  const ObOptionCard({
    super.key,
    required this.label,
    this.subtitle,
    this.emoji,
    this.icon,
    required this.selected,
    required this.multiSelect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: AnimatedPressable(
        hapticEnabled: false,
        onTap: () {
          HapticEngine.selection();
          onTap();
        },
        scaleFactor: 0.985,
        child: AnimatedContainer(
          duration: MedAiA11y.motion(context, AppDurations.fast),
          curve: AppCurves.expressive,
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: selected ? p.surfaceSel : p.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? p.borderSel : p.border,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected ? null : AppShadows.soft,
          ),
          child: Row(
            children: [
              if (emoji != null)
                Text(emoji!, style: const TextStyle(fontSize: 22))
              else if (icon != null)
                Icon(icon, size: 22, color: p.accent),
              if (emoji != null || icon != null) const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: AppTypography.titleMedium.copyWith(
                        color: p.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTypography.bodySmall.copyWith(color: p.sub),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _Marker(selected: selected, multiSelect: multiSelect, p: p),
            ],
          ),
        ),
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  final bool selected;
  final bool multiSelect;
  final ObPalette p;
  const _Marker({
    required this.selected,
    required this.multiSelect,
    required this.p,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: MedAiA11y.motion(context, AppDurations.micro),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        gradient: selected
            ? LinearGradient(colors: [p.accent, p.electric])
            : null,
        color: selected ? null : Colors.transparent,
        shape: multiSelect ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: multiSelect ? BorderRadius.circular(7) : null,
        border: Border.all(
          color: selected ? p.accent : p.border,
          width: 2,
        ),
      ),
      child: selected
          ? Icon(Icons.check_rounded, size: 16, color: p.accentInk)
          : null,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// SMALL UI ATOMS
// ════════════════════════════════════════════════════════════════════════
class ObPill extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? color;
  const ObPill({super.key, required this.text, this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    final c = color ?? p.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: c.withValues(alpha: 0.22), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: c),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: AppTypography.labelMedium.copyWith(
              color: c,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class ObStars extends StatelessWidget {
  final int count;
  final String? caption;
  const ObStars({super.key, this.count = 5, this.caption});

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (i) => Icon(
              i < count ? Icons.star_rounded : Icons.star_outline_rounded,
              color: const Color(0xFFFFB020),
              size: 26,
            ),
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 6),
          Text(
            caption!,
            style: AppTypography.bodySmall.copyWith(color: p.sub),
          ),
        ],
      ],
    );
  }
}

class ObStatBlock extends StatelessWidget {
  final String stat;
  final String caption;
  const ObStatBlock({super.key, required this.stat, required this.caption});

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            p.warmTint,
            p.accent.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: p.accent.withValues(alpha: 0.22), width: 0.5),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Text(
            stat,
            style: AppTypography.displaySmall.copyWith(
              color: p.accent,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              caption,
              style: AppTypography.bodySmall.copyWith(
                color: p.text,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Entrance helper — respects reduced-motion system setting.
extension ObEntrance on Widget {
  Widget obFadeUp({int delayMs = 0}) {
    return Builder(builder: (context) {
      if (MedAiA11y.reducedMotion(context)) return this;
      return animate(delay: delayMs.ms)
          .fadeIn(duration: 350.ms, curve: AppCurves.smooth)
          .slideY(begin: 0.04, end: 0, duration: 350.ms, curve: AppCurves.smooth);
    });
  }
}
