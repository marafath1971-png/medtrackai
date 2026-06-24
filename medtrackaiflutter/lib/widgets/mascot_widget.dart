import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_state.dart';

class MascotWidget extends StatelessWidget {
  final double size;
  final String mood; // 'energetic', 'sleepy', 'content', 'happy'

  const MascotWidget({
    super.key,
    this.size = 80,
    this.mood = 'energetic',
  });

  @override
  Widget build(BuildContext context) {
    Widget child = Consumer<AppState>(
      builder: (context, state, _) {
        final accessoryId = state.mascotAccessory;
        
        // Map accessory ID to emoji
        String? accessoryEmoji;
        switch (accessoryId) {
          case 'glasses': accessoryEmoji = '🕶️'; break;
          case 'crown': accessoryEmoji = '👑'; break;
          case 'party': accessoryEmoji = '🥳'; break;
          case 'wizard': accessoryEmoji = '🧙‍♂️'; break;
          case 'halo': accessoryEmoji = '😇'; break;
          case 'nerd': accessoryEmoji = '🤓'; break;
        }

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: _MascotPainter(mood: mood),
            ),
            if (accessoryEmoji != null)
              Positioned(
                top: _getAccessoryTopOffset(accessoryId, size),
                child: Text(
                  accessoryEmoji,
                  style: TextStyle(fontSize: _getAccessorySize(accessoryId, size)),
                ),
              ),
          ],
        );
      },
    );

    if (mood == 'energetic') {
      return child.animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: -5, end: 5, duration: 1000.ms, curve: Curves.easeInOut);
    } else if (mood == 'sleepy') {
      return child.animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: 0, end: 2, duration: 2000.ms, curve: Curves.easeInOut);
    } else {
      return child;
    }
  }

  double _getAccessoryTopOffset(String? id, double size) {
    if (id == 'crown' || id == 'party' || id == 'wizard' || id == 'halo') {
      return -size * 0.15; // Hats go on top
    } else {
      return size * 0.20; // Glasses go on eyes
    }
  }

  double _getAccessorySize(String? id, double size) {
    if (id == 'crown' || id == 'party' || id == 'wizard') {
      return size * 0.6;
    } else if (id == 'halo') {
      return size * 0.8;
    } else {
      return size * 0.55;
    }
  }
}

class _MascotPainter extends CustomPainter {
  final String mood;

  _MascotPainter({required this.mood});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final paint = Paint()..style = PaintingStyle.fill;

    // The Pill Body
    final RRect pillBody = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w / 2, h / 2), width: w * 0.6, height: h * 0.8),
      Radius.circular(w * 0.3),
    );

    // Draw Bottom Half (White)
    paint.color = AppColors.white;
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(0, h / 2, w, h), const Radius.circular(0)));
    canvas.drawRRect(pillBody, paint);
    canvas.restore();

    // Draw Top Half (Accent Orange)
    paint.color = AppColors.accent;
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(0, 0, w, h / 2), const Radius.circular(0)));
    canvas.drawRRect(pillBody, paint);
    canvas.restore();

    // Draw Eyes (White circles in top half)
    paint.color = Colors.white;
    double eyeSize = w * 0.08;
    double eyeOffsetY = h * 0.35;
    double eyeOffsetX = w * 0.12;
    
    if (mood == 'sleepy') {
      // Sleepy eyes (slits)
      paint.strokeWidth = 3;
      paint.strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(w / 2 - eyeOffsetX - eyeSize, eyeOffsetY),
          Offset(w / 2 - eyeOffsetX + eyeSize, eyeOffsetY), paint);
      canvas.drawLine(Offset(w / 2 + eyeOffsetX - eyeSize, eyeOffsetY),
          Offset(w / 2 + eyeOffsetX + eyeSize, eyeOffsetY), paint);
    } else if (mood == 'happy') {
      // Happy eyes (arcs)
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 3;
      paint.strokeCap = StrokeCap.round;
      canvas.drawArc(
          Rect.fromCenter(center: Offset(w / 2 - eyeOffsetX, eyeOffsetY), width: eyeSize * 2, height: eyeSize * 2),
          3.14, 3.14, false, paint);
      canvas.drawArc(
          Rect.fromCenter(center: Offset(w / 2 + eyeOffsetX, eyeOffsetY), width: eyeSize * 2, height: eyeSize * 2),
          3.14, 3.14, false, paint);
      paint.style = PaintingStyle.fill;
    } else {
      // Energetic/Content
      canvas.drawCircle(Offset(w / 2 - eyeOffsetX, eyeOffsetY), eyeSize, paint);
      canvas.drawCircle(Offset(w / 2 + eyeOffsetX, eyeOffsetY), eyeSize, paint);
    }

    // Draw Mouth
    paint.color = Colors.black.withValues(alpha: 0.6);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = w * 0.02;
    paint.strokeCap = StrokeCap.round;
    
    if (mood == 'energetic' || mood == 'happy') {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(w / 2, h * 0.5), width: w * 0.2, height: h * 0.1),
        0, 3.14, false, paint);
    } else if (mood == 'content') {
      canvas.drawLine(Offset(w / 2 - w * 0.05, h * 0.52), Offset(w / 2 + w * 0.05, h * 0.52), paint);
    } else if (mood == 'sleepy') {
      canvas.drawCircle(Offset(w / 2, h * 0.55), w * 0.03, paint); // small 'o' shape for sleepy
    }
  }

  @override
  bool shouldRepaint(covariant _MascotPainter oldDelegate) {
    return oldDelegate.mood != mood;
  }
}
