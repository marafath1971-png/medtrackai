import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/premium_photos.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/med_ai_logo.dart';
import '../../../widgets/common/med_ai_mascot.dart';
import '../onboarding_theme.dart';
import 'ob_photo_hero.dart';
import 'ob_widgets.dart';

// ════════════════════════════════════════════════════════════════════════
// PictureThis-inspired widgets — adapted for Med AI medication features.
// ════════════════════════════════════════════════════════════════════════

/// Vertical accent bars used on cinematic splash / trial flash screens.
class ObAccentBars extends StatelessWidget {
  const ObAccentBars({super.key, Color? color})
      : color = color ?? Design2026.electric;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MedAiA11y.reducedMotion(context);
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: _Bar(height: 0.38, color: color, animate: !reduceMotion),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: _Bar(
              height: 0.28,
              color: Colors.white.withValues(alpha: 0.12),
              animate: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;
  final Color color;
  final bool animate;

  const _Bar({
    required this.height,
    required this.color,
    required this.animate,
  });

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height * height;
    Widget bar = Container(width: 3, height: h, color: color);
    if (animate && !MedAiA11y.reducedMotion(context)) {
      bar = bar
          .animate()
          .fadeIn(duration: 500.ms)
          .scaleY(begin: 0.9, end: 1.0, duration: 500.ms, curve: AppCurves.smooth);
    }
    return bar;
  }
}

/// Soft splash — logo + pulse (loading screen).
class ObCinematicSplash extends StatelessWidget {
  final String? subtitle;
  const ObCinematicSplash({super.key, this.subtitle});

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
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!reduceMotion)
              SizedBox(
                child: const MedAiMascot(
                  size: 100,
                  animate: false,
                  semanticLabel: 'Med AI',
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(
                    begin: const Offset(0.96, 0.96),
                    end: const Offset(1, 1),
                    duration: 600.ms,
                    curve: AppCurves.smooth,
                  )
            else
              const MedAiMascot(
                size: 100,
                animate: false,
                semanticLabel: 'Med AI',
              ),
            const SizedBox(height: 28),
            Builder(
              builder: (_) {
                final title = Text(
                  'Med AI',
                  style: AppTypography.headlineLarge.copyWith(
                    color: p.text,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                );
                return reduceMotion
                    ? title
                    : title.animate().fadeIn(duration: 600.ms);
              },
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 10),
              Builder(
                builder: (_) {
                  final sub = Text(
                    subtitle!,
                    style: AppTypography.bodySmall.copyWith(color: p.sub),
                  );
                  return reduceMotion
                      ? sub
                      : sub.animate().fadeIn(delay: 200.ms, duration: 500.ms);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Masonry-style intro grid — pill / scan imagery columns.
class ObMasonryGallery extends StatefulWidget {
  const ObMasonryGallery({super.key});

  @override
  State<ObMasonryGallery> createState() => _ObMasonryGalleryState();
}

class _ObMasonryGalleryState extends State<ObMasonryGallery>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static const _tints = [
    AppColors.accent,
    AppColors.electric,
    AppColors.limeDeep,
    Color(0xFF4ABFE2),
    Color(0xFFF5A623),
    Color(0xFFE5573F),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!MedAiA11y.reducedMotion(context)) {
        _ctrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MedAiA11y.reducedMotion(context);
    return SizedBox(
      height: 220,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.l),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final offset = reduceMotion ? 0.0 : _ctrl.value * 40;
            return Row(
              children: [
                _Column(offset: offset, reverse: false, tints: _tints),
                const SizedBox(width: 6),
                _Column(offset: -offset * 0.7, reverse: true, tints: _tints),
                const SizedBox(width: 6),
                _Column(offset: offset * 0.5, reverse: false, tints: _tints),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Column extends StatelessWidget {
  final double offset;
  final bool reverse;
  final List<Color> tints;

  const _Column({
    required this.offset,
    required this.reverse,
    required this.tints,
  });

  @override
  Widget build(BuildContext context) {
    const assets = PremiumPhotos.gallery;
    return Expanded(
      child: Transform.translate(
        offset: Offset(0, offset),
        child: Column(
          children: List.generate(4, (i) {
            final idx = reverse ? 3 - i : i;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _PillTile(
                  color: tints[idx % tints.length],
                  asset: assets[(idx + (reverse ? 2 : 0)) % assets.length],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _PillTile extends StatelessWidget {
  final Color color;
  final String asset;
  const _PillTile({required this.color, required this.asset});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            asset,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) => ColoredBox(color: color),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.45),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen #1 social proof interstitial — soft premium (not dark cinema).
class ObRankInterstitial extends StatelessWidget {
  final VoidCallback onContinue;
  const ObRankInterstitial({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            PremiumPhotos.rank,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => ColoredBox(color: p.bgTop),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66000000),
                  Color(0x33000000),
                  Color(0xF2FFF8F2),
                ],
                stops: [0.0, 0.4, 0.72],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.limeDeep.withValues(alpha: 0.16),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'YOUR #1 PLAN',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.accentDeep,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '#1',
                          style: AppTypography.displayLarge.copyWith(
                            color: p.text,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -2,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Medication companion',
                          style: AppTypography.titleLarge.copyWith(
                            color: p.text,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Scan. Know. Never miss a dose.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(
                            color: p.sub,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ).obFadeUp(),
                  const SizedBox(height: 20),
                  Text(
                    'Trusted by 500,000+ people managing their health',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkStrong.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w600,
                    ),
                  ).obFadeUp(delayMs: 80),
                  const Spacer(),
                  ObPrimaryButton(label: 'Continue', onTap: onContinue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Photo hero scenes — HD lifestyle imagery for onboarding hooks.
enum ObHeroScene { thriving, diagnose, scan, family }

class ObHeroIllustration extends StatelessWidget {
  final ObHeroScene scene;
  final double height;

  const ObHeroIllustration({
    super.key,
    required this.scene,
    this.height = 260,
  });

  @override
  Widget build(BuildContext context) {
    final (asset, line) = switch (scene) {
      ObHeroScene.diagnose => (
          PremiumPhotos.know,
          'Know every med before you take it.'
        ),
      ObHeroScene.thriving => (
          PremiumPhotos.thrive,
          'Consistency that feels like success.'
        ),
      ObHeroScene.family => (
          PremiumPhotos.family,
          'Peace of mind for people you love.'
        ),
      ObHeroScene.scan => (
          PremiumPhotos.scanFeature,
          'Scan once. Understand forever.'
        ),
    };

    return ObPhotoHero(
      asset: asset,
      height: height,
      overlayLine: line,
    );
  }
}

class ObAccuracyBarChart extends StatefulWidget {
  final double ourScore;
  final double otherScore;
  final String source;

  const ObAccuracyBarChart({
    super.key,
    this.ourScore = 0.94,
    this.otherScore = 0.57,
    this.source = 'Based on internal benchmark vs. 5 leading pill ID apps',
  });

  @override
  State<ObAccuracyBarChart> createState() => _ObAccuracyBarChartState();
}

class _ObAccuracyBarChartState extends State<ObAccuracyBarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!MedAiA11y.reducedMotion(context)) {
        _ctrl.forward();
      } else {
        _ctrl.value = 1;
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    final multiplier = widget.ourScore / widget.otherScore;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_ctrl.value);
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(AppRadius.l),
            border: Border.all(color: p.border.withValues(alpha: 0.5)),
            boxShadow: AppShadows.premium,
          ),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _BarColumn(
                        label: 'Other apps',
                        score: widget.otherScore,
                        progress: t,
                        color: p.sub.withValues(alpha: 0.35),
                        icon: Icons.apps_rounded,
                        iconColor: p.sub,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topCenter,
                        children: [
                          _BarColumn(
                            label: 'Med AI',
                            score: widget.ourScore,
                            progress: t,
                            color: p.accent,
                            icon: null,
                            useLogo: true,
                          ),
                          if (t > 0.6)
                            Positioned(
                              top: -8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF8C42),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.arrow_upward_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${multiplier.toStringAsFixed(2)}×',
                                      style: AppTypography.labelMedium.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (t > 0.5)
                CustomPaint(
                  size: const Size(double.infinity, 40),
                  painter: _ArcConnectorPainter(
                    progress: (t - 0.5) * 2,
                    color: p.border.withValues(alpha: 0.9),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                widget.source,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(color: p.sub),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BarColumn extends StatelessWidget {
  final String label;
  final double score;
  final double progress;
  final Color color;
  final IconData? icon;
  final Color? iconColor;
  final bool useLogo;

  const _BarColumn({
    required this.label,
    required this.score,
    required this.progress,
    required this.color,
    this.icon,
    this.iconColor,
    this.useLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    final pct = '${(score * 100).round()}%';
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          pct,
          style: AppTypography.headlineSmall.copyWith(
            color: useLogo ? color : iconColor ?? color,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: score * progress,
              widthFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (useLogo)
          MedAiLogo.badge(size: 36)
        else if (icon != null)
          Icon(icon!, color: iconColor, size: 24),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ArcConnectorPainter extends CustomPainter {
  final double progress;
  final Color color;
  _ArcConnectorPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final path = Path();
    path.moveTo(size.width * 0.25, size.height);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * (1 - progress),
      size.width * 0.75,
      0,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcConnectorPainter old) =>
      old.progress != progress;
}

/// Full-screen trial flash — soft premium (not dark cinema).
class ObTrialFlashInterstitial extends StatelessWidget {
  final VoidCallback onContinue;
  const ObTrialFlashInterstitial({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.bgTop, p.bg],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 36, 24, 36),
                  decoration: BoxDecoration(
                    color: p.surfaceSel,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.limeDeep.withValues(alpha: 0.16),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'FREE TRIAL',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.accentDeep,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: AppTypography.headlineLarge.copyWith(
                            color: p.text,
                            fontWeight: FontWeight.w800,
                            fontSize: 30,
                            height: 1.2,
                            letterSpacing: -0.4,
                          ),
                          children: const [
                            TextSpan(text: 'Start '),
                            TextSpan(
                              text: '7',
                              style: TextStyle(color: AppColors.limeDeep),
                            ),
                            TextSpan(text: ' days\nfor free'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Full access. Cancel anytime.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          color: p.sub,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ).obFadeUp(),
                const Spacer(flex: 3),
                ObPrimaryButton(label: 'Continue', onTap: onContinue),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paywall feature icon grid — colored circular badges.
class ObPaywallFeatureGrid extends StatelessWidget {
  const ObPaywallFeatureGrid({super.key});

  static const _items = [
    (Icons.warning_amber_rounded, Color(0xFFE5573F), 'Interactions'),
    (Icons.notifications_active_rounded, Color(0xFF4ABFE2), 'Reminders'),
    (Icons.alarm_rounded, AppColors.accent, 'Alarms'),
    (Icons.camera_alt_rounded, AppColors.limeDeep, 'Scan'),
    (Icons.medical_services_rounded, Color(0xFFFF8C42), 'Reports'),
    (Icons.family_restroom_rounded, AppColors.electric, 'Family'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          return Stack(
            children: List.generate(_items.length, (i) {
              final (icon, color, _) = _items[i];
              final angle = (i / _items.length) * math.pi * 2 - math.pi / 2;
              final cx = w * 0.5 + math.cos(angle) * w * 0.32;
              final cy = 60 + math.sin(angle) * 42;
              return Positioned(
                left: cx - 28,
                top: cy - 28,
                child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            )
                .animate(delay: (i * 60).ms)
                .fadeIn(duration: 400.ms)
                .scale(
                  begin: const Offset(0.6, 0.6),
                  end: const Offset(1, 1),
                  curve: AppCurves.emilOut,
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// Medicine detail skeleton — loading state for scan results.
class ObMedicineDetailSkeleton extends StatelessWidget {
  const ObMedicineDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: p.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ShimmerBox(
                width: 80,
                height: 80,
                radius: 12,
                color: p.border,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(width: 160, height: 18, color: p.border),
                    const SizedBox(height: 8),
                    _ShimmerBox(width: 120, height: 14, color: p.border),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: List.generate(
              3,
              (_) => Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: _ShimmerBox(height: 48, color: p.border),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ShimmerBox(width: double.infinity, height: 100, color: p.border),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final Color color;

  const _ShimmerBox({
    this.width,
    required this.height,
    this.radius = 8,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
  final reduceMotion = MedAiA11y.reducedMotion(context);
    Widget box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
    if (!reduceMotion) {
      box = box
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(
            duration: 1200.ms,
            color: Colors.white.withValues(alpha: 0.15),
          );
    }
    return box;
  }
}
