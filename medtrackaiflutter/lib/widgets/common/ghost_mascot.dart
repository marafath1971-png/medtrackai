import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/med_ai_assets.dart';
import '../../theme/med_ai_ui.dart';

/// Shared renderer for the extracted ghost-mascot PNGs (assets/mascots/).
///
/// One place owns how a mascot looks and moves so every screen stays
/// consistent. Ask by intent — `GhostMascot.feature('caregiver')` — and the
/// character logic in [MedAiAssets.mascotFor] picks the right sticker.
///
/// Motion is deliberately calm and "alive", not bouncy:
///   • a slow vertical breathing float,
///   • a barely-there rotational sway,
///   • an optional soft radial halo behind the sticker.
/// All looping motion is suppressed under reduced-motion (only a static image
/// renders). Falls back to a tinted disc if the PNG isn't bundled.
class GhostMascot extends StatefulWidget {
  /// Explicit asset path (use [GhostMascot.feature] to resolve by intent).
  final String asset;
  final double size;

  /// Continuous idle float/sway. Turn off in dense lists or when the parent
  /// already animates the mascot's entrance only.
  final bool idle;

  /// Soft radial glow behind the sticker — good for hero/empty states.
  final bool showGlow;

  /// Amplitude of the float in logical px. Scaled with [size] by default.
  final double? floatAmplitude;

  final String? semanticLabel;

  const GhostMascot({
    super.key,
    required this.asset,
    this.size = 96,
    this.idle = true,
    this.showGlow = false,
    this.floatAmplitude,
    this.semanticLabel,
  });

  /// Resolve the best-fit mascot for an app feature/context (shares the mapping
  /// used across onboarding, home and family). See [MedAiAssets.mascotFor].
  factory GhostMascot.feature(
    String feature, {
    Key? key,
    double size = 96,
    bool idle = true,
    bool showGlow = false,
    double? floatAmplitude,
    String? semanticLabel,
  }) =>
      GhostMascot(
        key: key,
        asset: MedAiAssets.mascotFor(feature),
        size: size,
        idle: idle,
        showGlow: showGlow,
        floatAmplitude: floatAmplitude,
        semanticLabel: semanticLabel,
      );

  @override
  State<GhostMascot> createState() => _GhostMascotState();
}

class _GhostMascotState extends State<GhostMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // A long, prime-ish period keeps the float and sway from visibly syncing.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPlayback();
  }

  @override
  void didUpdateWidget(covariant GhostMascot old) {
    super.didUpdateWidget(old);
    if (old.idle != widget.idle) _syncPlayback();
  }

  void _syncPlayback() {
    final shouldRun = widget.idle && !MedAiA11y.reducedMotion(context);
    if (shouldRun) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final amp = widget.floatAmplitude ?? (widget.size * 0.045).clamp(2.0, 6.0);

    final sticker = Image.asset(
      widget.asset,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => Container(
        width: widget.size * 0.72,
        height: widget.size * 0.72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: L.accent.withValues(alpha: 0.10),
          border: Border.all(color: L.accent.withValues(alpha: 0.25)),
        ),
        child: Icon(Icons.medication_liquid_rounded,
            color: L.accent, size: widget.size * 0.30),
      ),
    );

    Widget content = Semantics(
      image: true,
      label: widget.semanticLabel ?? 'Med AI mascot',
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (widget.showGlow)
            Container(
              width: widget.size + widget.size * 0.5,
              height: widget.size + widget.size * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    L.accent.withValues(alpha: 0.14),
                    L.accent.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          sticker,
        ],
      ),
    );

    if (!widget.idle || MedAiA11y.reducedMotion(context)) return content;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        child: content,
        builder: (context, child) {
          final t = _controller.value * math.pi * 2;
          final dy = math.sin(t) * amp;
          // Sway on a slower harmonic so it never looks mechanical.
          final rot = math.sin(t * 0.5) * 0.02;
          return Transform.translate(
            offset: Offset(0, dy),
            child: Transform.rotate(angle: rot, child: child),
          );
        },
      ),
    );
  }
}
