import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class InteractiveBodyMap extends StatelessWidget {
  final List<String> activeSystems;
  final String medName;

  const InteractiveBodyMap({
    super.key,
    required this.activeSystems,
    required this.medName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.accessibility_new_rounded, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'TARGET ORGANS',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Visualizing how $medName affects your body',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 200,
            height: 300,
            child: Stack(
              children: [
                // Base Silhouette
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BodySilhouettePainter(),
                  ),
                ),
                // Scanning Laser Effect
                Positioned.fill(
                  child: const _LaserScanner(),
                ),
                // Glowing Nodes based on active systems
                ..._buildNodes(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNodes() {
    final List<Widget> nodes = [];
    final sys = activeSystems.map((e) => e.toLowerCase()).toList();

    // Mapping systems to relative positions (x, y) from 0.0 to 1.0
    void addNode(String name, double x, double y, Color color) {
      nodes.add(
        Positioned(
          left: 200 * x - 15,
          top: 300 * y - 15,
          child: _GlowingNode(name: name, color: color),
        ),
      );
    }

    if (sys.contains('nervous') || sys.contains('brain')) {
      addNode('Brain', 0.5, 0.1, const Color(0xFF00E5FF)); // Cyan
    }
    if (sys.contains('cardiovascular') || sys.contains('heart')) {
      addNode('Heart', 0.53, 0.35, const Color(0xFFFF3B30)); // Red
    }
    if (sys.contains('respiratory') || sys.contains('lungs')) {
      addNode('Lungs', 0.5, 0.33, const Color(0xFFE0E0E0)); // White
    }
    if (sys.contains('digestive') || sys.contains('gastrointestinal')) {
      addNode('Stomach', 0.5, 0.48, const Color(0xFFFF9500)); // Orange
    }
    if (sys.contains('hepatic') || sys.contains('liver')) {
      addNode('Liver', 0.45, 0.45, const Color(0xFFFFD60A)); // Yellow
    }
    if (sys.contains('renal') || sys.contains('kidney')) {
      addNode('Kidneys', 0.5, 0.55, const Color(0xFFBF5AF2)); // Purple
    }
    if (sys.contains('musculoskeletal') || sys.contains('joints') || sys.contains('hematologic')) {
      addNode('Joints/Blood', 0.5, 0.7, AppColors.accent);
    }

    // Default node if none match
    if (nodes.isEmpty) {
      addNode('Systemic', 0.5, 0.5, Colors.white);
    }

    return nodes;
  }
}

class _LaserScanner extends StatelessWidget {
  const _LaserScanner();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 4,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accent.withValues(alpha: 0.0),
                AppColors.accent.withValues(alpha: 0.8),
                AppColors.accent.withValues(alpha: 0.0),
              ],
              stops: const [0.1, 0.5, 0.9],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.5),
                blurRadius: 12,
                spreadRadius: 2,
              )
            ],
          ),
        ).animate(onPlay: (c) => c.repeat()).slideY(
              begin: -constraints.maxHeight / 4,
              end: constraints.maxHeight / 4,
              duration: 3.seconds,
              curve: Curves.easeInOutSine,
            );
      },
    );
  }
}

class _GlowingNode extends StatelessWidget {
  final String name;
  final Color color;

  const _GlowingNode({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.3),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.8),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white,
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 0.8, end: 1.2, duration: 1.seconds),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Text(
            name.toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}

class _BodySilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    
    // Abstract Human Silhouette using bezier curves
    final w = size.width;
    final h = size.height;
    
    // Head
    path.addOval(Rect.fromCircle(center: Offset(w * 0.5, h * 0.1), radius: w * 0.15));
    
    // Neck and Shoulders
    path.moveTo(w * 0.45, h * 0.18);
    path.quadraticBezierTo(w * 0.4, h * 0.22, w * 0.25, h * 0.22); // Left shoulder
    path.quadraticBezierTo(w * 0.15, h * 0.22, w * 0.15, h * 0.3); // Left upper arm
    path.lineTo(w * 0.15, h * 0.5); // Left arm
    path.quadraticBezierTo(w * 0.15, h * 0.55, w * 0.2, h * 0.55); // Left hand
    path.lineTo(w * 0.25, h * 0.3); // Inner left arm
    
    // Torso
    path.lineTo(w * 0.3, h * 0.55); // Left waist
    path.lineTo(w * 0.25, h * 0.9); // Left leg
    path.quadraticBezierTo(w * 0.25, h * 0.95, w * 0.35, h * 0.95); // Left foot
    path.lineTo(w * 0.45, h * 0.6); // Crotch left
    
    path.quadraticBezierTo(w * 0.5, h * 0.55, w * 0.55, h * 0.6); // Crotch right
    
    path.lineTo(w * 0.65, h * 0.95); // Right leg
    path.quadraticBezierTo(w * 0.75, h * 0.95, w * 0.75, h * 0.9); // Right foot
    path.lineTo(w * 0.7, h * 0.55); // Right waist
    
    // Inner right arm
    path.lineTo(w * 0.75, h * 0.3); 
    path.lineTo(w * 0.85, h * 0.55); // Right hand
    path.quadraticBezierTo(w * 0.9, h * 0.55, w * 0.9, h * 0.5); // Right arm
    path.lineTo(w * 0.9, h * 0.3); // Right upper arm
    path.quadraticBezierTo(w * 0.9, h * 0.22, w * 0.75, h * 0.22); // Right shoulder
    path.quadraticBezierTo(w * 0.6, h * 0.22, w * 0.55, h * 0.18); // Neck
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
    
    // Draw some techy grid lines inside
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
      
    for(int i = 0; i < 10; i++) {
       canvas.drawLine(Offset(0, h * (i/10)), Offset(w, h * (i/10)), gridPaint);
       canvas.drawLine(Offset(w * (i/10), 0), Offset(w * (i/10), h), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
