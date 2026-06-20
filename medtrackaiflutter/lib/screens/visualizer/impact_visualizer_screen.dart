import 'dart:math';

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/shared/shared_widgets.dart';

class OrganCluster {
  final String name;
  final Offset relativePos; // x: -1 to 1, y: -1 to 1
  final double startHour;
  final double peakHour;
  final double endHour;
  final Color color;

  OrganCluster({
    required this.name,
    required this.relativePos,
    required this.startHour,
    required this.peakHour,
    required this.endHour,
    required this.color,
  });

  double getActivation(double currentHour) {
    if (currentHour < startHour || currentHour > endHour) return 0.0;
    if (currentHour <= peakHour) {
      return (currentHour - startHour) / (peakHour - startHour);
    } else {
      return 1.0 - ((currentHour - peakHour) / (endHour - peakHour));
    }
  }
}

class ImpactVisualizerScreen extends StatefulWidget {
  const ImpactVisualizerScreen({super.key});

  @override
  State<ImpactVisualizerScreen> createState() => _ImpactVisualizerScreenState();
}

class _ImpactVisualizerScreenState extends State<ImpactVisualizerScreen> with SingleTickerProviderStateMixin {
  double _currentHour = 0.0; // 0 to 24
  late AnimationController _pulseController;

  final List<OrganCluster> _organs = [
    OrganCluster(
      name: 'Brain',
      relativePos: const Offset(0.0, -0.7),
      startHour: 1.0,
      peakHour: 4.0,
      endHour: 12.0,
      color: const Color(0xFF00E5FF), // Cyan
    ),
    OrganCluster(
      name: 'Heart',
      relativePos: const Offset(-0.25, -0.35),
      startHour: 0.5,
      peakHour: 2.0,
      endHour: 8.0,
      color: const Color(0xFFFF3B30), // Red
    ),
    OrganCluster(
      name: 'Digestive',
      relativePos: const Offset(0.05, -0.05),
      startHour: 0.0,
      peakHour: 1.5,
      endHour: 5.0,
      color: const Color(0xFFFF9500), // Orange
    ),
    OrganCluster(
      name: 'Liver',
      relativePos: const Offset(0.25, 0.1),
      startHour: 2.0,
      peakHour: 6.0,
      endHour: 16.0,
      color: const Color(0xFFFFD60A), // Yellow
    ),
    OrganCluster(
      name: 'Kidneys',
      relativePos: const Offset(-0.2, 0.35),
      startHour: 4.0,
      peakHour: 10.0,
      endHour: 24.0,
      color: const Color(0xFFBF5AF2), // Purple
    ),
    OrganCluster(
      name: 'Muscles',
      relativePos: const Offset(0.45, 0.45),
      startHour: 3.0,
      peakHour: 8.0,
      endHour: 20.0,
      color: const Color(0xFFFF6B35), // Coral Orange
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onSliderChanged(double value) {
    setState(() {
      _currentHour = value;
    });
  }

  void _onSliderChangeEnd(double value) {
    HapticEngine.selection();
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final size = MediaQuery.of(context).size;
    final center = Offset(size.width / 2, size.height / 2 - 20);
    // Determine bounds for drawing
    final drawRadiusX = size.width * 0.4;
    final drawRadiusY = size.height * 0.32;

    return Scaffold(
      backgroundColor: L.bg,
      body: Stack(
        children: [
          // Background ambient glow (based on organ activation)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                // Determine max activation across all organs to pulse background
                double maxAct = 0.0;
                for (var o in _organs) {
                  final act = o.getActivation(_currentHour);
                  if (act > maxAct) maxAct = act;
                }

                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.5,
                      colors: [
                        L.text.withValues(alpha: 0.04 * maxAct * (0.8 + 0.2 * _pulseController.value)),
                        L.bg,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 1. Holographic Silhouette
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _HolographicBodySilhouettePainter(
                    center: center,
                    radiusX: drawRadiusX,
                    radiusY: drawRadiusY,
                    borderColor: L.text,
                    fillColor: L.fill,
                    pulse: _pulseController.value,
                  ),
                );
              },
            ),
          ),

          // 2. Holographic Node Network
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _OrganNetworkPainter(
                    currentHour: _currentHour,
                    pulse: _pulseController.value,
                    color: L.text,
                    subColor: L.border,
                    organs: _organs,
                    center: center,
                    radiusX: drawRadiusX,
                    radiusY: drawRadiusY,
                  ),
                );
              },
            ),
          ),

          // 3. Organ Labels Overlay
          ..._organs.map((organ) {
            final act = organ.getActivation(_currentHour);
            final pos = Offset(
              center.dx + organ.relativePos.dx * drawRadiusX,
              center.dy + organ.relativePos.dy * drawRadiusY,
            );

            // Shift label so it doesn't overlap nodes
            final isLeft = organ.relativePos.dx < 0;
            final labelOffset = isLeft ? const Offset(-90, -10) : const Offset(32, -10);

            return Positioned(
              left: pos.dx + labelOffset.dx,
              top: pos.dy + labelOffset.dy,
              child: AnimatedOpacity(
                opacity: act > 0.05 ? 1.0 : 0.45,
                duration: const Duration(milliseconds: 200),
                child: Column(
                  crossAxisAlignment: isLeft ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      organ.name.toUpperCase(),
                      style: AppTypography.labelSmall.copyWith(
                        color: act > 0.1 ? organ.color : L.sub.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        fontSize: 10,
                        shadows: act > 0.1
                            ? [
                                Shadow(
                                  color: organ.color.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                )
                              ]
                            : [],
                      ),
                    ),
                    Text(
                      '${(act * 100).toInt()}%',
                      style: AppTypography.bodyMedium.copyWith(
                        color: act > 0.1 ? L.text : L.text.withValues(alpha: 0.5),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // Header
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      BouncingButton(
                        onTap: () {
                          HapticEngine.selection();
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: L.card,
                            shape: BoxShape.circle,
                            border: Border.all(color: L.border.withValues(alpha: 0.4)),
                          ),
                          child: Icon(Icons.arrow_back_rounded, color: L.text, size: 20),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'ORGAN IMPACT',
                            style: AppTypography.labelSmall.copyWith(
                              color: L.sub.withValues(alpha: 0.7),
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 44), // Balance header
                    ],
                  ),
                ),

                const Spacer(),

                // Bottom Scrubber Floating Glass Capsule
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    borderRadius: BorderRadius.circular(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '0h (Dose)',
                              style: AppTypography.labelSmall.copyWith(
                                color: L.text.withValues(alpha: 0.4),
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              '24h (Clearance)',
                              style: AppTypography.labelSmall.copyWith(
                                color: L.text.withValues(alpha: 0.4),
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 2,
                            activeTrackColor: L.text,
                            inactiveTrackColor: L.border.withValues(alpha: 0.15),
                            thumbColor: L.text,
                            overlayColor: L.text.withValues(alpha: 0.1),
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                          ),
                          child: Slider(
                            value: _currentHour,
                            min: 0,
                            max: 24,
                            onChanged: _onSliderChanged,
                            onChangeEnd: _onSliderChangeEnd,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Time: ',
                              style: AppTypography.bodyMedium.copyWith(
                                color: L.text.withValues(alpha: 0.5),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_currentHour.toStringAsFixed(1)} Hours',
                              style: AppTypography.titleMedium.copyWith(
                                color: L.text,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HolographicBodySilhouettePainter extends CustomPainter {
  final Offset center;
  final double radiusX;
  final double radiusY;
  final Color borderColor;
  final Color fillColor;
  final double pulse;

  _HolographicBodySilhouettePainter({
    required this.center,
    required this.radiusX,
    required this.radiusY,
    required this.borderColor,
    required this.fillColor,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = fillColor.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();

    double mapX(double x) => center.dx + (x - 0.5) * radiusX * 1.8;
    double mapY(double y) => center.dy + (y - 0.45) * radiusY * 2.2;

    // Head
    path.addOval(Rect.fromCircle(
      center: Offset(mapX(0.5), mapY(0.1)),
      radius: radiusX * 0.28,
    ));

    // Neck and Shoulders
    path.moveTo(mapX(0.45), mapY(0.18));
    path.quadraticBezierTo(mapX(0.4), mapY(0.22), mapX(0.25), mapY(0.22)); // Left shoulder
    path.quadraticBezierTo(mapX(0.15), mapY(0.22), mapX(0.15), mapY(0.3)); // Left upper arm
    path.lineTo(mapX(0.15), mapY(0.5)); // Left arm
    path.quadraticBezierTo(mapX(0.15), mapY(0.55), mapX(0.2), mapY(0.55)); // Left hand
    path.lineTo(mapX(0.25), mapY(0.3)); // Inner left arm

    // Torso
    path.lineTo(mapX(0.3), mapY(0.55)); // Left waist
    path.lineTo(mapX(0.25), mapY(0.9)); // Left leg
    path.quadraticBezierTo(mapX(0.25), mapY(0.95), mapX(0.35), mapY(0.95)); // Left foot
    path.lineTo(mapX(0.45), mapY(0.6)); // Crotch left

    path.quadraticBezierTo(mapX(0.5), mapY(0.55), mapX(0.55), mapY(0.6)); // Crotch right

    path.lineTo(mapX(0.65), mapY(0.95)); // Right leg
    path.quadraticBezierTo(mapX(0.75), mapY(0.95), mapX(0.75), mapY(0.9)); // Right foot
    path.lineTo(mapX(0.7), mapY(0.55)); // Right waist

    // Inner right arm
    path.lineTo(mapX(0.75), mapY(0.3));
    path.lineTo(mapX(0.85), mapY(0.55)); // Right hand
    path.quadraticBezierTo(mapX(0.9), mapY(0.55), mapX(0.9), mapY(0.5)); // Right arm
    path.lineTo(mapX(0.9), mapY(0.3)); // Right upper arm
    path.quadraticBezierTo(mapX(0.9), mapY(0.22), mapX(0.75), mapY(0.22)); // Right shoulder
    path.quadraticBezierTo(mapX(0.6), mapY(0.22), mapX(0.55), mapY(0.18)); // Neck
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    // Grid lines inside the body (clipped)
    canvas.save();
    canvas.clipPath(path);

    final gridPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    int lines = 12;
    for (int i = 0; i <= lines; i++) {
      double y = mapY(i / lines);
      canvas.drawLine(Offset(center.dx - radiusX, y), Offset(center.dx + radiusX, y), gridPaint);
      double x = mapX(i / lines);
      canvas.drawLine(Offset(x, center.dy - radiusY * 1.2), Offset(x, center.dy + radiusY * 1.2), gridPaint);
    }

    canvas.restore();

    // Clipped laser scanner line
    double laserY = mapY(0.08 + pulse * 0.77);
    final laserPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.save();
    canvas.clipPath(path);

    final gradient = LinearGradient(
      colors: [
        borderColor.withValues(alpha: 0.0),
        borderColor.withValues(alpha: 0.4),
        borderColor.withValues(alpha: 0.0),
      ],
    );
    laserPaint.shader = gradient.createShader(
      Rect.fromLTRB(center.dx - radiusX, laserY, center.dx + radiusX, laserY + 2),
    );
    canvas.drawLine(
      Offset(center.dx - radiusX * 1.5, laserY),
      Offset(center.dx + radiusX * 1.5, laserY),
      laserPaint,
    );

    // Glowing blur behind the laser line
    final laserGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    laserGlow.shader = LinearGradient(
      colors: [
        borderColor.withValues(alpha: 0.0),
        borderColor.withValues(alpha: 0.15),
        borderColor.withValues(alpha: 0.0),
      ],
    ).createShader(
      Rect.fromLTRB(center.dx - radiusX, laserY - 2, center.dx + radiusX, laserY + 4),
    );
    canvas.drawLine(
      Offset(center.dx - radiusX * 1.5, laserY),
      Offset(center.dx + radiusX * 1.5, laserY),
      laserGlow,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HolographicBodySilhouettePainter oldDelegate) {
    return oldDelegate.pulse != pulse;
  }
}

class _OrganNetworkPainter extends CustomPainter {
  final double currentHour;
  final double pulse;
  final Color color;
  final Color subColor;
  final List<OrganCluster> organs;
  final Offset center;
  final double radiusX;
  final double doubleRadiusY;

  _OrganNetworkPainter({
    required this.currentHour,
    required this.pulse,
    required this.color,
    required this.subColor,
    required this.organs,
    required this.center,
    required this.radiusX,
    required double radiusY,
  }) : doubleRadiusY = radiusY;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);

    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final nodePaint = Paint()..style = PaintingStyle.fill;
    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);

    List<Map<String, dynamic>> allNodes = [];

    // Generate cluster nodes
    for (var organ in organs) {
      final act = organ.getActivation(currentHour);
      final cPos = Offset(
        center.dx + organ.relativePos.dx * radiusX,
        center.dy + organ.relativePos.dy * doubleRadiusY,
      );

      final int clusterSize = 7 + random.nextInt(5);

      for (int i = 0; i < clusterSize; i++) {
        final angle = random.nextDouble() * 2 * pi;
        final dist = random.nextDouble() * 32;
        final nPos = Offset(cPos.dx + cos(angle) * dist, cPos.dy + sin(angle) * dist);

        allNodes.add({
          'pos': nPos,
          'act': act,
          'color': organ.color,
        });
      }
    }

    // Draw Edges
    for (int i = 0; i < allNodes.length; i++) {
      for (int j = i + 1; j < allNodes.length; j++) {
        final pos1 = allNodes[i]['pos'] as Offset;
        final pos2 = allNodes[j]['pos'] as Offset;
        final dist = (pos1 - pos2).distance;

        if (dist < 64) {
          final act1 = allNodes[i]['act'] as double;
          final act2 = allNodes[j]['act'] as double;
          final edgeAct = (act1 + act2) / 2;
          final col1 = allNodes[i]['color'] as Color;
          final col2 = allNodes[j]['color'] as Color;

          if (edgeAct > 0.05) {
            final edgeColor = Color.lerp(col1, col2, 0.5) ?? col1;
            edgePaint.color = edgeColor.withValues(alpha: 0.15 + 0.35 * edgeAct * (0.8 + 0.2 * pulse));
            edgePaint.strokeWidth = 0.8 + 1.2 * edgeAct;
          } else {
            edgePaint.color = subColor.withValues(alpha: 0.08);
            edgePaint.strokeWidth = 0.5;
          }
          canvas.drawLine(pos1, pos2, edgePaint);
        }
      }
    }

    // Draw Nodes
    for (var node in allNodes) {
      final pos = node['pos'] as Offset;
      final act = node['act'] as double;
      final col = node['color'] as Color;

      if (act > 0.05) {
        // Glowing active node
        glowPaint.color = col.withValues(alpha: 0.5 * act * (0.8 + 0.2 * pulse));
        canvas.drawCircle(pos, 7 + 5 * act * pulse, glowPaint);

        nodePaint.color = col;
        canvas.drawCircle(pos, 2.5 + 2 * act, nodePaint);
      } else {
        // Inactive node
        nodePaint.color = col.withValues(alpha: 0.15);
        canvas.drawCircle(pos, 1.8, nodePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OrganNetworkPainter oldDelegate) {
    return oldDelegate.currentHour != currentHour || oldDelegate.pulse != pulse;
  }
}
