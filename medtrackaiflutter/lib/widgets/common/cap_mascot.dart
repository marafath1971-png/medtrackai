import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum MascotMood { energetic, content, sleepy }
enum MascotAccessory { partyHat, glasses, scarf, badgePin }

class CapMascot extends StatelessWidget {
  final MascotMood mood;
  final List<MascotAccessory> unlockedAccessories;
  final double size;

  const CapMascot({
    super.key,
    required this.mood,
    this.unlockedAccessories = const [],
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * (90 / 70), // Maintain aspect ratio
      child: CustomPaint(
        painter: _CapMascotPainter(
          mood: mood,
          accessories: unlockedAccessories,
        ),
      ),
    );
  }
}

class _CapMascotPainter extends CustomPainter {
  final MascotMood mood;
  final List<MascotAccessory> accessories;

  _CapMascotPainter({required this.mood, required this.accessories});

  @override
  void paint(Canvas canvas, Size size) {
    // Scale everything relative to design coordinates (70x90)
    final double scaleX = size.width / 70;
    final double scaleY = size.height / 90;
    
    canvas.save();
    canvas.scale(scaleX, scaleY);

    // Sleepy state is tilted slightly (-8 degrees around center 35, 45)
    if (mood == MascotMood.sleepy) {
      canvas.translate(35, 45);
      canvas.rotate(-8 * math.pi / 180);
      canvas.translate(-35, -45);
    }

    final Paint bodyPaint = Paint()..style = PaintingStyle.fill;
    final Paint dividerPaint = Paint()..style = PaintingStyle.fill;
    final Paint linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF0A0A0C);

    // 1. Draw Body & Divider
    double bodyY = 6;
    double bodyHeight = 78;
    double dividerY = 42;

    // Shift body down slightly if party hat is active to let it fit
    if (accessories.contains(MascotAccessory.partyHat)) {
      bodyY = 14;
      bodyHeight = 70;
      dividerY = 48;
    }

    if (mood == MascotMood.energetic) {
      bodyPaint.color = AppColors.white;
      dividerPaint.color = AppColors.accent;
    } else if (mood == MascotMood.content) {
      bodyPaint.color = AppColors.white;
      dividerPaint.color = AppColors.grey300;
    } else {
      // Sleepy
      bodyPaint.color = AppColors.grey300;
      dividerPaint.color = AppColors.grey500;
    }

    // Draw Capsule Body
    final RRect bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(15, bodyY, 40, bodyHeight),
      const Radius.circular(20),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    // Draw Divider (Middle Band)
    canvas.drawRect(
      Rect.fromLTWH(15, dividerY, 40, 6),
      dividerPaint,
    );

    // 2. Draw Eyes and Mouth (face coordinates shift if body shifts)
    final double faceOffset = accessories.contains(MascotAccessory.partyHat) ? 6 : 0;
    final Paint facePaint = Paint()..color = const Color(0xFF0A0A0C);

    if (mood == MascotMood.energetic) {
      // Sparkles/Glow dots
      final Paint sparklePaint = Paint()..color = AppColors.accentLight;
      canvas.drawCircle(const Offset(13, 14), 1.6, sparklePaint);
      canvas.drawCircle(const Offset(58, 20), 1.6, sparklePaint);
      canvas.drawCircle(const Offset(11, 60), 1.6, sparklePaint);

      // Open Eyes
      canvas.drawCircle(Offset(28, 26 + faceOffset), 4, facePaint);
      canvas.drawCircle(Offset(42, 26 + faceOffset), 4, facePaint);

      // Smile
      final Path smilePath = Path()
        ..moveTo(26, 33 + faceOffset)
        ..quadraticBezierTo(35, 43 + faceOffset, 44, 33 + faceOffset);
      canvas.drawPath(smilePath, linePaint);

      // Legs/posture line
      final Paint legPaint = Paint()
        ..color = const Color(0xFF3A4A44)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(21, 86), const Offset(28, 83), legPaint);
      canvas.drawLine(const Offset(49, 86), const Offset(42, 83), legPaint);

    } else if (mood == MascotMood.content) {
      // Standard Eyes
      canvas.drawCircle(Offset(28, 26 + faceOffset), 3.5, facePaint);
      canvas.drawCircle(Offset(42, 26 + faceOffset), 3.5, facePaint);

      // Content mouth (subtle curve)
      final Path mouthPath = Path()
        ..moveTo(28, 35 + faceOffset)
        ..quadraticBezierTo(35, 39 + faceOffset, 42, 35 + faceOffset);
      canvas.drawPath(mouthPath, linePaint);

    } else if (mood == MascotMood.sleepy) {
      // Closed/Curved Eyes
      final Path eyeL = Path()
        ..moveTo(24, 27 + faceOffset)
        ..quadraticBezierTo(28, 30 + faceOffset, 32, 27 + faceOffset);
      final Path eyeR = Path()
        ..moveTo(38, 27 + faceOffset)
        ..quadraticBezierTo(42, 30 + faceOffset, 46, 27 + faceOffset);
      
      canvas.drawPath(eyeL, linePaint);
      canvas.drawPath(eyeR, linePaint);

      // Straight mouth
      canvas.drawLine(Offset(31, 37 + faceOffset), Offset(39, 37 + faceOffset), linePaint);
    }

    // Restore rotation from sleepy state so accessories are not rotated unless intended
    canvas.restore();

    // 3. Draw Accessories (drawn on top)
    if (accessories.contains(MascotAccessory.partyHat)) {
      // Cone Hat
      final Paint hatPaint = Paint()..color = AppColors.accent;
      final Path hatPath = Path()
        ..moveTo(35, 2)
        ..lineTo(46, 18)
        ..lineTo(24, 18)
        ..close();
      canvas.drawPath(hatPath, hatPaint);

      // Pom pom
      final Paint pomPaint = Paint()..color = AppColors.white;
      canvas.drawCircle(const Offset(35, 2), 2.5, pomPaint);
    }

    if (accessories.contains(MascotAccessory.glasses)) {
      final Paint glassFramePaint = Paint()
        ..color = AppColors.accent // Amber -> Accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      final double glassesY = 26 + faceOffset;
      // Left rim
      canvas.drawCircle(Offset(27, glassesY), 7, glassFramePaint);
      // Right rim
      canvas.drawCircle(Offset(43, glassesY), 7, glassFramePaint);
      // Bridge
      canvas.drawLine(Offset(34, glassesY), Offset(36, glassesY), glassFramePaint);
    }

    if (accessories.contains(MascotAccessory.scarf)) {
      final Paint scarfPaint = Paint()..color = AppColors.accent; // Accent scarf
      // Wrap around neck (divider area)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(13, dividerY - 1, 44, 8),
          const Radius.circular(4),
        ),
        scarfPaint,
      );
      // Scarf tail hanging down
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(42, dividerY + 7, 8, 16),
          const Radius.circular(2),
        ),
        scarfPaint,
      );
    }

    if (accessories.contains(MascotAccessory.badgePin)) {
      // Gold Badge Pin on bottom-right of body
      final Paint badgePaint = Paint()..color = AppColors.accent;
      final double badgeY = bodyY + bodyHeight - 16;
      canvas.drawCircle(Offset(45, badgeY), 4, badgePaint);
      
      final Paint starPaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(45, badgeY), 1.5, starPaint);
    }

    // 4. Draw sleepy Zs (outside capsule rotation, top-right)
    if (mood == MascotMood.sleepy) {
      final textPainterZ1 = TextPainter(
        text: const TextSpan(
          text: 'z',
          style: TextStyle(
            color: AppColors.grey500,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final textPainterZ2 = TextPainter(
        text: const TextSpan(
          text: 'z',
          style: TextStyle(
            color: AppColors.grey500,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainterZ1.paint(canvas, const Offset(52, 14));
      textPainterZ2.paint(canvas, const Offset(58, 8));
    }
  }

  @override
  bool shouldRepaint(covariant _CapMascotPainter oldDelegate) {
    return oldDelegate.mood != mood || oldDelegate.accessories != accessories;
  }
}
