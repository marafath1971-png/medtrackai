import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';

/// Retro 8-bit Pixel Art Medicine Companion Widget.
///
/// Pure Flutter CustomPainter rendering a crisp, animated 16x16 pixel capsule
/// with idle breathing, periodic eye blinks, floating retro 8-bit sparkles,
/// and interactive tap hop-celebrations.
class PixelArtMascot extends StatefulWidget {
  final double size;
  final bool showSparkles;
  final String? tooltip;
  final VoidCallback? onTap;

  const PixelArtMascot({
    super.key,
    this.size = 80,
    this.showSparkles = true,
    this.tooltip,
    this.onTap,
  });

  @override
  State<PixelArtMascot> createState() => _PixelArtMascotState();
}

class _PixelArtMascotState extends State<PixelArtMascot>
    with TickerProviderStateMixin {
  late final AnimationController _idleController;
  late final AnimationController _blinkController;
  late final AnimationController _hopController;

  @override
  void initState() {
    super.initState();

    // 1. Idle breathing/bobbing (gentle continuous oscillation)
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // 2. Natural eye blinking cycle
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    // 3. Interactive joyful hop when tapped
    _hopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
  }

  @override
  void dispose() {
    _idleController.dispose();
    _blinkController.dispose();
    _hopController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticEngine.selection();
    _hopController.forward(from: 0.0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Tooltip(
        message: widget.tooltip ?? 'Med AI Pixel Buddy',
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _idleController,
            _blinkController,
            _hopController,
          ]),
          builder: (context, child) {
            // Idle bobbing: -4px to +4px
            final idleOffset = math.sin(_idleController.value * math.pi * 2) * 4.0;

            // Hop trajectory (parabolic jump on tap)
            final hopProgress = _hopController.value;
            final hopOffset = -math.sin(hopProgress * math.pi) * 16.0;
            final hopScale = 1.0 + math.sin(hopProgress * math.pi) * 0.12;

            // Blink calculation (blink is closed for a brief 150ms window)
            // Blink cycle is 3.2s: values 0.90 to 0.96 are closed eye
            final blinkVal = _blinkController.value;
            final isBlinking = blinkVal >= 0.88 && blinkVal <= 0.96;

            return Transform.translate(
              offset: Offset(0, idleOffset + hopOffset),
              child: Transform.scale(
                scale: hopScale,
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: CustomPaint(
                    painter: _PixelMascotPainter(
                      isBlinking: isBlinking,
                      sparklePhase: _idleController.value,
                      showSparkles: widget.showSparkles,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PixelMascotPainter extends CustomPainter {
  final bool isBlinking;
  final double sparklePhase;
  final bool showSparkles;

  _PixelMascotPainter({
    required this.isBlinking,
    required this.sparklePhase,
    required this.showSparkles,
  });

  // 16x16 Pixel Art Color Palette
  static const Color _outline = Color(0xFF1E232A);
  static const Color _topPrimary = AppColors.limeDeep;
  static const Color _topLight = Color(0xFFA6E33B);
  static const Color _topDark = Color(0xFF6B9C18);
  static const Color _botPrimary = Color(0xFFF7FAFC);
  static const Color _botShadow = Color(0xFFCBD5E1);
  static const Color _eye = Color(0xFF0F172A);
  static const Color _eyeShine = Colors.white;
  static const Color _blush = Color(0xFFFF8BA7);
  static const Color _heart = Color(0xFFFF5252);
  static const Color _gold = Color(0xFFFFD166);

  // 16x16 Grid:
  // 0: transparent
  // 1: outline
  // 2: top primary (Lime)
  // 3: top light highlight
  // 4: top dark shadow
  // 5: bottom white
  // 6: bottom shadow
  // 7: eye
  // 8: blush
  // 9: heart
  static const List<List<int>> _grid = [
    [0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0], // Row 0
    [0, 0, 0, 1, 1, 3, 3, 2, 2, 2, 2, 1, 1, 0, 0, 0], // Row 1
    [0, 0, 1, 3, 3, 3, 2, 2, 2, 2, 2, 4, 4, 1, 0, 0], // Row 2
    [0, 1, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 4, 4, 1, 0], // Row 3
    [0, 1, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 4, 1, 0], // Row 4
    [0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 4, 1, 0], // Row 5
    [0, 1, 2, 2, 7, 7, 2, 2, 2, 2, 7, 7, 2, 4, 1, 0], // Row 6 (Eyes)
    [0, 1, 2, 8, 7, 7, 8, 2, 2, 8, 7, 7, 8, 4, 1, 0], // Row 7 (Blush/Eyes)
    [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0], // Row 8 (Belt / Seam)
    [0, 1, 5, 5, 5, 5, 5, 9, 9, 5, 5, 5, 5, 6, 1, 0], // Row 9 (Heart chest)
    [0, 1, 5, 5, 5, 5, 9, 9, 9, 9, 5, 5, 5, 6, 1, 0], // Row 10
    [0, 1, 5, 5, 5, 5, 5, 9, 9, 5, 5, 5, 5, 6, 1, 0], // Row 11
    [0, 1, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 1, 0], // Row 12
    [0, 0, 1, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 1, 0, 0], // Row 13
    [0, 0, 0, 1, 1, 5, 5, 5, 5, 6, 6, 1, 1, 0, 0, 0], // Row 14
    [0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0], // Row 15
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const cols = 16;
    const rows = 16;
    final pixelSize = size.width / cols;
    final paint = Paint()..isAntiAlias = false;

    // Draw main 16x16 pixel sprite
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        int cell = _grid[r][c];

        // Eye state override for blinking
        if ((r == 6 || r == 7) && (c == 4 || c == 5 || c == 10 || c == 11)) {
          if (isBlinking) {
            // Closed eye: only bottom row is dark line
            if (r == 7) {
              cell = 7;
            } else {
              cell = 2; // Lime top background
            }
          }
        }

        if (cell == 0) continue;

        Color color;
        switch (cell) {
          case 1:
            color = _outline;
            break;
          case 2:
            color = _topPrimary;
            break;
          case 3:
            color = _topLight;
            break;
          case 4:
            color = _topDark;
            break;
          case 5:
            color = _botPrimary;
            break;
          case 6:
            color = _botShadow;
            break;
          case 7:
            color = _eye;
            break;
          case 8:
            color = _blush;
            break;
          case 9:
            color = _heart;
            break;
          default:
            color = Colors.transparent;
        }

        paint.color = color;
        canvas.drawRect(
          Rect.fromLTWH(
            c * pixelSize,
            r * pixelSize,
            pixelSize,
            pixelSize,
          ),
          paint,
        );

        // Add eye shine highlights when eyes are open
        if (!isBlinking && r == 6 && (c == 4 || c == 10)) {
          paint.color = _eyeShine;
          canvas.drawRect(
            Rect.fromLTWH(
              c * pixelSize,
              r * pixelSize,
              pixelSize * 0.5,
              pixelSize * 0.5,
            ),
            paint,
          );
        }
      }
    }

    // Draw floating 8-bit sparkles / stars
    if (showSparkles) {
      _drawPixelSparkle(
        canvas,
        paint,
        x: size.width * 0.12,
        y: size.height * 0.22 + math.sin(sparklePhase * math.pi * 2) * 5,
        unit: pixelSize * 0.8,
        color: _gold,
      );

      _drawPixelSparkle(
        canvas,
        paint,
        x: size.width * 0.88,
        y: size.height * 0.28 + math.cos(sparklePhase * math.pi * 2) * 6,
        unit: pixelSize * 0.9,
        color: _topLight,
      );

      _drawPixelSparkle(
        canvas,
        paint,
        x: size.width * 0.82,
        y: size.height * 0.78 + math.sin((sparklePhase + 0.5) * math.pi * 2) * 4,
        unit: pixelSize * 0.7,
        color: _heart,
      );
    }
  }

  /// 4-pointed 8-bit retro sparkle star
  ///      [█]
  ///   [█][█][█]
  ///      [█]
  void _drawPixelSparkle(
    Canvas canvas,
    Paint paint, {
    required double x,
    required double y,
    required double unit,
    required Color color,
  }) {
    paint.color = color;
    // Center pixel
    canvas.drawRect(Rect.fromLTWH(x, y, unit, unit), paint);
    // North
    canvas.drawRect(Rect.fromLTWH(x, y - unit, unit, unit), paint);
    // South
    canvas.drawRect(Rect.fromLTWH(x, y + unit, unit, unit), paint);
    // West
    canvas.drawRect(Rect.fromLTWH(x - unit, y, unit, unit), paint);
    // East
    canvas.drawRect(Rect.fromLTWH(x + unit, y, unit, unit), paint);
  }

  @override
  bool shouldRepaint(_PixelMascotPainter old) =>
      old.isBlinking != isBlinking ||
      old.sparklePhase != sparklePhase ||
      old.showSparkles != showSparkles;
}
