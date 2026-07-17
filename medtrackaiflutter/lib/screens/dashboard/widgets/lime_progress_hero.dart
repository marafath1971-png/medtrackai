import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';
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
        ? HopeVibe.progressDone
        : widget.total == 0
            ? HopeVibe.progressEmpty
            : HopeVibe.progressToday;

    return Semantics(
      button: widget.onTap != null,
      label:
          '${widget.taken} of ${widget.total} doses taken today${widget.showStreak ? ', ${widget.streak} day streak' : ''}',
      child: AnimatedPressable(
        onTap: widget.onTap,
        disabled: widget.onTap == null,
        scaleFactor: 0.98,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.p20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.lime, AppColors.limeDeep],
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
                            Icon(Icons.bolt_rounded,
                                size: 14, color: onAccent.withValues(alpha: 0.85)),
                            const SizedBox(width: AppSpacing.p4),
                            Text(
                              HopeVibe.dailyDosesTag,
                              style: AppTypography.caption.copyWith(
                                color: onAccent.withValues(alpha: 0.85),
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.p8),
                        Text(
                          title,
                          style: AppTypography.headlineSmall.copyWith(
                            color: onAccent,
                            fontWeight: FontWeight.w800,
                            height: 1.12,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (widget.showStreak) ...[
                          const SizedBox(height: AppSpacing.p16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.p12, vertical: AppSpacing.p4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              HopeVibe.streakChip(widget.streak),
                              style: AppTypography.bodySmall.copyWith(
                                color: onAccent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.p12),
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
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  allDone
                                      ? '✓'
                                      : '${widget.taken}/${widget.total}',
                                  style: (allDone
                                          ? AppTypography.headlineLarge
                                          : AppTypography.headlineSmall)
                                      .copyWith(
                                    color: onAccent,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (!allDone)
                                  Text(
                                    'DOSES',
                                    style: AppTypography.caption.copyWith(
                                      color: onAccent.withValues(alpha: 0.6),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                              ],
                            ),
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
