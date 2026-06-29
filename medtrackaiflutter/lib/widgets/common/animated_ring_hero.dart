import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import 'med_ai_mascot.dart';

// ─────────────────────────────────────────────────────────────
// CAL AI RING HERO — premium circular progress hero
// ─────────────────────────────────────────────────────────────
class CalAiRingHero extends StatelessWidget {
  final int takenCount;
  final int total;
  final double dosePct;
  final int streak;
  final int remaining;

  /// When false, the inline 🔥 streak badge is hidden (e.g. on Home, where the
  /// header already shows the streak). Defaults to true for other surfaces.
  final bool showStreakBadge;

  /// Optional primary "take next dose" action rendered below the status pill.
  /// When [onTakeNext] is null, no action row is shown.
  final String? nextDoseName;
  final String? nextDoseTime;
  final VoidCallback? onTakeNext;
  final VoidCallback? onSnoozeNext;

  const CalAiRingHero({
    super.key,
    required this.takenCount,
    required this.total,
    required this.dosePct,
    required this.streak,
    required this.remaining,
    this.showStreakBadge = true,
    this.nextDoseName,
    this.nextDoseTime,
    this.onTakeNext,
    this.onSnoozeNext,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final isDark = context.isDark;
    final isAllDone = total > 0 && dosePct >= 1.0;
    final isEmpty = total == 0;

    // Ring: sage progress on cream (light) · electric glow (dark)
    final ringColors = isAllDone
        ? [L.green, const Color(0xFF00E676)]
        : isDark
            ? [L.accent, Color.lerp(L.accent, Colors.teal, 0.355)!]
            : [L.accent, AppColors.eatoNavy];

    final statusText = isEmpty
        ? 'Add a medicine to get started'
        : isAllDone
            ? '🎉 All doses complete'
            : '$remaining dose${remaining == 1 ? '' : 's'} remaining';

    // Adaptive streak badge styling (glow in dark mode, crisp in light mode)
    final streakBg = isDark
        ? const Color(0xFFFF9F0A).withValues(alpha: 0.08)
        : const Color(0xFFFFF3E0);
    final streakBorder = isDark
        ? const Color(0xFFFF9F0A).withValues(alpha: 0.25)
        : const Color(0xFFFFCC80).withValues(alpha: 0.6);
    final streakTextColor = isDark
        ? const Color(0xFFFF9F0A)
        : const Color(0xFFE65100);

    final trackColor = isDark
        ? L.accent.withValues(alpha: 0.08)
        : L.accent.withValues(alpha: 0.05);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? L.border.withValues(alpha: 0.35)
              : AppColors.eatoGold.withValues(alpha: 0.12),
          width: isDark ? 0.5 : 1,
        ),
        boxShadow: isDark
            ? AppShadows.premium
            : [
                BoxShadow(
                  color: AppColors.eatoNavy.withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Header row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: title + subtitle
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAllDone ? 'All done' : 'Today',
                    style: AppTypography.headlineSmall.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAllDone
                        ? 'Perfect adherence today'
                        : '$takenCount of $total doses taken',
                    style: AppTypography.bodySmall.copyWith(
                      color: L.sub,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              // Right: 🔥 Streak badge or branded assistant on Home
              if (showStreakBadge)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: streakBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: streakBorder,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 16))
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scaleXY(
                              begin: 0.92,
                              end: 1.08,
                              duration: 900.ms,
                              curve: Curves.easeInOutSine),
                      const SizedBox(width: 5),
                      Text(
                        '$streak',
                        style: AppTypography.titleMedium.copyWith(
                          color: streakTextColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'day${streak == 1 ? '' : 's'}',
                        style: AppTypography.bodySmall.copyWith(
                          color: streakTextColor.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: L.fill.withValues(alpha: 0.28),
                    border: Border.all(
                      color: L.border.withValues(alpha: 0.18),
                      width: 0.8,
                    ),
                  ),
                  child: const MedAiMascot(
                    size: 54,
                    semanticLabel: 'Med AI assistant',
                  ),
                ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Ring ──
          Semantics(
            label: isEmpty
                ? 'No medications scheduled'
                : '$takenCount of $total doses taken, ${(dosePct * 100).round()} percent complete',
            child: ExcludeSemantics(
              child: AnimatedRing(
            percent: dosePct,
            colors: ringColors,
            trackColor: trackColor,
            size: 200,
            strokeWidth: 14,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: dosePct * 100),
                  duration: const Duration(milliseconds: 1600),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return Text(
                      '${value.round()}%',
                      style: AppTypography.displayXL.copyWith(
                        color: L.text,
                        height: 1.0,
                        fontWeight: FontWeight.w800,
                        fontSize: 48,
                        letterSpacing: -2,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  isEmpty ? 'No meds' : '$takenCount / $total',
                  style: AppTypography.labelMedium.copyWith(
                    color: L.sub.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ── Status pill ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isAllDone
                  ? L.green.withValues(alpha: 0.10)
                  : L.fill.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isAllDone
                    ? L.green.withValues(alpha: 0.18)
                    : L.border.withValues(alpha: 0.5),
                width: 0.8,
              ),
            ),
            child: Text(
              statusText,
              style: AppTypography.bodySmall.copyWith(
                color: isAllDone ? L.green : L.sub.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),

          // ── Primary next-dose action ──
          if (onTakeNext != null) ...[
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _TakeNextButton(
                    label: nextDoseName == null
                        ? 'Take next dose'
                        : 'Take $nextDoseName',
                    time: nextDoseTime,
                    colors: ringColors,
                    onTap: onTakeNext!,
                  ),
                ),
                if (onSnoozeNext != null) ...[
                  const SizedBox(width: 10),
                  _SnoozeNextButton(onTap: onSnoozeNext!),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PRIMARY "TAKE NEXT DOSE" ACTION (accessible, 52dp target)
// ─────────────────────────────────────────────────────────────
class _TakeNextButton extends StatelessWidget {
  final String label;
  final String? time;
  final List<Color> colors;
  final VoidCallback onTap;

  const _TakeNextButton({
    required this.label,
    required this.time,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final isDark = context.isDark;
    final btnColor = isDark
        ? Color.lerp(L.text, L.accent, 0.25)!
        : AppColors.eatoNavy;
    return Semantics(
      button: true,
      label: time == null ? label : '$label, due $time',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(99),
          child: Ink(
            decoration: BoxDecoration(
              color: btnColor,
              borderRadius: BorderRadius.circular(99),
              boxShadow: isDark
                  ? AppShadows.glow(L.accent, intensity: 0.2)
                  : [
                      BoxShadow(
                        color: AppColors.eatoNavy.withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (time != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      time!,
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SnoozeNextButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SnoozeNextButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Semantics(
      button: true,
      label: 'Snooze next dose 30 minutes',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            constraints: const BoxConstraints(minHeight: 52, minWidth: 52),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: L.fill.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: L.border.withValues(alpha: 0.5),
                width: 0.8,
              ),
            ),
            child: Icon(Icons.snooze_rounded, color: L.sub, size: 22),
          ),
        ),
      ),
    );
  }
}

class AnimatedRing extends StatefulWidget {
  final double percent;
  final List<Color> colors;
  final Color trackColor;
  final double size;
  final double strokeWidth;
  final Widget child;

  const AnimatedRing({
    super.key,
    required this.percent,
    required this.colors,
    required this.trackColor,
    required this.size,
    required this.strokeWidth,
    required this.child,
  });

  @override
  State<AnimatedRing> createState() => _AnimatedRingState();
}

class _AnimatedRingState extends State<AnimatedRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));
    _anim = Tween<double>(begin: 0, end: widget.percent)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(AnimatedRing old) {
    super.didUpdateWidget(old);
    if (old.percent != widget.percent) {
      _anim = Tween<double>(begin: _anim.value, end: widget.percent)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _RingPainter(
              percent: _anim.value,
              colors: widget.colors,
              trackColor: widget.trackColor,
              strokeWidth: widget.strokeWidth,
            ),
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double percent;
  final List<Color> colors;
  final Color trackColor;
  final double strokeWidth;

  const _RingPainter({
    required this.percent,
    required this.colors,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -1.5707963267948966;
    final sweepAngle = 6.283185307179586 * percent;

    // Background track — soft, barely visible
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      6.283185307179586,
      false,
      Paint()
        ..color = trackColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (percent > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final validColors = colors.length >= 2 ? colors : [colors.first, colors.first];

      final gradient = SweepGradient(
        colors: validColors,
        startAngle: 0.0,
        endAngle: sweepAngle,
        tileMode: TileMode.decal,
        transform: GradientRotation(startAngle),
      );

      // Clean crisp arc — no shadow/glow
      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..shader = gradient.createShader(rect)
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.percent != percent || old.colors != colors;
}
