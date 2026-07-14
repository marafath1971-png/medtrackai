import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/premium_texture.dart';

/// Today's dose progress hero — single accent (sage), streak optional (header owns it).
class LimeProgressHero extends StatefulWidget {
  final double fraction;
  final int taken;
  final int total;
  final int streak;
  final bool showStreak;
  final VoidCallback? onTap;

  const LimeProgressHero({
    super.key,
    required this.fraction,
    required this.taken,
    required this.total,
    this.streak = 0,
    this.showStreak = false,
    this.onTap,
  });

  @override
  State<LimeProgressHero> createState() => _LimeProgressHeroState();
}

class _LimeProgressHeroState extends State<LimeProgressHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late Animation<double> _a;

  double get _target =>
      widget.fraction.isNaN ? 0.0 : widget.fraction.clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _a = Tween<double>(begin: 0, end: _target)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      MedAiA11y.reducedMotion(context) ? _c.value = 1.0 : _c.forward();
    });
  }

  @override
  void didUpdateWidget(covariant LimeProgressHero old) {
    super.didUpdateWidget(old);
    if (old.fraction != widget.fraction) {
      _a = Tween<double>(begin: _a.value, end: _target)
          .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
      MedAiA11y.reducedMotion(context) ? _c.value = 1.0 : _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onAccent = AppColors.limeInk;
    final allDone = widget.total > 0 && widget.taken >= widget.total;
    final title = allDone
        ? "You're all caught up"
        : widget.total == 0
            ? 'Nothing due today'
            : 'Your progress\ntoday';

    return Semantics(
      button: widget.onTap != null,
      label:
          '${widget.taken} of ${widget.total} doses taken today${widget.showStreak ? ', ${widget.streak} day streak' : ''}',
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 18, 22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFC2EF7D), Color(0xFFA9E65F)],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.limeDeep.withValues(alpha: 0.45),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned.fill(child: PremiumHeroSheen()),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Text('⚡',
                                style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(
                              'DAILY DOSES',
                              style: AppTypography.labelSmall.copyWith(
                                color: onAccent.withValues(alpha: 0.85),
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w800,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: AppTypography.headlineSmall.copyWith(
                            color: onAccent,
                            fontWeight: FontWeight.w800,
                            height: 1.12,
                            letterSpacing: -0.5,
                            fontSize: 22,
                          ),
                        ),
                        if (widget.showStreak) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 11, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '🔥 ${widget.streak} day streak',
                              style: AppTypography.labelMedium.copyWith(
                                color: onAccent,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedBuilder(
                    animation: _a,
                    builder: (context, _) {
                      return SizedBox(
                        width: 96,
                        height: 96,
                        child: CustomPaint(
                          painter: _BadgePainter(
                            _a.value.clamp(0.0, 1.0),
                            trackColor: onAccent.withValues(alpha: 0.2),
                            progressColor: onAccent,
                            fillColor: Colors.white.withValues(alpha: 0.9),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  allDone
                                      ? '✓'
                                      : '${widget.taken}/${widget.total}',
                                  style: AppTypography.titleLarge.copyWith(
                                    color: onAccent,
                                    fontWeight: FontWeight.w800,
                                    fontSize: allDone ? 30 : 22,
                                  ),
                                ),
                                if (!allDone)
                                  Text(
                                    'DOSES',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: onAccent.withValues(alpha: 0.6),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgePainter extends CustomPainter {
  final double fraction;
  final Color trackColor;
  final Color progressColor;
  final Color fillColor;

  _BadgePainter(
    this.fraction, {
    required this.trackColor,
    required this.progressColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    canvas.drawCircle(center, radius - 3, Paint()..color = fillColor);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );

    if (fraction > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * fraction,
        false,
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BadgePainter old) =>
      old.fraction != fraction ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor;
}
