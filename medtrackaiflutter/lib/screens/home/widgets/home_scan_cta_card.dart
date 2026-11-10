// ════════════════════════════════════════════════════════════════════════════
// HomeScanCtaCard — Cal AI-style scan hero for MedTrackAI home screen.
//
// Design DNA: TikTok immediacy · Cal AI scan-card energy · Apple polish.
// Everything breathes — nothing is static.
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/utils/haptic_engine.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

/// A full-width Cal AI-style scan CTA card for the home screen.
///
/// Shows:
///   - A horizontally scrollable row of feature chips (staggered entrance)
///   - A large gradient hero banner (pressable → [onScan])
///   - A bottom row of 3 social-proof stat chips
///
/// All elements animate on first build via `flutter_animate`. The hero card
/// has a continuous pulsing border ring and a pulsing sparkle icon to keep
/// the UI alive at all times.
class HomeScanCtaCard extends StatelessWidget {
  /// Called when the user taps the hero banner. Wire to your scan flow.
  final VoidCallback onScan;

  const HomeScanCtaCard({super.key, required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1 ── Feature chips row ─────────────────────────────────────────────
        _FeatureChipsRow(),
        const SizedBox(height: AppSpacing.p12),

        // 2 ── Hero banner ───────────────────────────────────────────────────
        _HeroBannerCard(onScan: onScan),
        const SizedBox(height: AppSpacing.p12),

        // 3 ── Social-proof stat chips ───────────────────────────────────────
        _StatChipsRow(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Feature chips — horizontal scroll, staggered entrance
// ─────────────────────────────────────────────────────────────────────────────

class _FeatureChipsRow extends StatelessWidget {
  // Each chip: [emoji, label]
  static const _chips = [
    ('🔬', 'Scan Medicine'),
    ('✨', 'Skincare Check'),
    ('🌿', 'Supplements'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      // Align with screen gutter; right padding gives visual breathing room.
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: Row(
        children: [
          for (int i = 0; i < _chips.length; i++) ...[
            _FeatureChip(
              emoji: _chips[i].$1,
              label: _chips[i].$2,
              animationDelay: (i * 80).ms,
            ),
            if (i < _chips.length - 1) const SizedBox(width: AppSpacing.p8),
          ],
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String emoji;
  final String label;
  final Duration animationDelay;

  const _FeatureChip({
    required this.emoji,
    required this.label,
    required this.animationDelay,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return AnimatedPressable(
      scaleFactor: 0.93,
      onTap: HapticEngine.selection,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.p16,
          vertical: AppSpacing.p8,
        ),
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(AppRadius.max),
          border: Border.all(
            color: L.border.withValues(alpha: 0.55),
            width: 1,
          ),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: AppSpacing.p8),
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: L.text,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    )
        // Staggered entrance: fade up from slight offset
        .animate()
        .fadeIn(
          duration: AppDurations.medium,
          delay: animationDelay,
          curve: AppCurves.smooth,
        )
        .slideY(
          begin: 0.18,
          end: 0,
          duration: AppDurations.medium,
          delay: animationDelay,
          curve: AppCurves.emilOut,
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Hero banner card — gradient, pulsing ring, sparkle, camera icon
// ─────────────────────────────────────────────────────────────────────────────

class _HeroBannerCard extends StatefulWidget {
  final VoidCallback onScan;
  const _HeroBannerCard({required this.onScan});

  @override
  State<_HeroBannerCard> createState() => _HeroBannerCardState();
}

class _HeroBannerCardState extends State<_HeroBannerCard>
    with SingleTickerProviderStateMixin {
  // Drives the continuous pulsing border ring (scale 1.0 → 1.025 → 1.0).
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.025).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: AnimatedPressable(
        scaleFactor: 0.975,
        opacityFactor: 0.92,
        lightHaptic: false,
        onTap: () {
          HapticEngine.heavyImpact();
          widget.onScan();
        },
        child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, child) => Transform.scale(
            scale: _pulseAnim.value,
            alignment: Alignment.center,
            child: child,
          ),
          child: _CardContent(),
        ),
      )
          // Hero entrance: fade + slide up
          .animate()
          .fadeIn(
            duration: AppDurations.hero,
            delay: 60.ms,
            curve: AppCurves.smooth,
          )
          .slideY(
            begin: 0.12,
            end: 0,
            duration: AppDurations.hero,
            delay: 60.ms,
            curve: AppCurves.emilOut,
          ),
    );
  }
}

/// The visual interior of the hero card, separated so [AnimatedBuilder]
/// can skip rebuilding the heavy widget tree on every pulse tick.
class _CardContent extends StatelessWidget {
  const _CardContent();

  // Brand gradient: limeDeep → forest green
  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.limeDeep, // #4A9E86
      Color(0xFF2A7D5F), // deep forest accent
    ],
    stops: [0.0, 1.0],
  );

  // Subtle diagonal sheen overlay for depth
  static const _sheen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x22FFFFFF),
      Color(0x00FFFFFF),
    ],
    stops: [0.0, 0.6],
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.p24),
      decoration: BoxDecoration(
        gradient: _gradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        // Pulsing ring via multiple box shadows (outer glow)
        boxShadow: [
          BoxShadow(
            color: AppColors.limeDeep.withValues(alpha: 0.45),
            blurRadius: 28,
            spreadRadius: -4,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFF2A7D5F).withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
            offset: Offset.zero,
          ),
        ],
      ),
      child: Stack(
        children: [
          // ── Sheen overlay ─────────────────────────────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: _sheen,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
            ),
          ),

          // ── Main row: text left, camera icon right ─────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left column: sparkle + headline + sub
              Expanded(child: _HeroTextBlock()),

              const SizedBox(width: AppSpacing.p20),

              // Right: camera scan icon in white circle
              _CameraIconBadge(),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bold headline + sub + pulsing sparkle icon (left column of hero card).
class _HeroTextBlock extends StatelessWidget {
  const _HeroTextBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pulsing AI sparkle icon above headline
        _PulsingSparkle(),
        const SizedBox(height: AppSpacing.p12),

        // Bold headline
        Text(
          'Scan anything.\nKnow everything.',
          style: AppTypography.displaySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
            height: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.p8),

        // Muted sub-text
        Text(
          'Meds • Skincare • Supplements',
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.70),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

/// Continuously pulsing `Icons.auto_awesome_rounded` in white.
class _PulsingSparkle extends StatelessWidget {
  const _PulsingSparkle();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.auto_awesome_rounded,
      color: Colors.white,
      size: 22,
    )
        // Repeating fade + scale pulse for the sparkle
        .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
        .scaleXY(
          begin: 0.88,
          end: 1.12,
          duration: const Duration(milliseconds: 1400),
          curve: Curves.easeInOut,
        )
        .fadeIn(
          begin: 0.55,
          duration: const Duration(milliseconds: 1400),
          curve: Curves.easeInOut,
        );
  }
}

/// White circle containing a camera scan icon (right of hero card).
class _CameraIconBadge extends StatelessWidget {
  const _CameraIconBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.document_scanner_rounded,
            color: AppColors.limeDeep,
            size: 24,
          ),
        ),
      ),
    )
        // Entrance: pop in with spring scale
        .animate()
        .scaleXY(
          begin: 0.0,
          end: 1.0,
          duration: AppDurations.hero,
          delay: 200.ms,
          curve: AppCurves.spring,
        )
        .fadeIn(
          duration: AppDurations.medium,
          delay: 200.ms,
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Social-proof stat chips row
// ─────────────────────────────────────────────────────────────────────────────

class _StatChipsRow extends StatelessWidget {
  static const _stats = [
    ('2M+ Users', Icons.people_alt_rounded),
    ('5-star Rated', Icons.star_rounded),
    ('AI-Powered', Icons.bolt_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: Row(
        children: [
          for (int i = 0; i < _stats.length; i++) ...[
            Expanded(
              child: _StatChip(
                label: _stats[i].$1,
                icon: _stats[i].$2,
                animationDelay: (120 + i * 70).ms,
              ),
            ),
            if (i < _stats.length - 1) const SizedBox(width: AppSpacing.p8),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Duration animationDelay;

  const _StatChip({
    required this.label,
    required this.icon,
    required this.animationDelay,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.p8,
        vertical: AppSpacing.p8,
      ),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(AppRadius.m),
        border: Border.all(
          color: L.border.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: AppColors.limeDeep,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: L.text,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    )
        // Staggered entrance: fade + scale from slightly below
        .animate()
        .fadeIn(
          duration: AppDurations.medium,
          delay: animationDelay,
          curve: AppCurves.smooth,
        )
        .slideY(
          begin: 0.2,
          end: 0,
          duration: AppDurations.medium,
          delay: animationDelay,
          curve: AppCurves.emilOut,
        )
        .scaleXY(
          begin: 0.92,
          end: 1.0,
          duration: AppDurations.medium,
          delay: animationDelay,
          curve: AppCurves.emilOut,
        );
  }
}
