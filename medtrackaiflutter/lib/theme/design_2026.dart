import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';

// ════════════════════════════════════════════════════════════════
// DESIGN 2026 — Viral / "Hooked" UI Kit
// Trends: liquid glass, kinetic type, aurora fields, living motion,
// high-contrast display numerics, single electric accent on mono.
// All widgets are stateless-of-state + RepaintBoundary-isolated.
// ════════════════════════════════════════════════════════════════

export 'app_theme.dart';

// ────────────────────────────────────────────────────────────────
// 2026 SPEC TOKENS
// ────────────────────────────────────────────────────────────────
class Design2026 {
  /// The single electric accent used for glow/CTA across 2026 surfaces.
  static const Color electric = Color(0xFF6CF2D2); // cyber-mint glow

  /// Aura pair tuned for the medical-wellness vibe.
  static const List<Color> aurora = [
    Color(0xFF4A9E86), // sage
    Color(0xFF6CF2D2), // mint
    Color(0xFF8B7BF2), // periwinkle
    Color(0xFF4ABFE2), // sky
  ];

  /// Liquid glass blur sigma.
  static const double glassBlur = 30;

  /// Tight, oversized display for hero numerics.
  static TextStyle displayHero(Color color) => GoogleFonts.outfit(
        fontSize: 64,
        fontWeight: FontWeight.w800,
        letterSpacing: -3.0,
        height: 0.95,
        color: color,
      );
}

// ────────────────────────────────────────────────────────────────
// AURORA BACKGROUND — drifting refractive color field.
// Replaces flat backgrounds with a living, breathing atmosphere.
// ────────────────────────────────────────────────────────────────
class AuroraBackground extends StatefulWidget {
  final List<Color> colors;
  final double opacity;
  const AuroraBackground({
    super.key,
    this.colors = Design2026.aurora,
    this.opacity = 1.0,
  });

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _AuroraPainter(
              t: _ctrl.value,
              colors: widget.colors,
              opacity: widget.opacity,
            ),
          );
        },
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double t;
  final List<Color> colors;
  final double opacity;
  _AuroraPainter({
    required this.t,
    required this.colors,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Four soft drifting blobs blended via 'plus' → dreamy aurora.
    final blobs = <_Blob>[
      _Blob(
        cx: 0.15 + 0.18 * math.sin(t * math.pi * 2),
        cy: 0.18 + 0.14 * math.cos(t * math.pi * 2),
        r: 0.55,
        color: colors[0 % colors.length],
      ),
      _Blob(
        cx: 0.85 - 0.16 * math.cos(t * math.pi * 2 * 1.1),
        cy: 0.30 + 0.20 * math.sin(t * math.pi * 2 * 0.8),
        r: 0.50,
        color: colors[1 % colors.length],
      ),
      _Blob(
        cx: 0.25 + 0.22 * math.cos(t * math.pi * 2 * 0.7),
        cy: 0.85 - 0.18 * math.sin(t * math.pi * 2 * 1.3),
        r: 0.60,
        color: colors[2 % colors.length],
      ),
      _Blob(
        cx: 0.78 + 0.14 * math.sin(t * math.pi * 2 * 0.9),
        cy: 0.80 + 0.12 * math.cos(t * math.pi * 2 * 1.2),
        r: 0.45,
        color: colors[3 % colors.length],
      ),
    ];

    for (final b in blobs) {
      final center = Offset(size.width * b.cx, size.height * b.cy);
      final radius = size.longestSide * b.r;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [b.color.withValues(alpha: 0.55 * opacity), b.color.withValues(alpha: 0.0)],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.t != t;
}

class _Blob {
  final double cx, cy, r;
  final Color color;
  const _Blob({required this.cx, required this.cy, required this.r, required this.color});
}

// ────────────────────────────────────────────────────────────────
// SURFACE CARD — liquid glass container with frosted depth.
// Uses BackdropFilter for iOS-style translucency; falls back to
// solid surface when blur would be invisible (no content behind).
// ────────────────────────────────────────────────────────────────
class LiquidGlass extends StatelessWidget {
  final Widget child;
  final double radius;
  final double blur;
  final EdgeInsetsGeometry padding;
  final Color? tint;
  final double tintOpacity;
  final bool showGloss;

  const LiquidGlass({
    super.key,
    required this.child,
    this.radius = 24,
    this.blur = Design2026.glassBlur,
    this.padding = const EdgeInsets.all(16),
    this.tint,
    this.tintOpacity = 0.06,
    this.showGloss = true,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = tint ?? L.card;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur * 0.65, sigmaY: blur * 0.65),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                base.withValues(alpha: isDark ? 0.72 : 0.88),
                base.withValues(alpha: isDark ? 0.58 : 0.76),
              ],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: L.glassBorder.withValues(alpha: isDark ? 0.16 : 0.28),
              width: 0.5,
            ),
            boxShadow: AppShadows.soft,
          ),
          child: Stack(
            children: [
              if (showGloss)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: radius,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: isDark ? 0.06 : 0.35),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// GLASS ORB — a 3D-refractive sphere (the viral hero element).
// Specular highlight + rim light + contact shadow + breathing aura.
// ────────────────────────────────────────────────────────────────
class GlassOrb extends StatefulWidget {
  final double size;
  final Color color;
  final IconData icon;
  final Widget? child;
  final bool breathe;
  const GlassOrb({
    super.key,
    this.size = 120,
    required this.color,
    this.icon = Icons.camera_alt_rounded,
    this.child,
    this.breathe = true,
  });

  @override
  State<GlassOrb> createState() => _GlassOrbState();
}

class _GlassOrbState extends State<GlassOrb> with TickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final breathe = Tween<double>(begin: 1.0, end: 1.04)
        .animate(CurvedAnimation(parent: _breath, curve: Curves.easeInOutSine));

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // ── Outer aura rings (breathing glow) ──
          if (widget.breathe)
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: breathe,
                  builder: (context, _) => CustomPaint(
                    painter: _OrbAuraPainter(
                      color: widget.color,
                      scale: breathe.value,
                    ),
                  ),
                ),
              ),
            ),
          // ── The sphere itself ──
          RepaintBoundary(
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _SpherePainter(color: widget.color),
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Center(
                  child: widget.child ??
                      Icon(widget.icon,
                          color: Colors.white,
                          size: widget.size * 0.38),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints a glossy 3D sphere: floor shadow → base radial → rim light → gloss.
class _SpherePainter extends CustomPainter {
  final Color color;
  _SpherePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Drop / contact shadow
    canvas.drawCircle(
      center.translate(0, radius * 0.12),
      radius * 0.96,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.30)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.18),
    );

    // Sphere body — radial gradient gives depth (light from top-left)
    final sphereRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.45),
          radius: 1.1,
          colors: [
            Color.lerp(color, Colors.white, 0.45)!,
            color,
            Color.lerp(color, Colors.black, 0.35)!,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(sphereRect),
    );

    // Rim light — bright edge on the lit side
    canvas.drawCircle(
      center,
      radius * 0.98,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.04
        ..shader = LinearGradient(
          begin: const Alignment(-0.5, -0.6),
          end: const Alignment(0.6, 0.7),
          colors: [
            Colors.white.withValues(alpha: 0.65),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(sphereRect),
    );

    // Specular highlight — the signature glass sheen
    final glossCenter = center.translate(-radius * 0.28, -radius * 0.34);
    canvas.drawOval(
      Rect.fromCenter(
        center: glossCenter,
        width: radius * 0.62,
        height: radius * 0.42,
      ),
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.85),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(
          center: glossCenter,
          radius: radius * 0.42,
        )),
    );
  }

  @override
  bool shouldRepaint(_SpherePainter old) => old.color != color;
}

/// Concentric breathing aura rings behind the orb.
class _OrbAuraPainter extends CustomPainter {
  final Color color;
  final double scale;
  _OrbAuraPainter({required this.color, required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final base = size.width / 2;

    for (var i = 0; i < 3; i++) {
      final expand = scale + i * 0.12;
      canvas.drawCircle(
        center,
        base * expand,
        Paint()
          ..style = PaintingStyle.fill
          ..color = color.withValues(alpha: 0.10 / (i + 1)),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbAuraPainter old) => old.scale != scale;
}

// ────────────────────────────────────────────────────────────────
// KINETIC TEXT — animated shimmer-gradient headline (the hook).
// ────────────────────────────────────────────────────────────────
class KineticText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final List<Color>? colors;
  final TextAlign align;
  const KineticText(
    this.text, {
    super.key,
    this.style,
    this.colors,
    this.align = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: colors ?? const [Color(0xFF6CF2D2), Color(0xFF4A9E86), Color(0xFF8B7BF2)],
    );

    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Text(text, style: style, textAlign: align),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 2600.ms,
          color: Colors.white.withValues(alpha: 0.35),
          angle: 0.4,
        );
  }
}

// ────────────────────────────────────────────────────────────────
// LIQUID FILL — animated sine-wave progress (refill / hydration vibe).
// ────────────────────────────────────────────────────────────────
class LiquidFill extends StatefulWidget {
  final double percent; // 0.0 – 1.0
  final Color color;
  final Color trackColor;
  final double width;
  final double height;
  const LiquidFill({
    super.key,
    required this.percent,
    required this.color,
    required this.trackColor,
    this.width = 44,
    this.height = 60,
  });

  @override
  State<LiquidFill> createState() => _LiquidFillState();
}

class _LiquidFillState extends State<LiquidFill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave;

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.width / 2),
          child: Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: widget.trackColor)),
              AnimatedBuilder(
                animation: _wave,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size(widget.width, widget.height),
                    painter: _LiquidWavePainter(
                      percent: widget.percent.clamp(0.0, 1.0),
                      color: widget.color,
                      phase: _wave.value,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiquidWavePainter extends CustomPainter {
  final double percent;
  final Color color;
  final double phase;
  _LiquidWavePainter({
    required this.percent,
    required this.color,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillHeight = size.height * (1 - percent);
    final path = Path();
    path.moveTo(0, fillHeight);
    const waveAmp = 3.0;
    const waveLen = 18.0;
    for (double x = 0; x <= size.width; x += 2) {
      final y = fillHeight +
          waveAmp * math.sin((x / waveLen) * 2 * math.pi + phase * 2 * math.pi);
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.8), color],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_LiquidWavePainter old) =>
      old.percent != percent || old.phase != phase;
}

// ────────────────────────────────────────────────────────────────
// LIVE STATUS DOT — pulsing "online / listening" indicator.
// ────────────────────────────────────────────────────────────────
class LiveStatusDot extends StatelessWidget {
  final Color color;
  final double size;
  const LiveStatusDot({super.key, this.color = Design2026.electric, this.size = 8});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.circle, size: size * 2.2, color: color.withValues(alpha: 0.18))
            .animate(onPlay: (c) => c.repeat())
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.6, 1.6), duration: 1600.ms)
            .fade(begin: 0.6, end: 0.0, duration: 1600.ms),
        Icon(Icons.circle, size: size, color: color),
      ],
    );
  }
}
