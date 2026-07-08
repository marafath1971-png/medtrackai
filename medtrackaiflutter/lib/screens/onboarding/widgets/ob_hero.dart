import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/utils/haptic_engine.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/med_ai_mascot.dart';
import '../onboarding_theme.dart';

// ════════════════════════════════════════════════════════════════════════
// MASCOT HERO — animated Med AI character with soft halo + caption.
// ════════════════════════════════════════════════════════════════════════
class ObMascotHero extends StatelessWidget {
  final double size;
  final bool animate;
  const ObMascotHero({super.key, this.size = 132, this.animate = false});

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    return Center(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (!MedAiA11y.reducedMotion(context))
            SizedBox(
              width: size + 80,
              height: size + 80,
              child: AuroraBackground(
                colors: p.aurora,
                opacity: 0.28,
              ),
            ),
          Container(
            width: size + 40,
            height: size + 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  p.electric.withValues(alpha: 0.14),
                  p.accent.withValues(alpha: 0.0),
                ],
              ),
            ),
            child: MedAiMascot(
              size: size,
              animate: animate,
              semanticLabel: 'Med AI assistant',
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// COMPARISON — "Without" vs "With Med AI" side-by-side value cards.
// ════════════════════════════════════════════════════════════════════════
class ObComparison extends StatelessWidget {
  final String leftTitle;
  final List<String> leftPoints;
  final String rightTitle;
  final List<String> rightPoints;
  const ObComparison({
    super.key,
    this.leftTitle = 'Without Med AI',
    required this.leftPoints,
    this.rightTitle = 'With Med AI',
    required this.rightPoints,
  });

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _ComparisonCard(
              title: leftTitle,
              points: leftPoints,
              accent: p.sub,
              positive: false,
              p: p,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ComparisonCard(
              title: rightTitle,
              points: rightPoints,
              accent: p.accent,
              positive: true,
              p: p,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  final String title;
  final List<String> points;
  final Color accent;
  final bool positive;
  final ObPalette p;
  const _ComparisonCard({
    required this.title,
    required this.points,
    required this.accent,
    required this.positive,
    required this.p,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: positive ? p.accent.withValues(alpha: 0.10) : p.surface,
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(
          color: positive ? p.electric.withValues(alpha: 0.45) : p.border,
          width: positive ? 1.5 : 0.5,
        ),
        boxShadow: positive
            ? AppShadows.glow(p.accent, intensity: 0.2)
            : AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.labelLarge.copyWith(
              color: positive ? p.accent : p.sub,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...points.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    positive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    size: 18,
                    color: positive ? p.good : p.bad.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t,
                      style: AppTypography.bodySmall.copyWith(color: p.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// PROJECTION CHART — rising adherence curve from "Today" to a goal.
// ════════════════════════════════════════════════════════════════════════
class ObProjectionChart extends StatelessWidget {
  final double start; // 0..1
  final double end; // 0..1
  final String startLabel;
  final String endLabel;
  const ObProjectionChart({
    super.key,
    required this.start,
    required this.end,
    this.startLabel = 'Today',
    this.endLabel = 'Day 30',
  });

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: p.border.withValues(alpha: 0.6), width: 0.5),
        boxShadow: AppShadows.premium,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 150,
            width: double.infinity,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: 1100.ms,
              curve: Curves.easeOutCubic,
              builder: (context, t, _) => CustomPaint(
                painter: _ProjectionPainter(
                  start: start,
                  end: end,
                  t: t,
                  line: p.accent,
                  fill: p.accent.withValues(alpha: 0.16),
                  dot: p.accent,
                  goalText: '${(end * 100).round()}%',
                  goalColor: p.accent,
                  textColor: p.text,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(startLabel,
                  style: AppTypography.bodySmall.copyWith(color: p.sub)),
              Text(endLabel,
                  style: AppTypography.bodySmall.copyWith(color: p.sub)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProjectionPainter extends CustomPainter {
  final double start;
  final double end;
  final double t; // animation 0..1
  final Color line;
  final Color fill;
  final Color dot;
  final String goalText;
  final Color goalColor;
  final Color textColor;
  _ProjectionPainter({
    required this.start,
    required this.end,
    required this.t,
    required this.line,
    required this.fill,
    required this.dot,
    required this.goalText,
    required this.goalColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 8.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;
    double y(double v) => pad + h * (1 - v);
    double x(double f) => pad + w * f;

    // Smooth eased rising curve.
    final path = Path()..moveTo(x(0), y(start));
    final pts = <Offset>[];
    const steps = 40;
    for (var i = 0; i <= steps; i++) {
      final f = (i / steps) * t;
      final ease = Curves.easeInOutCubic.transform(f);
      final v = start + (end - start) * ease;
      final off = Offset(x(f), y(v));
      pts.add(off);
      path.lineTo(off.dx, off.dy);
    }

    // Fill under curve.
    final fillPath = Path.from(path)
      ..lineTo(pts.last.dx, y(0))
      ..lineTo(x(0), y(0))
      ..close();
    canvas.drawPath(fillPath, Paint()..color = fill);

    // Line.
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // End dot.
    final endPt = pts.last;
    canvas.drawCircle(endPt, 7, Paint()..color = dot);
    canvas.drawCircle(
        endPt, 7, Paint()..color = Colors.white.withValues(alpha: 0.9)..style = PaintingStyle.stroke..strokeWidth = 2);

    // Goal label near end dot.
    if (t > 0.85) {
      final tp = TextPainter(
        text: TextSpan(
          text: goalText,
          style: TextStyle(
            color: goalColor,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(endPt.dx - tp.width - 4, endPt.dy - 24));
    }
  }

  @override
  bool shouldRepaint(_ProjectionPainter old) => old.t != t;
}

// ════════════════════════════════════════════════════════════════════════
// FEATURE GRID — 2x2 "how it works" tiles.
// ════════════════════════════════════════════════════════════════════════
class ObFeatureGrid extends StatelessWidget {
  final List<({IconData icon, String title, String sub})> items;
  const ObFeatureGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.98,
      children: items
          .map(
            (it) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(AppRadius.l),
                border: Border.all(color: p.border.withValues(alpha: 0.6), width: 0.5),
                boxShadow: AppShadows.soft,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          p.accent.withValues(alpha: 0.16),
                          p.electric.withValues(alpha: 0.10),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(it.icon, color: p.accent, size: 22),
                  ),
                  const Spacer(),
                  Text(
                    it.title,
                    style: AppTypography.titleMedium
                        .copyWith(color: p.text, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    it.sub,
                    style: AppTypography.bodySmall.copyWith(color: p.sub),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// COMMIT ORB — tap & hold the mascot to "commit" (fills a ring), then done.
// ════════════════════════════════════════════════════════════════════════
class ObCommitOrb extends StatefulWidget {
  final VoidCallback onComplete;
  const ObCommitOrb({super.key, required this.onComplete});

  @override
  State<ObCommitOrb> createState() => _ObCommitOrbState();
}

class _ObCommitOrbState extends State<ObCommitOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed && !_done) {
          _done = true;
          HapticEngine.heavyMilestone();
          widget.onComplete();
        }
      });
    _ctrl.addListener(_hapticTick);
  }

  int _lastTick = 0;
  void _hapticTick() {
    final tick = (_ctrl.value * 6).floor();
    if (tick != _lastTick) {
      _lastTick = tick;
      HapticEngine.light();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _down(TapDownDetails _) {
    if (_done) return;
    _ctrl.forward();
  }

  void _up([TapUpDetails? _]) {
    if (_done) return;
    if (_ctrl.status != AnimationStatus.completed) _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final p = ObPalette.of(context);
    return Semantics(
      button: true,
      label: 'Hold to commit to your health goal',
      child: GestureDetector(
        onTapDown: _down,
        onTapUp: _up,
        onTapCancel: _up,
        child: SizedBox(
        width: 220,
        height: 220,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CustomPaint(
                    painter: _RingPainter(
                      progress: _ctrl.value,
                      track: p.border,
                      color: p.accent,
                    ),
                  ),
                ),
                Transform.scale(
                  scale: 1 + _ctrl.value * 0.06,
                  child: child,
                ),
              ],
            );
          },
          child: const MedAiMascot(size: 124, semanticLabel: 'Hold to commit'),
        ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color track;
  final Color color;
  _RingPainter({
    required this.progress,
    required this.track,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 5;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ════════════════════════════════════════════════════════════════════════
// PLAN LOADER — animated checklist that builds the user's plan, then onDone.
// ════════════════════════════════════════════════════════════════════════
class ObPlanLoader extends StatefulWidget {
  final List<String> steps;
  final VoidCallback onDone;
  const ObPlanLoader({super.key, required this.steps, required this.onDone});

  @override
  State<ObPlanLoader> createState() => _ObPlanLoaderState();
}

class _ObPlanLoaderState extends State<ObPlanLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 900 * widget.steps.length + 600),
    )..forward();
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed && !_fired) {
        _fired = true;
        HapticEngine.success();
        widget.onDone();
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
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final pct = (_ctrl.value * 100).clamp(0, 100).round();
        final each = 1 / widget.steps.length;
        return Column(
          children: [
            Text(
              '$pct%',
              style: AppTypography.displayMedium.copyWith(
                color: p.accent,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: _ctrl.value,
                minHeight: 8,
                backgroundColor: p.border,
                valueColor: AlwaysStoppedAnimation(p.accent),
              ),
            ),
            const SizedBox(height: 24),
            ...List.generate(widget.steps.length, (i) {
              final done = _ctrl.value >= (i + 1) * each;
              final active = !done && _ctrl.value >= i * each;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: AppDurations.fast,
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done ? p.good : Colors.transparent,
                        border: Border.all(
                          color: done ? p.good : p.border,
                          width: 2,
                        ),
                      ),
                      child: done
                          ? const Icon(Icons.check_rounded,
                              size: 16, color: Colors.white)
                          : (active
                              ? Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation(p.accent),
                                  ),
                                )
                              : null),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.steps[i],
                        style: AppTypography.titleMedium.copyWith(
                          color: done || active ? p.text : p.sub,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
