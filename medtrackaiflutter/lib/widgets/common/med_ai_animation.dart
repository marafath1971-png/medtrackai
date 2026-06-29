import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:rive/rive.dart' hide LinearGradient, RadialGradient;
import '../../core/constants/med_ai_assets.dart';
import '../../theme/design_2026.dart';
import 'med_ai_logo.dart';

/// Loads Rive/Lottie assets with premium animated fallbacks when files are absent.
class MedAiAnimation extends StatefulWidget {
  final MedAiAnimationKind kind;
  final double width;
  final double height;
  final bool repeat;
  final BoxFit fit;

  const MedAiAnimation({
    super.key,
    required this.kind,
    this.width = 200,
    this.height = 200,
    this.repeat = true,
    this.fit = BoxFit.contain,
  });

  @override
  State<MedAiAnimation> createState() => _MedAiAnimationState();
}

class _MedAiAnimationState extends State<MedAiAnimation>
    with SingleTickerProviderStateMixin {
  Artboard? _riveArtboard;
  RiveAnimationController? _riveController;
  bool _useFallback = false;

  @override
  void initState() {
    super.initState();
    _loadRiveIfNeeded();
  }

  String? get _rivePath {
    switch (widget.kind) {
      case MedAiAnimationKind.splashLogo:
        return MedAiAssets.riveSplashLogo;
      case MedAiAnimationKind.onboardingStreak:
        return MedAiAssets.riveOnboardingStreak;
      case MedAiAnimationKind.onboardingScan:
        return MedAiAssets.riveOnboardingScan;
      case MedAiAnimationKind.onboardingFamily:
        return MedAiAssets.riveOnboardingFamily;
      case MedAiAnimationKind.paywallHero:
        return MedAiAssets.rivePaywallHero;
      case MedAiAnimationKind.celebrationCheck:
      case MedAiAnimationKind.emptyMeds:
        return null;
    }
  }

  String? get _lottiePath {
    switch (widget.kind) {
      case MedAiAnimationKind.celebrationCheck:
        return MedAiAssets.lottieCelebrationCheck;
      case MedAiAnimationKind.emptyMeds:
        return MedAiAssets.lottieEmptyMeds;
      default:
        return null;
    }
  }

  Future<void> _loadRiveIfNeeded() async {
    final path = _rivePath;
    if (path == null) return;
    try {
      final data = await rootBundle.load(path);
      final file = RiveFile.import(data);
      final artboard = file.mainArtboard;
      final ctrl = SimpleAnimation('idle', autoplay: true);
      artboard.addController(ctrl);
      if (mounted) {
        setState(() {
          _riveArtboard = artboard;
          _riveController = ctrl;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _useFallback = true);
    }
  }

  @override
  void dispose() {
    _riveController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lottie = _lottiePath;
    if (lottie != null) {
      return Lottie.asset(
        lottie,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        repeat: widget.repeat,
        errorBuilder: (_, __, ___) => _FallbackAnimation(
          kind: widget.kind,
          width: widget.width,
          height: widget.height,
        ),
      );
    }

    if (_riveArtboard != null && !_useFallback) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Rive(artboard: _riveArtboard!, fit: widget.fit),
      );
    }

    return _FallbackAnimation(
      kind: widget.kind,
      width: widget.width,
      height: widget.height,
    );
  }
}

class _FallbackAnimation extends StatefulWidget {
  final MedAiAnimationKind kind;
  final double width;
  final double height;

  const _FallbackAnimation({
    required this.kind,
    required this.width,
    required this.height,
  });

  @override
  State<_FallbackAnimation> createState() => _FallbackAnimationState();
}

class _FallbackAnimationState extends State<_FallbackAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.kind == MedAiAnimationKind.splashLogo) {
      return MedAiLogo(
        size: widget.width,
        asset: MedAiAssets.illustrationAppIconBlue,
      );
    }
    return _buildPaintedFallback(context);
  }

  Widget _buildPaintedFallback(BuildContext context) {
    final L = context.L;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: CustomPaint(
            painter: _FallbackPainter(
              kind: widget.kind,
              t: _ctrl.value,
              electric: Design2026.electric,
              sage: L.accent,
            ),
          ),
        );
      },
    );
  }
}

class _FallbackPainter extends CustomPainter {
  final MedAiAnimationKind kind;
  final double t;
  final Color electric;
  final Color sage;

  _FallbackPainter({
    required this.kind,
    required this.t,
    required this.electric,
    required this.sage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final breathe = 0.92 + 0.08 * math.sin(t * math.pi * 2);

    switch (kind) {
      case MedAiAnimationKind.splashLogo:
      case MedAiAnimationKind.paywallHero:
        _drawOrb(canvas, cx, cy, size.shortestSide * 0.28 * breathe, electric, sage);
        break;
      case MedAiAnimationKind.onboardingStreak:
        _drawStreak(canvas, cx, cy, size, breathe);
        break;
      case MedAiAnimationKind.onboardingScan:
        _drawScanFrame(canvas, size, t, electric);
        break;
      case MedAiAnimationKind.onboardingFamily:
        _drawShield(canvas, cx, cy, size.shortestSide * 0.32 * breathe, sage, electric);
        break;
      case MedAiAnimationKind.celebrationCheck:
        _drawCheck(canvas, cx, cy, size.shortestSide * 0.3, sage);
        break;
      case MedAiAnimationKind.emptyMeds:
        _drawPill(canvas, cx, cy, size.shortestSide * 0.35, electric, t);
        break;
    }
  }

  void _drawOrb(Canvas c, double cx, double cy, double r, Color glow, Color core) {
    c.drawCircle(
      Offset(cx, cy),
      r * 1.4,
      Paint()..color = glow.withValues(alpha: 0.15),
    );
    c.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [glow, core.withValues(alpha: 0.6)],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
    );
  }

  void _drawStreak(Canvas c, double cx, double cy, Size size, double breathe) {
    final path = Path();
    path.moveTo(cx, cy - size.height * 0.22 * breathe);
    path.quadraticBezierTo(
      cx + size.width * 0.08,
      cy - size.height * 0.05,
      cx,
      cy + size.height * 0.25 * breathe,
    );
    path.quadraticBezierTo(
      cx - size.width * 0.12,
      cy,
      cx,
      cy - size.height * 0.22 * breathe,
    );
    c.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [const Color(0xFFFF9F0A), const Color(0xFFFF6584)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  void _drawScanFrame(Canvas c, Size size, double t, Color electric) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.65,
        height: size.height * 0.45,
      ),
      const Radius.circular(24),
    );
    c.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = electric.withValues(alpha: 0.7),
    );
    final lineY = size.height * (0.28 + 0.44 * t);
    c.drawLine(
      Offset(size.width * 0.18, lineY),
      Offset(size.width * 0.82, lineY),
      Paint()
        ..strokeWidth = 2
        ..color = electric,
    );
  }

  void _drawShield(Canvas c, double cx, double cy, double h, Color sage, Color electric) {
    final path = Path()
      ..moveTo(cx, cy - h * 0.5)
      ..lineTo(cx + h * 0.45, cy - h * 0.15)
      ..lineTo(cx + h * 0.45, cy + h * 0.25)
      ..quadraticBezierTo(cx, cy + h * 0.55, cx - h * 0.45, cy + h * 0.25)
      ..lineTo(cx - h * 0.45, cy - h * 0.15)
      ..close();
    c.drawPath(path, Paint()..color = sage.withValues(alpha: 0.25));
    c.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = electric,
    );
  }

  void _drawCheck(Canvas c, double cx, double cy, double r, Color color) {
    c.drawCircle(Offset(cx, cy), r, Paint()..color = color.withValues(alpha: 0.2));
    final check = Path()
      ..moveTo(cx - r * 0.35, cy)
      ..lineTo(cx - r * 0.05, cy + r * 0.3)
      ..lineTo(cx + r * 0.4, cy - r * 0.25);
    c.drawPath(
      check,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  void _drawPill(Canvas c, double cx, double cy, double w, Color color, double t) {
    final dy = math.sin(t * math.pi * 2) * 6;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + dy), width: w, height: w * 0.45),
      Radius.circular(w * 0.225),
    );
    c.drawRRect(rect, Paint()..color = color.withValues(alpha: 0.85));
  }

  @override
  bool shouldRepaint(covariant _FallbackPainter old) =>
      old.t != t || old.kind != kind;
}
