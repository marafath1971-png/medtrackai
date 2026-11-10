import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/med_ai_ui.dart';

/// One arc of a [StepRing].
class StepRingArc {
  /// Progress toward the goal; values above 1 draw a full ring.
  final double progress;
  final Color color;
  final Color track;

  const StepRingArc({
    required this.progress,
    required this.color,
    required this.track,
  });
}

/// Concentric progress rings, outermost first. One arc is a solo day; two is
/// "you and your partner".
class StepRing extends StatelessWidget {
  final List<StepRingArc> arcs;
  final double size;
  final double stroke;
  final Widget? child;

  const StepRing({
    super.key,
    required this.arcs,
    this.size = 200,
    this.stroke = 16,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        // Sweeps in once. Later refreshes repaint at the new value without
        // replaying the entrance, so the ring never snaps back to empty.
        tween: Tween(begin: 0, end: 1),
        duration: MedAiA11y.motion(context, AppDurations.slow),
        curve: AppCurves.emilOut,
        builder: (context, t, child) => CustomPaint(
          painter: _RingPainter(arcs: arcs, t: t, stroke: stroke),
          child: child,
        ),
        child: child == null ? null : Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final List<StepRingArc> arcs;
  final double t;
  final double stroke;

  _RingPainter({required this.arcs, required this.t, required this.stroke});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    var radius = (size.shortestSide - stroke) / 2;

    for (final arc in arcs) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final track = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = arc.track;
      canvas.drawCircle(center, radius, track);

      final sweep = 2 * math.pi * arc.progress.clamp(0.0, 1.0) * t;
      if (sweep > 0.001) {
        final fill = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = arc.color;
        canvas.drawArc(rect, -math.pi / 2, sweep, false, fill);
      }
      radius -= stroke + 5;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.t != t || old.stroke != stroke || old.arcs != arcs;
}
