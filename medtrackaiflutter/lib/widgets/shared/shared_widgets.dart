import 'dart:ui';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../theme/med_ai_ui.dart' show MedAiA11y;
import '../../core/utils/haptic_engine.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/color_utils.dart';
import '../common/app_shimmer.dart';
import '../common/animated_pressable.dart';
export '../common/app_shimmer.dart';
export '../common/animated_pressable.dart';
export '../../theme/med_ai_ui.dart' show MedAiA11y, MedAiCTA, MedAiGlass, MedAiDepthCard, MedAiSectionHeader;

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
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return Semantics(
        toggled: value,
        child: CupertinoSwitch(
          value: value,
          activeTrackColor: L.success,
          onChanged: (v) {
            if (v) {
              HapticEngine.success();
            } else {
              HapticEngine.lightTap();
            }
            onChanged(v);
          },
        ),
      );
    }
    return AnimatedPressable(
      scaleFactor: 0.95, // Nice subtle squish for toggle press state
      hapticEnabled: false, // We handle custom haptics in onTap
      onTap: () {
        if (!value) {
          HapticEngine.success();
        } else {
          HapticEngine.lightTap();
        }
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        width: 52,
        height: 30,
        decoration: BoxDecoration(
          color: value ? L.text : L.fill.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Stack(children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            alignment: value
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOut,
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
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.borderRadius,
    this.showBorder = true,
    this.tintColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final r = borderRadius ?? AppRadius.roundXL;

    Widget content = ClipPath(
      clipper: ShapeBorderClipper(
        shape: ContinuousRectangleBorder(borderRadius: r),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
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
            shadows: const [],
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return AnimatedPressable(
        onTap: onTap,
        scaleFactor: 0.98,
        hapticEnabled: true,
        child: content,
      );
    }
    return content;
  }
}

// ══════════════════════════════════════════════
// BOUNCING BUTTON (iOS 26 Spring Interaction)
// ══════════════════════════════════════════════

class BouncingButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleFactor;
  final bool hapticEnabled;
  final Duration duration; // Kept for API compatibility, though AnimatedPressable uses physics

  const BouncingButton({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleFactor = 0.97,
    this.hapticEnabled = true,
    this.duration = const Duration(milliseconds: 350), 
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      enabled: onTap != null,
      child: AnimatedPressable(
        onTap: onTap,
        onLongPress: onLongPress,
        scaleFactor: scaleFactor,
        hapticEnabled: hapticEnabled,
        disabled: onTap == null && onLongPress == null,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: MedAiA11y.minTapTarget,
            minWidth: MedAiA11y.minTapTarget,
          ),
          alignment: Alignment.center,
          child: child,
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
  final VoidCallback? onTap;

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
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = radius ?? borderRadius ?? AppRadius.xl;
    final bw = borderWidth ?? 0.5;

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
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

    if (onTap != null) {
      return AnimatedPressable(
        onTap: onTap,
        scaleFactor: 0.98,
        child: content,
      );
    }
    return content;
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
    
    // Choose premium colors & icons for 2026 aesthetics
    final IconData iconData;
    final Color accentColor;
    
    switch (type) {
      case 'error':
        iconData = Icons.error_rounded;
        accentColor = AppColors.error;
        break;
      case 'warning':
        iconData = Icons.warning_amber_rounded;
        accentColor = AppColors.warning;
        break;
      case 'info':
        iconData = Icons.info_outline_rounded;
        accentColor = AppColors.blue;
        break;
      default:
        iconData = Icons.check_circle_rounded;
        accentColor = AppColors.success;
    }

    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Positioned(
      bottom: bottomPadding + 115,
      left: 24,
      right: 24,
      child: Center(
        child: Dismissible(
          key: UniqueKey(),
          direction: DismissDirection.horizontal,
          onDismissed: (_) {
            context.read<AppState>().clearToast();
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.12),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? Colors.black.withValues(alpha: 0.45)
                        : Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.25),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Beautiful animated glowing icon container
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor.withValues(alpha: 0.12),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          iconData,
                          color: accentColor,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(end: 4),
                          child: Text(
                            message,
                            style: AppTypography.bodyMedium.copyWith(
                              color: L.text,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: AppDurations.fast, curve: AppCurves.emilOut)
              .slideY(
                begin: 0.18,
                end: 0.0,
                curve: AppCurves.emilOut,
                duration: AppDurations.medium,
              )
              .scale(
                begin: const Offset(0.96, 0.96),
                curve: AppCurves.emilOut,
                duration: AppDurations.fast,
              ),
        ),
      ),
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
    with TickerProviderStateMixin {
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
    if (MedAiA11y.reducedMotion(context)) {
      widget.onTake();
      return;
    }
    setState(() => _showBurst = true);
    _burstCtrl.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 250), widget.onTake);
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final reduceMotion = MedAiA11y.reducedMotion(context);
    final medColor = hexToColor(widget.med.color);
    final isDone = widget.taken;

    final Widget checkboxChild = isDone
        ? KeyedSubtree(
            key: const ValueKey('checked'),
            child: Container(
              width: MedAiA11y.minTapTarget,
              height: MedAiA11y.minTapTarget,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [medColor, Color.lerp(medColor, const Color(0xFF10B981), 0.45)!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: AppShadows.glow(medColor, intensity: 0.35),
              ),
              child: const Center(
                child: Icon(Icons.check_rounded, size: 20, color: Colors.white),
              ),
            ),
          )
        : KeyedSubtree(
            key: const ValueKey('unchecked'),
            child: Container(
              width: MedAiA11y.minTapTarget,
              height: MedAiA11y.minTapTarget,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: medColor.withValues(alpha: 0.08),
                border: Border.all(
                  color: medColor.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: MedImage(
                  imageUrl: widget.med.imageUrl,
                  borderRadius: 100,
                  placeholder: Icon(
                    Icons.medication_rounded,
                    size: 20,
                    color: medColor.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Dismissible(
              key: ValueKey('dose_${widget.sched.id}_${widget.taken}'),
              direction: isDone ? DismissDirection.none : DismissDirection.startToEnd,
              confirmDismiss: (dir) async {
                if (dir == DismissDirection.startToEnd) {
                  _triggerDopamineBurst();
                }
                return false;
              },
              background: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                alignment: AlignmentDirectional.centerStart,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      L.accent.withValues(alpha: 0.08),
                      L.success.withValues(alpha: 0.2),
                    ],
                    begin: AlignmentDirectional.centerStart,
                    end: AlignmentDirectional.centerEnd,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: L.success.withValues(alpha: 0.25),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_rounded, color: L.success, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      'Mark as taken',
                      style: AppTypography.labelMedium.copyWith(
                        color: L.success,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              child: Semantics(
                button: true,
                label: '${widget.med.name}, ${fmtTime(widget.sched.h, widget.sched.m, context)}',
                child: AnimatedPressable(
                  onTap: widget.onTap,
                  scaleFactor: 0.97,
                  lightHaptic: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDone
                          ? L.card.withValues(alpha: 0.72)
                          : L.card,
                      borderRadius: BorderRadius.circular(AppRadius.l),
                      border: Border.all(
                        color: isDone
                            ? L.border.withValues(alpha: 0.25)
                            : widget.overdue
                                ? L.error.withValues(alpha: 0.35)
                                : widget.isNext
                                    ? L.accent.withValues(alpha: 0.45)
                                    : L.border.withValues(alpha: 0.35),
                        width: widget.isNext && !isDone ? 1.2 : 0.5,
                      ),
                      boxShadow: (widget.isNext && !isDone)
                          ? AppShadows.glow(L.accent, intensity: 0.12)
                          : null,
                    ),
                    child: Row(
                      children: [
                        AnimatedSwitcher(
                          duration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 500),
                          transitionBuilder: (child, anim) {
                            final scale = Tween<double>(begin: 0.72, end: 1.0).animate(
                              CurvedAnimation(parent: anim, curve: Curves.elasticOut),
                            );
                            return ScaleTransition(scale: scale, child: child);
                          },
                          child: checkboxChild,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.med.name,
                                style: AppTypography.labelLarge.copyWith(
                                  color: isDone ? L.text.withValues(alpha: 0.35) : L.text,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  letterSpacing: -0.3,
                                  decoration: isDone ? TextDecoration.lineThrough : null,
                                  decorationColor: L.text.withValues(alpha: 0.2),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Text(
                                    fmtTime(widget.sched.h, widget.sched.m, context),
                                    style: AppTypography.labelSmall.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDone
                                          ? L.sub.withValues(alpha: 0.25)
                                          : widget.overdue
                                              ? L.error.withValues(alpha: 0.85)
                                              : L.sub.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  if (widget.med.dose.isNotEmpty) ...[
                                    Text(
                                      ' · ',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: L.sub.withValues(alpha: 0.25),
                                        fontSize: 12,
                                      ),
                                    ),
                                    Flexible(
                                      child: Text(
                                        widget.med.dose,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.labelSmall.copyWith(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDone ? L.sub.withValues(alpha: 0.25) : L.sub.withValues(alpha: 0.45),
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (widget.isNext && !isDone) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: L.accent.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Next',
                                        style: AppTypography.labelSmall.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: L.accent,
                                        ),
                                      ),
                                    ),
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
            if (_showBurst && !reduceMotion)
              Positioned.fill(
                child: IgnorePointer(
                  child: DopamineBurstOverlay(controller: _burstCtrl, medColor: medColor),
                ),
              ),
          ],
        );
  }

  Widget _buildCta(AppThemeColors L, Color medColor) {
    if (widget.taken) {
      return const SizedBox.shrink();
    }
    if (widget.overdue) {
      return Semantics(
        button: true,
        label: 'Mark ${widget.med.name} as taken, late',
        child: AnimatedPressable(
          onTap: () {
            HapticEngine.medium();
            widget.onTake();
          },
          child: Container(
            constraints: BoxConstraints(minHeight: MedAiA11y.minTapTargetCompact),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: L.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.s),
              border: Border.all(
                  color: L.error.withValues(alpha: 0.3), width: 0.8),
            ),
            child: Text(
              'Late',
              style: AppTypography.labelSmall.copyWith(
                color: L.error,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      );
    }
    if (widget.isNext) {
      return Semantics(
        button: true,
        label: 'Log ${widget.med.name}',
        child: AnimatedPressable(
          onTap: () {
            HapticEngine.selection();
            _triggerDopamineBurst();
          },
          child: Container(
            constraints: BoxConstraints(minHeight: MedAiA11y.minTapTargetCompact),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: L.text,
              borderRadius: BorderRadius.circular(AppRadius.s),
              boxShadow: AppShadows.glow(L.accent, intensity: 0.2),
            ),
            child: Text(
              'Log',
              style: AppTypography.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      );
    }
    return Semantics(
      button: true,
      label: 'Log ${widget.med.name}',
      child: AnimatedPressable(
        onTap: () {
          HapticEngine.light();
          widget.onTake();
        },
        child: Container(
          width: MedAiA11y.minTapTarget,
          height: MedAiA11y.minTapTarget,
          decoration: BoxDecoration(
            color: L.fill.withValues(alpha: 0.4),
            shape: BoxShape.circle,
            border: Border.all(
                color: L.border.withValues(alpha: 0.15), width: 1.0),
          ),
          child: Icon(
            Icons.add_rounded,
            size: 20,
            color: L.text.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

// ── Dopamine Burst Particle System ───────────────
class DopamineBurstOverlay extends StatelessWidget {
  final AnimationController controller;
  final Color medColor;
  const DopamineBurstOverlay({super.key, required this.controller, required this.medColor});

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
