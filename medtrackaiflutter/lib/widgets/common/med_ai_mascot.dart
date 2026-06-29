import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/med_ai_assets.dart';
import '../../theme/design_2026.dart';

/// Reusable 3D-feeling Med AI mascot.
///
/// Use the animated version on hero/header/empty states. Prefer
/// [animate: false] in repeated lists to avoid unnecessary work.
class MedAiMascot extends StatefulWidget {
  final double size;
  final bool animate;
  final bool showGlow;
  final String semanticLabel;

  const MedAiMascot({
    super.key,
    this.size = 72,
    this.animate = true,
    this.showGlow = true,
    this.semanticLabel = 'Med AI assistant mascot',
  });

  const MedAiMascot.static({
    super.key,
    this.size = 28,
    this.showGlow = false,
    this.semanticLabel = 'Med AI assistant',
  }) : animate = false;

  @override
  State<MedAiMascot> createState() => _MedAiMascotState();
}

class _MedAiMascotState extends State<MedAiMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant MedAiMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) {
      widget.animate ? _controller.repeat() : _controller.stop();
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

    Widget child = Semantics(
      image: true,
      label: widget.semanticLabel,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (widget.showGlow)
            Container(
              width: widget.size * 0.92,
              height: widget.size * 0.92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Design2026.electric.withValues(alpha: 0.32),
                    L.accent.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Design2026.electric.withValues(alpha: 0.22),
                    blurRadius: widget.size * 0.38,
                    spreadRadius: widget.size * 0.03,
                  ),
                ],
              ),
            ),
          Image.asset(
            MedAiAssets.illustrationAppIconBlue,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [L.accent, Design2026.electric],
                ),
              ),
              child: Icon(
                Icons.medication_liquid_rounded,
                color: Colors.white,
                size: widget.size * 0.46,
              ),
            ),
          ),
        ],
      ),
    );

    if (!widget.animate) return child;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value * math.pi * 2;
          final dy = math.sin(t) * 4;
          final rotateY = math.sin(t * 0.75) * 0.08;
          final rotateX = math.cos(t * 0.65) * 0.045;
          return Transform.translate(
            offset: Offset(0, dy),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0018)
                ..rotateX(rotateX)
                ..rotateY(rotateY),
              child: child,
            ),
          );
        },
      )
          .animate()
          .fadeIn(duration: 450.ms)
          .scaleXY(begin: 0.92, end: 1, curve: Curves.easeOutBack),
    );
  }
}
