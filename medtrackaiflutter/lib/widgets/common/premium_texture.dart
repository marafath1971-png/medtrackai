import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/med_ai_ui.dart';

/// Home reference canvas — soft cream with a lime wash at the top.
class PremiumHomeSurface extends StatelessWidget {
  final Widget child;

  const PremiumHomeSurface({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return ColoredBox(
        color: const Color(0xFF12141C),
        child: child,
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.bgLight,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment(0, 0.45),
          colors: [
            AppColors.pastelMint,
            AppColors.bgLight,
            Color(0xFFF7F7F9),
          ],
          stops: [0.0, 0.22, 1.0],
        ),
      ),
      child: child,
    );
  }
}

enum PremiumTextureStyle { dots, waves, fineGrain, none }

/// Frosted / textured premium card shell used on Home surfaces.
class PremiumTextureCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final PremiumTextureStyle texture;
  final List<BoxShadow>? shadows;

  const PremiumTextureCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.color,
    this.texture = PremiumTextureStyle.none,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final bg = color ?? L.card;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: L.border.withValues(alpha: context.isDark ? 0.2 : 0.12),
          width: 0.5,
        ),
        boxShadow: shadows ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            if (texture != PremiumTextureStyle.none)
              Positioned.fill(
                child: CustomPaint(
                  painter: PremiumTexturePainter(
                    style: texture,
                    color: L.text.withValues(alpha: 0.04),
                  ),
                ),
              ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

class PremiumTexturePainter extends CustomPainter {
  final PremiumTextureStyle style;
  final Color color;

  PremiumTexturePainter({
    required this.style,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    switch (style) {
      case PremiumTextureStyle.dots:
        for (var x = 6.0; x < size.width; x += 10) {
          for (var y = size.height * 0.35; y < size.height; y += 10) {
            canvas.drawCircle(Offset(x, y), 0.9, paint);
          }
        }
      case PremiumTextureStyle.waves:
        final path = Path();
        for (var y = size.height * 0.5; y < size.height; y += 12) {
          path.moveTo(0, y);
          for (var x = 0.0; x <= size.width; x += 6) {
            path.lineTo(x, y + math.sin(x / 16) * 3);
          }
        }
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 1;
        canvas.drawPath(path, paint);
      case PremiumTextureStyle.fineGrain:
        final rnd = math.Random(7);
        for (var i = 0; i < 120; i++) {
          final x = rnd.nextDouble() * size.width;
          final y = rnd.nextDouble() * size.height;
          paint.style = PaintingStyle.fill;
          canvas.drawCircle(
            Offset(x, y),
            0.35 + rnd.nextDouble() * 0.4,
            paint..color = color.withValues(alpha: 0.03 + rnd.nextDouble() * 0.04),
          );
        }
      case PremiumTextureStyle.none:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant PremiumTexturePainter old) =>
      old.style != style || old.color != color;
}

/// Subtle highlight sheen for hero gradients (lime progress card).
class PremiumHeroSheen extends StatelessWidget {
  const PremiumHeroSheen({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.38),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: PremiumTexturePainter(
                style: PremiumTextureStyle.waves,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
