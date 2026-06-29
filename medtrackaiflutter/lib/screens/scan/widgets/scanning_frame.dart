import 'package:flutter/material.dart';
import 'dart:math';
import '../../../theme/med_ai_ui.dart';

class ScanningFrame extends StatefulWidget {
  final bool isDetecting;
  final ScanFrameStyle style;
  final String? instruction;

  const ScanningFrame({
    super.key,
    this.isDetecting = false,
    this.style = ScanFrameStyle.capsule,
    this.instruction,
  });

  @override
  State<ScanningFrame> createState() => _ScanningFrameState();
}

enum ScanFrameStyle { capsule, square }

class _ScanningFrameState extends State<ScanningFrame>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.isDetecting && !MedAiA11y.reducedMotion(context)) {
        _pulseController.repeat(reverse: true);
      }
    });
  }

  @override
  void didUpdateWidget(ScanningFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDetecting != oldWidget.isDetecting) {
      if (widget.isDetecting && !MedAiA11y.reducedMotion(context)) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const color = AppColors.sageGreen;
    final reduceMotion = MedAiA11y.reducedMotion(context);
    final isSquare = widget.style == ScanFrameStyle.square;
    final frameW = isSquare ? 280.0 : 160.0;
    final frameH = isSquare ? 280.0 : 280.0;
    final radius = isSquare ? 20.0 : 80.0;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final alpha = widget.isDetecting && !reduceMotion
            ? 0.55 + (_pulseController.value * 0.25)
            : 0.45;
        return Semantics(
          label: widget.isDetecting
              ? 'Scanning in progress'
              : widget.instruction ?? 'Scan frame ready',
          child: Container(
            width: frameW,
            height: frameH,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: color.withValues(alpha: alpha),
                width: 2.0,
              ),
              boxShadow: widget.isDetecting
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 24,
                        spreadRadius: -4,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isSquare)
                  CustomPaint(
                    size: Size(frameW, frameH),
                    painter: _SquareCornersPainter(
                      color: color.withValues(alpha: alpha + 0.15),
                      strokeWidth: 3,
                    ),
                  )
                else
                  CustomPaint(
                    painter: _CapsuleCornersPainter(
                      color: color.withValues(alpha: alpha + 0.15),
                      strokeWidth: 2.5,
                    ),
                  ),
                if (widget.instruction != null && !widget.isDetecting)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      widget.instruction!,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SquareCornersPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _SquareCornersPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    const len = 28.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(12, 12, size.width - 24, size.height - 24);
    final tl = rect.topLeft;
    final tr = rect.topRight;
    final bl = rect.bottomLeft;
    final br = rect.bottomRight;

    canvas.drawLine(tl, tl + const Offset(len, 0), paint);
    canvas.drawLine(tl, tl + const Offset(0, len), paint);
    canvas.drawLine(tr, tr + Offset(-len, 0), paint);
    canvas.drawLine(tr, tr + const Offset(0, len), paint);
    canvas.drawLine(bl, bl + Offset(len, 0), paint);
    canvas.drawLine(bl, bl + const Offset(0, -len), paint);
    canvas.drawLine(br, br + Offset(-len, 0), paint);
    canvas.drawLine(br, br + const Offset(0, -len), paint);
  }

  @override
  bool shouldRepaint(_SquareCornersPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

class _CapsuleCornersPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _CapsuleCornersPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    canvas.drawArc(Rect.fromLTWH(0, 0, w, w), pi, pi, false, paint);
    canvas.drawArc(Rect.fromLTWH(0, h - w, w, w), 0, pi, false, paint);
  }

  @override
  bool shouldRepaint(_CapsuleCornersPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}
