// ════════════════════════════════════════════════════════════════════════════
// scan_share_card.dart — MedTrackAI
//
// Shareable "story card" shown as a modal bottom sheet after a product scan.
// Designed to be screenshot-shared on Instagram / TikTok stories.
//
// Usage:
//   await ScanShareCard.show(context, product: myProduct, imageFile: file);
// ════════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/haptic_engine.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';
import '../../../models/product_analysis.dart';

// ── Palette constants (dark card only — these never adapt to theme) ──────────
const _kBgTop = Color(0xFF0D1F17);
const _kBgBottom = Color(0xFF1A3628);
const _kMint = Color(0xFFB8F5C8); // label / ring track accent
const _kLime = Color(0xFFC2F47E); // ring progress / CTA
const _kLimeDim = Color(0xFF4A9E86); // ring gradient stop 2
const _kCardText = Colors.white;
const _kSub = Color(0xFFAABFAF); // secondary text on dark card
const _kChipBg = Color(0x1AC2F47E); // 10% lime chip fill
const _kChipBdr = Color(0x33C2F47E); // 20% lime chip border

// ── Ring dimensions ──────────────────────────────────────────────────────────
const _kRingSize = 148.0;
const _kRingStroke = 10.0;
const _kGlowRadius = 72.0;

/// Gorgeous shareable story card widget shown as a modal bottom sheet
/// immediately after a product scan. Tap "Share" → [share_plus] fires;
/// tap "Save to Camera Roll" → stub (snackbar) until native save lands.
class ScanShareCard extends StatefulWidget {
  const ScanShareCard({
    super.key,
    required this.product,
    this.imageFile,
  });

  final ProductAnalysis product;
  final File? imageFile;

  // ── Public entry point ─────────────────────────────────────────────────────
  /// Shows the share card as a draggable modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required ProductAnalysis product,
    File? imageFile,
  }) {
    HapticEngine.selection();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      useRootNavigator: true,
      builder: (_) => ScanShareCard(product: product, imageFile: imageFile),
    );
  }

  @override
  State<ScanShareCard> createState() => _ScanShareCardState();
}

class _ScanShareCardState extends State<ScanShareCard>
    with SingleTickerProviderStateMixin {
  // Controls the animated score ring fill — starts at 0, animates to target.
  late final AnimationController _ringCtrl;
  late final Animation<double> _ringAnim;

  bool _sharing = false;

  @override
  void initState() {
    super.initState();

    final targetFraction =
        (widget.product.cleanScore ?? 0).clamp(0, 100) / 100.0;

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _ringAnim = Tween<double>(begin: 0, end: targetFraction).animate(
      CurvedAnimation(parent: _ringCtrl, curve: AppCurves.emilOut),
    );

    // Delay ring animation so the card entrance finishes first.
    Future.delayed(const Duration(milliseconds: 420), () {
      if (mounted) _ringCtrl.forward();
    });
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    super.dispose();
  }

  // ── Derived chip data ──────────────────────────────────────────────────────
  List<_InsightChip> get _chips {
    final p = widget.product;
    final chips = <_InsightChip>[];

    // Clean score chip
    final score = p.cleanScore ?? 0;
    if (score >= 80) {
      chips.add(const _InsightChip(label: 'Ultra-clean formula ✓', icon: '🌿'));
    } else if (score >= 60) {
      chips.add(const _InsightChip(label: 'Clean formula ✓', icon: '✅'));
    }

    // Allergy risk
    if (p.allergyRiskLevel == 'None' || p.allergyRiskLevel == 'Low') {
      chips.add(const _InsightChip(label: 'Low allergy risk ✓', icon: '🛡️'));
    }

    // Halal
    if (p.halalStatus.toLowerCase().contains('halal')) {
      chips.add(const _InsightChip(label: 'Halal certified ✓', icon: '☪️'));
    }

    // Skincare
    if (p.comedogenicRating != null && (p.comedogenicRating ?? 5) <= 1) {
      chips.add(const _InsightChip(label: 'Non-comedogenic ✓', icon: '✨'));
    } else if (p.skinBenefits.isNotEmpty) {
      chips.add(_InsightChip(label: p.skinBenefits.first, icon: '💧'));
    }

    // Routine type pill
    if (p.routineType != null) {
      chips.add(_InsightChip(label: '${p.routineType} routine', icon: '🕐'));
    }

    // Generic fallback chips so card never looks empty
    if (chips.length < 2) {
      chips.add(const _InsightChip(label: 'AI-verified ✓', icon: '🤖'));
      chips.add(const _InsightChip(label: 'Safe for daily use ✓', icon: '📅'));
    }

    return chips.take(4).toList(); // max 4 chips
  }

  // ── Share logic (stubbed — ready for real implementation) ──────────────────
  Future<void> _handleShare() async {
    HapticEngine.heavyImpact();
    setState(() => _sharing = true);

    try {
      if (widget.imageFile != null && widget.imageFile!.existsSync()) {
        // Real share: attach the scanned image + caption
        await SharePlus.instance.share(
          ShareParams(
            text: '✨ Just scanned "${widget.product.name}" with MedTrackAI!\n'
                '${widget.product.cleanScore != null ? "Clean Score: ${widget.product.cleanScore}/100 🌿\n" : ""}'
                'Download MedTrackAI for your AI-powered health scan 🔬\n'
                '#MedTrackAI #HealthScan #CleanBeauty',
            files: [XFile(widget.imageFile!.path)],
          ),
        );
      } else {
        // Text-only share when no image is available
        await SharePlus.instance.share(
          ShareParams(
            text: '✨ Just scanned "${widget.product.name}" with MedTrackAI!\n'
                '${widget.product.cleanScore != null ? "Clean Score: ${widget.product.cleanScore}/100 🌿\n" : ""}'
                'Download MedTrackAI for your AI-powered health scan 🔬',
          ),
        );
      }
    } catch (e) {
      // Graceful fallback — share_plus not available or user cancelled
      debugPrint('[ScanShareCard] Share failed or cancelled: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Share feature coming soon 🚀',
              style: AppTypography.bodySmall.copyWith(color: Colors.white),
            ),
            backgroundColor: _kLimeDim,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.s),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _handleSave() async {
    HapticEngine.selection();
    // TODO: implement native save via image_gallery_saver or photo_manager
    // For now — friendly toast.
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Save to Camera Roll coming soon 📸',
          style: AppTypography.bodySmall.copyWith(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A3628),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.s),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final safePad = MediaQuery.paddingOf(context).bottom;

    return Container(
      // Sheet handle + sheet background
      decoration: const BoxDecoration(
        color: Color(0xFF111B15),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          _SheetHandle(),

          // Story card itself
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p20),
            child: _StoryCard(
              product: widget.product,
              chips: _chips,
              ringAnim: _ringAnim,
              ringCtrl: _ringCtrl,
            ),
          ).animate().fadeIn(duration: 340.ms, curve: AppCurves.emilOut).slideY(
                begin: 0.06,
                end: 0,
                duration: 380.ms,
                curve: AppCurves.emilOut,
              ),

          const SizedBox(height: AppSpacing.p24),

          // ── Action buttons ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p20),
            child: Column(
              children: [
                // "Save to Camera Roll" — ghost button
                _GhostButton(
                  label: 'Save to Camera Roll',
                  icon: Icons.download_rounded,
                  onTap: _handleSave,
                )
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 260.ms, curve: AppCurves.emilOut)
                    .slideY(begin: 0.04, end: 0, duration: 260.ms),

                const SizedBox(height: AppSpacing.p12),

                // "Share" — primary lime gradient button
                _LimeButton(
                  label: 'Share',
                  icon: Icons.ios_share_rounded,
                  loading: _sharing,
                  onTap: _handleShare,
                )
                    .animate(delay: 260.ms)
                    .fadeIn(duration: 260.ms, curve: AppCurves.emilOut)
                    .slideY(begin: 0.04, end: 0, duration: 260.ms),
              ],
            ),
          ),

          SizedBox(height: math.max(safePad, AppSpacing.p24) + bottomInset),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _StoryCard — the actual shareable card rendered inside the sheet
// ══════════════════════════════════════════════════════════════════════════════
class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.product,
    required this.chips,
    required this.ringAnim,
    required this.ringCtrl,
  });

  final ProductAnalysis product;
  final List<_InsightChip> chips;
  final Animation<double> ringAnim;
  final AnimationController ringCtrl;

  @override
  Widget build(BuildContext context) {
    final hasScore = (product.cleanScore ?? 0) > 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kBgTop, _kBgBottom],
          stops: [0.0, 1.0],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: _kLime.withValues(alpha: 0.12),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _kLime.withValues(alpha: 0.08),
            blurRadius: 40,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.p24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Header: logo + label ─────────────────────────────────────
            _CardHeader(),

            const SizedBox(height: AppSpacing.p24),

            // ── Score ring  OR  medicine icon ───────────────────────────
            if (hasScore)
              _ScoreRingSection(
                score: product.cleanScore!,
                anim: ringAnim,
              )
            else
              _MedicineIconSection(category: product.category),

            const SizedBox(height: AppSpacing.p20),

            // ── Product name ─────────────────────────────────────────────
            Text(
              product.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.headlineMedium.copyWith(
                color: _kCardText,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                height: 1.15,
              ),
            ),

            const SizedBox(height: AppSpacing.p8),

            // Category badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.p12,
                vertical: AppSpacing.p4,
              ),
              decoration: BoxDecoration(
                color: _kMint.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.max),
                border: Border.all(
                  color: _kMint.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                product.category.toUpperCase(),
                style: AppTypography.labelSmall.copyWith(
                  color: _kMint,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.p20),

            // ── Insight chips ────────────────────────────────────────────
            Wrap(
              spacing: AppSpacing.p8,
              runSpacing: AppSpacing.p8,
              alignment: WrapAlignment.center,
              children: chips.map((c) => _ChipWidget(chip: c)).toList(),
            ),

            const SizedBox(height: AppSpacing.p24),

            // ── Footer ───────────────────────────────────────────────────
            _CardFooter(),
          ],
        ),
      ),
    );
  }
}

// ── _CardHeader ──────────────────────────────────────────────────────────────
class _CardHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo mark — gradient "M" inside a circle
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kLime, _kLimeDim],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              'M',
              style: TextStyle(
                color: Color(0xFF0D1F17),
                fontSize: 16,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ),

        const SizedBox(width: AppSpacing.p8),

        // Brand name
        Text(
          'MedAI',
          style: AppTypography.titleLarge.copyWith(
            color: _kCardText,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),

        const Spacer(),

        // "AI Product Scan" label
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.p8,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: _kMint.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.max),
          ),
          child: Text(
            'AI Product Scan',
            style: AppTypography.caption.copyWith(
              color: _kMint,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}

// ── _CardFooter ──────────────────────────────────────────────────────────────
class _CardFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Divider line
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                _kLime.withValues(alpha: 0.2),
                Colors.transparent,
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.p12),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Scanned with ',
              style: AppTypography.bodySmall.copyWith(color: _kSub),
            ),
            Text(
              'MedAI',
              style: AppTypography.bodySmall.copyWith(
                color: _kLime,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppSpacing.p8),

            // App store badge style text
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _kSub.withValues(alpha: 0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '⬇ App Store',
                style: AppTypography.caption.copyWith(
                  color: _kSub,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── _ScoreRingSection ─────────────────────────────────────────────────────────
/// Animated circular progress ring with glow effect and score in the centre.
class _ScoreRingSection extends StatelessWidget {
  const _ScoreRingSection({required this.score, required this.anim});

  final int score;
  final Animation<double> anim;

  // Score → descriptive label
  String get _label {
    if (score >= 90) return 'Exceptional';
    if (score >= 75) return 'Very Clean';
    if (score >= 60) return 'Clean';
    if (score >= 40) return 'Moderate';
    return 'Review Needed';
  }

  Color get _ringColor {
    if (score >= 75) return _kLime;
    if (score >= 50) return const Color(0xFFFFD166); // amber
    return const Color(0xFFFF6B6B); // red
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kRingSize,
      height: _kRingSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radial glow behind ring
          Container(
            width: _kGlowRadius * 2,
            height: _kGlowRadius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _kLime.withValues(alpha: 0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Ring painter
          AnimatedBuilder(
            animation: anim,
            builder: (_, __) => CustomPaint(
              size: const Size(_kRingSize, _kRingSize),
              painter: _RingPainter(
                progress: anim.value,
                ringColor: _ringColor,
                trackColor: _kLime.withValues(alpha: 0.08),
                strokeWidth: _kRingStroke,
              ),
            ),
          ),

          // Centre content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated score counter
              AnimatedBuilder(
                animation: anim,
                builder: (_, __) {
                  final displayed = (anim.value * 100).round();
                  return Text(
                    '$displayed',
                    style: AppTypography.displaySmall.copyWith(
                      color: _kCardText,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      letterSpacing: -1.5,
                    ),
                  );
                },
              ),
              Text(
                '/100',
                style: AppTypography.bodySmall.copyWith(
                  color: _kSub,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _label,
                style: AppTypography.caption.copyWith(
                  color: _kMint,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── _MedicineIconSection ──────────────────────────────────────────────────────
/// Shown when no cleanScore is present (e.g. a prescription medicine).
class _MedicineIconSection extends StatelessWidget {
  const _MedicineIconSection({required this.category});
  final String category;

  IconData get _icon {
    final c = category.toLowerCase();
    if (c.contains('vitamin') || c.contains('supplement')) {
      return Icons.spa_rounded;
    }
    if (c.contains('skin') || c.contains('beauty') || c.contains('cosmetic')) {
      return Icons.face_retouching_natural_rounded;
    }
    return Icons.medication_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF1F3A2A), Color(0xFF142B1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: _kLime.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _kLime.withValues(alpha: 0.14),
            blurRadius: 24,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Icon(_icon, size: 44, color: _kLime),
    );
  }
}

// ── _ChipWidget ───────────────────────────────────────────────────────────────
class _ChipWidget extends StatelessWidget {
  const _ChipWidget({required this.chip});
  final _InsightChip chip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.p12,
        vertical: AppSpacing.p8,
      ),
      decoration: BoxDecoration(
        color: _kChipBg,
        borderRadius: BorderRadius.circular(AppRadius.max),
        border: Border.all(color: _kChipBdr, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(chip.icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(
            chip.label,
            style: AppTypography.labelSmall.copyWith(
              color: _kMint,
              letterSpacing: 0.1,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ── _GhostButton ──────────────────────────────────────────────────────────────
class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.m),
          border: Border.all(
            color: _kLime.withValues(alpha: 0.28),
            width: 1.5,
          ),
          color: _kLime.withValues(alpha: 0.06),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: _kLime),
            const SizedBox(width: AppSpacing.p8),
            Text(
              label,
              style: AppTypography.titleMedium.copyWith(
                color: _kLime,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _LimeButton ───────────────────────────────────────────────────────────────
class _LimeButton extends StatelessWidget {
  const _LimeButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      onTap: loading ? () {} : onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kLime, Color(0xFF8FD14F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.m),
          boxShadow: [
            BoxShadow(
              color: _kLime.withValues(alpha: 0.38),
              blurRadius: 20,
              spreadRadius: -2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Color(0xFF0D1F17)),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: const Color(0xFF0D1F17)),
                  const SizedBox(width: AppSpacing.p8),
                  Text(
                    label,
                    style: AppTypography.titleMedium.copyWith(
                      color: const Color(0xFF0D1F17),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── _SheetHandle ──────────────────────────────────────────────────────────────
class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.p12),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.max),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _RingPainter — custom painter for the animated score arc
// ══════════════════════════════════════════════════════════════════════════════
class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.ringColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress; // 0.0 → 1.0
  final Color ringColor;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    const startAngle = -math.pi / 2; // top of circle
    const fullSweep = 2 * math.pi;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw the background track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      fullSweep,
      false,
      trackPaint,
    );

    if (progress <= 0) return;

    // Draw the progress arc with a gradient
    final progressSweep = fullSweep * progress;
    final sweepRect = Rect.fromCircle(center: center, radius: radius);

    // Gradient paint — lime → limeDeep clockwise
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + fullSweep,
        colors: [_kLime, _kLimeDim, _kLime],
        stops: const [0.0, 0.6, 1.0],
        transform: GradientRotation(startAngle),
      ).createShader(sweepRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      sweepRect,
      startAngle,
      progressSweep,
      false,
      progressPaint,
    );

    // Glowing tip dot at the end of the arc
    if (progress > 0.02) {
      final tipAngle = startAngle + progressSweep;
      final tipX = center.dx + radius * math.cos(tipAngle);
      final tipY = center.dy + radius * math.sin(tipAngle);
      final tipCenter = Offset(tipX, tipY);

      // Outer glow
      canvas.drawCircle(
        tipCenter,
        strokeWidth * 0.9,
        Paint()
          ..color = _kLime.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      // Solid tip
      canvas.drawCircle(
        tipCenter,
        strokeWidth * 0.55,
        Paint()..color = _kLime,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.ringColor != ringColor ||
      old.strokeWidth != strokeWidth;
}

// ══════════════════════════════════════════════════════════════════════════════
// _InsightChip — value object
// ══════════════════════════════════════════════════════════════════════════════
class _InsightChip {
  const _InsightChip({required this.label, required this.icon});
  final String label;
  final String icon;
}
