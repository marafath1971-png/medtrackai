import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/color_utils.dart';
import '../../domain/entities/medicine.dart';
import '../common/app_shimmer.dart';
export '../common/app_shimmer.dart';

// ══════════════════════════════════════════════
// RING CHART (CustomPainter — matches JSX Ring component)
// ══════════════════════════════════════════════

class RingChart extends StatelessWidget {
  final double percent; // 0.0 – 1.0
  final double size;
  final double strokeWidth;
  final Color color;
  final String label;
  final String sub;

  const RingChart({
    super.key,
    required this.percent,
    this.size = 100,
    this.strokeWidth = 6, // Refined thinner stroke
    required this.color,
    required this.label,
    this.sub = '',
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        CustomPaint(
          size: Size(size, size),
          painter: _RingPainter(
              percent: percent.clamp(0, 1),
              color: color,
              bg: Colors.black.withValues(alpha: 0.05),
              strokeWidth: strokeWidth),
        ),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: AppTypography.displaySmall.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: size * 0.22,
                  color: L.text,
                  letterSpacing: -1.0,
                  height: 1.0)),
          if (sub.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(sub.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                      fontSize: size * 0.08,
                      color: L.sub,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center),
            ),
        ]),
      ]),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double percent;
  final Color color;
  final Color bg;
  final double strokeWidth;
  const _RingPainter(
      {required this.percent,
      required this.color,
      required this.bg,
      required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -1.5708; // -π/2

    final bgPaint = Paint()
      ..color = bg
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Background
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * 3.14159,
      false,
      bgPaint,
    );

    // Foreground
    if (percent > 0) {
      final fgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * 3.14159 * percent,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter o) =>
      o.percent != percent || o.color != color;
}

class AppToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const AppToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return GestureDetector(
      onTap: () {
        if (!value) {
          HapticEngine.success();
        } else {
          HapticEngine.lightTap();
        }
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: AppCurves.spring,
        width: 52,
        height: 30,
        decoration: BoxDecoration(
          color: value ? L.text : L.fill.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Stack(children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 400),
            curve: AppCurves.spring,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: value ? 0.2 : 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// GLASS CARD (iOS 26 Frosted Glass)
// ══════════════════════════════════════════════

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool showBorder;
  final Color? tintColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.borderRadius,
    this.showBorder = true,
    this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final r = borderRadius ?? AppRadius.roundXL;

    return ClipPath(
      clipper: ShapeBorderClipper(
        shape: ContinuousRectangleBorder(borderRadius: r),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(20),
          decoration: ShapeDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (tintColor ?? Colors.white).withValues(alpha: 0.14),
                (tintColor ?? Colors.white).withValues(alpha: 0.04),
              ],
            ),
            shape: ContinuousRectangleBorder(
              borderRadius: r,
              side: showBorder
                  ? BorderSide(
                      color: L.glassBorder.withValues(alpha: 0.12),
                      width: 0.5,
                    )
                  : BorderSide.none,
            ),
            shadows: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 48,
                offset: const Offset(0, 24),
                spreadRadius: -12,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.35),
                blurRadius: 1,
                offset: const Offset(0, -0.5),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// BOUNCING BUTTON (iOS 26 Spring Interaction)
// ══════════════════════════════════════════════

class BouncingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final bool hapticEnabled;
  final Duration duration;

  const BouncingButton({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.92,
    this.hapticEnabled = true,
    this.duration = const Duration(milliseconds: 350), // hero duration
  });

  @override
  State<BouncingButton> createState() => _BouncingButtonState();
}

class _BouncingButtonState extends State<BouncingButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        if (widget.hapticEnabled) HapticEngine.lightTap();
      },
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleFactor : 1.0,
        duration: widget.duration,
        curve: AppCurves.spring,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          alignment: Alignment.center,
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: _isPressed ? 0.05 : 0),
              BlendMode.srcATop,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// SQUIRCLE CARD (iOS 26 High-Fidelity)
// ══════════════════════════════════════════════

class SquircleCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final List<BoxShadow>? boxShadow;
  final bool showBorder;
  final double? borderRadius;
  final double? radius;
  final double? borderWidth;

  const SquircleCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.boxShadow,
    this.showBorder = true,
    this.borderRadius,
    this.radius,
    this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = radius ?? borderRadius ?? AppRadius.xl;
    final bw = borderWidth ?? 0.5;

    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (color ?? L.card).withValues(alpha: isDark ? 0.95 : 1.0),
            (color ?? L.card).withValues(alpha: isDark ? 0.88 : 0.97),
          ],
        ),
        borderRadius: BorderRadius.circular(r),
        border: showBorder
            ? Border.all(
                color: L.border.withValues(alpha: isDark ? 0.12 : 0.07),
                width: bw,
              )
            : null,
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
                blurRadius: 40,
                offset: const Offset(0, 16),
                spreadRadius: -8,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
      ),
      child: child,
    );
  }
}

// ══════════════════════════════════════════════
// BADGE (pill chip)
// ══════════════════════════════════════════════

class AppBadge extends StatelessWidget {
  final String text;
  final Color bg;
  final Color textColor;

  const AppBadge(
      {super.key,
      required this.text,
      required this.bg,
      required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(text,
          style: AppTypography.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: textColor,
          )),
    );
  }
}

// ══════════════════════════════════════════════
// TOAST (pill-style)
// ══════════════════════════════════════════════

class AppToast extends StatelessWidget {
  final String message;
  final String type; // success, error, warning, info

  const AppToast({super.key, required this.message, this.type = 'success'});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final String emoji;

    switch (type) {
      case 'error':
        emoji = '🚨';
        break;
      case 'warning':
        emoji = '⚠️';
        break;
      case 'info':
        emoji = 'ℹ️';
        break;
      default:
        emoji = '✅';
    }

    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Positioned(
      bottom: bottomPadding + 120,
      left: 24,
      right: 24,
      child: Center(
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: BorderRadius.circular(24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  message,
                  style: AppTypography.bodyMedium.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 400.ms)
          .slideY(begin: 0.5, end: 0, curve: Curves.easeOutQuart)
          .shimmer(
              delay: 600.ms,
              duration: 1200.ms,
              color: Colors.white.withValues(alpha: 0.1)),
    );
  }
}

class SyncStatusBanner extends StatelessWidget {
  final bool isSyncing;
  final DateTime? lastSynced;
  const SyncStatusBanner({super.key, required this.isSyncing, this.lastSynced});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    if (!isSyncing && lastSynced == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: L.bg.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: L.border.withValues(alpha: 0.1), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isSyncing ? L.warning : L.success,
              shape: BoxShape.circle,
            ),
          )
              .animate(
                  onPlay: isSyncing ? (c) => c.repeat(reverse: true) : null)
              .fade(duration: 500.ms),
          const SizedBox(width: 8),
          Text(
            isSyncing ? 'SYNCING_CLOUD' : 'CLOUD_STABLE',
            style: AppTypography.labelSmall.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: L.sub.withValues(alpha: 0.5),
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// SKELETON SHIMMER LOADER
// ══════════════════════════════════════════════

class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const SkeletonBox({super.key, required this.width, required this.height, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(width: width, height: height, radius: radius);
  }
}

// ══════════════════════════════════════════════
// SETTINGS ROW (label + right content)
// ══════════════════════════════════════════════

class SettingsRow extends StatelessWidget {
  final Widget leading;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsRow(
      {super.key,
      required this.leading,
      required this.label,
      this.subtitle,
      this.trailing,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide.none),
        ),
        child: Row(children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                Text(label,
                    style: AppTypography.titleMedium.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w600,
                    )),
                if (subtitle != null)
                  Text(subtitle!,
                      style: AppTypography.labelSmall.copyWith(
                        color: L.sub,
                      )),
              ])),
          if (trailing != null) trailing!,
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// SECTION LABEL (uppercase small - like Lbl in JSX)
// ══════════════════════════════════════════════

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.08 * 11,
          color: context.L.sub,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// INFO ROW (IRow in JSX)
// ══════════════════════════════════════════════

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isWarning;
  const InfoRow(
      {super.key,
      required this.label,
      required this.value,
      this.isWarning = false});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label,
          style: AppTypography.bodySmall.copyWith(
            color: L.sub,
          )),
      Flexible(
          child: Text(value,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: isWarning ? L.red : L.text,
              ),
              textAlign: TextAlign.right)),
    ]);
  }
}

// ══════════════════════════════════════════════
// LIGHT INPUT FIELD (matches LightInp in JSX)
// ══════════════════════════════════════════════

class LightInput extends StatelessWidget {
  final String label;
  final String? placeholder;
  final String value;
  final ValueChanged<String> onChanged;
  final TextInputType keyboardType;
  final int maxLines;

  const LightInput({
    super.key,
    required this.label,
    this.placeholder,
    required this.value,
    required this.onChanged,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.08 * 10,
            color: L.sub,
          )),
      const SizedBox(height: 5),
      TextFormField(
        initialValue: value,
        onChanged: onChanged,
        keyboardType: keyboardType,
        maxLines: maxLines,
        cursorColor: L.text,
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w500,
          color: L.text,
        ),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: L.sub,
          ),
          filled: true,
          fillColor: L.bg,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(
                  color: L.border.withValues(alpha: 0.1), width: 0.5)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(
                  color: L.border.withValues(alpha: 0.1), width: 0.5)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide:
                  BorderSide(color: L.text.withValues(alpha: 0.2), width: 0.5)),
        ),
      ),
    ]);
  }
}
// ══════════════════════════════════════════════
// COLOR SWATCH CIRCLE
// ══════════════════════════════════════════════

// ══════════════════════════════════════════════
// MED IMAGE (Intelligent Image Loader)
// ══════════════════════════════════════════════

class MedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double? borderRadius;
  final Widget? placeholder;

  const MedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    Widget image;
    if (imageUrl == null || imageUrl!.isEmpty) {
      image = placeholder ??
          Container(
            color: L.fill,
            child: Icon(Icons.medication_rounded,
                color: L.sub, size: width != null ? width! * 0.4 : 24),
          );
    } else if (imageUrl!.startsWith('http')) {
      image = Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            placeholder ??
            Container(
              color: L.fill,
              child: Icon(Icons.broken_image_rounded, color: L.sub),
            ),
      );
    } else {
      if (imageUrl!.startsWith('assets/')) {
        image = Image.asset(
          imageUrl!,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              placeholder ??
              Container(
                color: L.fill,
                child: Icon(Icons.broken_image_rounded, color: L.sub),
              ),
        );
      } else {
        image = Image.file(
          File(imageUrl!),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              placeholder ??
              Container(
                color: L.fill,
                child: Icon(Icons.broken_image_rounded, color: L.sub),
              ),
        );
      }
    }

    final radius = borderRadius ?? AppRadius.squircle;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: image,
    );
  }
}

// ══════════════════════════════════════════════
// DOSE CARD (iOS 26 High-Fidelity)
// ══════════════════════════════════════════════


class DoseCard extends StatefulWidget {
  final Medicine med;
  final ScheduleEntry sched;
  final bool taken;
  final bool overdue;
  final bool isNext;
  final VoidCallback onTake;
  final VoidCallback onSnooze;
  final VoidCallback onTap;

  const DoseCard({
    super.key,
    required this.med,
    required this.sched,
    required this.taken,
    required this.overdue,
    required this.isNext,
    required this.onTake,
    required this.onSnooze,
    required this.onTap,
  });

  @override
  State<DoseCard> createState() => _DoseCardState();
}

class _DoseCardState extends State<DoseCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  bool _showBurst = false;
  late AnimationController _burstCtrl;

  @override
  void initState() {
    super.initState();
    _burstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (mounted) setState(() => _showBurst = false);
        }
      });
  }

  @override
  void dispose() {
    _burstCtrl.dispose();
    super.dispose();
  }

  void _triggerDopamineBurst() {
    if (widget.taken) return;
    HapticEngine.doseTaken();
    setState(() => _showBurst = true);
    _burstCtrl.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 250), widget.onTake);
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final medColor = hexToColor(widget.med.color);
    final isDone = widget.taken;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Dismissible(
          key: ValueKey('dose_${widget.sched.id}_${widget.taken}'),
          direction:
              isDone ? DismissDirection.none : DismissDirection.startToEnd,
          confirmDismiss: (dir) async {
            if (dir == DismissDirection.startToEnd) {
              _triggerDopamineBurst();
            }
            return false;
          },
          background: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              // Cal AI: orange swipe background
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.check_rounded, color: AppColors.accent, size: 22),
                const SizedBox(width: 12),
                Text('Mark as taken',
                    style: AppTypography.labelMedium.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        fontSize: 14)),
              ],
            ),
          ),
          child: GestureDetector(
            onTapDown: (_) {
              setState(() => _pressed = true);
              HapticEngine.selection();
            },
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: widget.onTap,
            child: AnimatedScale(
              scale: _pressed ? 0.97 : 1.0,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOutCubic,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDone ? L.card.withValues(alpha: 0.4) : L.card.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDone
                            ? L.border.withValues(alpha: 0.1)
                            : (widget.isNext ? L.accent.withValues(alpha: 0.25) : L.border.withValues(alpha: 0.18)),
                        width: 1.0,
                      ),
                      boxShadow: isDone
                          ? null
                          : [
                              BoxShadow(
                                color: (widget.overdue
                                        ? L.error
                                        : (widget.isNext ? L.accent : medColor))
                                    .withValues(alpha: 0.05),
                                blurRadius: 16,
                                spreadRadius: -2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDone
                                  ? medColor.withValues(alpha: 0.15)
                                  : medColor.withValues(alpha: 0.35),
                              width: 1.2,
                            ),
                            boxShadow: isDone ? null : [
                              BoxShadow(
                                color: medColor.withValues(alpha: 0.1),
                                blurRadius: 6,
                                spreadRadius: 0.5,
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDone
                                  ? medColor.withValues(alpha: 0.05)
                                  : medColor.withValues(alpha: 0.08),
                            ),
                            child: Center(
                              child: isDone
                                  ? Icon(Icons.check_circle_rounded,
                                      size: 16, color: medColor)
                                  : MedImage(
                                      imageUrl: widget.med.imageUrl,
                                      borderRadius: 100,
                                      placeholder: Icon(Icons.medication_rounded,
                                          size: 16,
                                          color: medColor.withValues(alpha: 0.8)),
                                    ),
                            ),
                          ),
                        )
                            .animate(target: isDone ? 1 : 0)
                            .scale(
                                begin: const Offset(1.0, 1.0),
                                end: const Offset(1.15, 1.15),
                                duration: 200.ms,
                                curve: Curves.elasticOut)
                            .then()
                            .scale(
                                begin: const Offset(1.15, 1.15),
                                end: const Offset(1.0, 1.0),
                                duration: 200.ms),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.med.name,
                            style: AppTypography.labelLarge.copyWith(
                              color: isDone
                                  ? L.text.withValues(alpha: 0.3)
                                  : L.text,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              letterSpacing: -0.3,
                              decoration:
                                  isDone ? TextDecoration.lineThrough : null,
                              decorationColor: L.text.withValues(alpha: 0.2),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                fmtTime(widget.sched.h, widget.sched.m,
                                    context),
                                style: AppTypography.labelSmall.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDone
                                      ? L.sub.withValues(alpha: 0.25)
                                      : widget.overdue
                                          ? L.error.withValues(alpha: 0.8)
                                          : L.sub.withValues(alpha: 0.55),
                                ),
                              ),
                              if (widget.med.dose.isNotEmpty) ...[
                                Text(' · ',
                                    style: AppTypography.labelSmall.copyWith(
                                        color: L.sub.withValues(alpha: 0.25),
                                        fontSize: 12)),
                                Text(widget.med.dose,
                                    style: AppTypography.labelSmall.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: L.sub.withValues(alpha: 0.4))),
                              ],
                              if (widget.isNext && !isDone) ...[
                                const SizedBox(width: 8),
                                Text('· swipe →',
                                    style: AppTypography.labelSmall.copyWith(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: L.accent.withValues(alpha: 0.7)))
                                    .animate(onPlay: (c) => c.repeat(reverse: true))
                                    .fade(begin: 0.4, end: 1.0, duration: 900.ms),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildCta(L, medColor),
                  ],
                ),
              ),
        ),
      ),
    ),
  ),
),
        if (_showBurst)
          Positioned.fill(
            child: IgnorePointer(
              child: _DopamineBurstOverlay(controller: _burstCtrl, medColor: medColor),
            ),
          ),
      ],
    );
  }

  Widget _buildCta(AppThemeColors L, Color medColor) {
    if (widget.taken) {
      // Cal AI: simple green check
      return const SizedBox.shrink();
    }
    if (widget.overdue) {
      return GestureDetector(
        onTap: () {
          HapticEngine.medium();
          widget.onTake();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: L.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: L.error.withValues(alpha: 0.25), width: 0.8),
          ),
          child: Text('LATE',
              style: AppTypography.labelSmall.copyWith(
                  color: L.error,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 0.5)),
        ),
      );
    }
    if (widget.isNext) {
      return GestureDetector(
        onTap: () {
          HapticEngine.selection();
          _triggerDopamineBurst();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            // Cal AI: orange accent for next-dose CTA
            color: L.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: L.accent.withValues(alpha: 0.3), width: 0.8),
          ),
          child: Text('Log',
              style: AppTypography.labelMedium.copyWith(
                  color: L.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0)),
        ),
      );
    }
    return GestureDetector(
      onTap: () {
        HapticEngine.light();
        widget.onTake();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: L.fill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: L.border, width: 0.8),
        ),
        child: Icon(Icons.add_rounded,
            size: 18, color: L.text.withValues(alpha: 0.5)),
      ),
    );
  }
}

// ── Dopamine Burst Particle System ───────────────
class _DopamineBurstOverlay extends StatelessWidget {
  final AnimationController controller;
  final Color medColor;
  const _DopamineBurstOverlay({required this.controller, required this.medColor});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Glowing Shockwave Ring
            Opacity(
              opacity: (1.0 - controller.value).clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 1.0 + controller.value * 3.0,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: medColor, width: 4 * (1.0 - controller.value)),
                    boxShadow: AppShadows.glow(medColor, intensity: 0.5),
                  ),
                ),
              ),
            ),
            // Central giant glow burst
            Opacity(
              opacity: (1.0 - controller.value).clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 0.5 + controller.value * 1.5,
                child: Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: medColor,
                    boxShadow: AppShadows.glow(medColor, intensity: 1.0),
                  ),
                ),
              ),
            ),
            // Orbiting liquid drops
            ..._buildParticles(),
          ],
        );
      },
    );
  }

  List<Widget> _buildParticles() {
    const offsets = [
      Offset(-80, -100),
      Offset(80, -100),
      Offset(-120, 20),
      Offset(120, 20),
      Offset(0, -140),
      Offset(-60, 80),
      Offset(60, 80),
    ];
    return List.generate(
      offsets.length,
      (i) => Positioned.fill(
        child: Align(
          alignment: Alignment.center,
          child: Transform.translate(
            offset: offsets[i] * controller.value,
            child: Opacity(
              opacity: (1.0 - controller.value * 1.4).clamp(0.0, 1.0),
              child: Transform.scale(
                scale: (0.5 + controller.value).clamp(0.0, 1.5),
                child: Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i % 2 == 0 ? medColor : Colors.white,
                    boxShadow: AppShadows.glow(medColor),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool glow;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                )
              ]
            : null,
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: L.bg,
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
