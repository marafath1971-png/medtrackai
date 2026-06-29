import 'dart:math';

import 'package:flutter/material.dart';
import '../../theme/med_ai_ui.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/shared/shared_widgets.dart';

class OrganCluster {
  final String name;
  final Offset relativePos;
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

class _ImpactVisualizerScreenState extends State<ImpactVisualizerScreen>
    with SingleTickerProviderStateMixin {
  double _currentHour = 0.0;
  late AnimationController _pulseController;

  final List<OrganCluster> _organs = [
    OrganCluster(
      name: 'Brain',
      relativePos: const Offset(0.0, -0.7),
      startHour: 1.0,
      peakHour: 4.0,
      endHour: 12.0,
      color: const Color(0xFF00E5FF),
    ),
    OrganCluster(
      name: 'Heart',
      relativePos: const Offset(-0.25, -0.35),
      startHour: 0.5,
      peakHour: 2.0,
      endHour: 8.0,
      color: const Color(0xFFFF3B30),
    ),
    OrganCluster(
      name: 'Digestive',
      relativePos: const Offset(0.05, -0.05),
      startHour: 0.0,
      peakHour: 1.5,
      endHour: 5.0,
      color: const Color(0xFFFF9500),
    ),
    OrganCluster(
      name: 'Liver',
      relativePos: const Offset(0.25, 0.1),
      startHour: 2.0,
      peakHour: 6.0,
      endHour: 16.0,
      color: const Color(0xFFFFD60A),
    ),
    OrganCluster(
      name: 'Kidneys',
      relativePos: const Offset(-0.2, 0.35),
      startHour: 4.0,
      peakHour: 10.0,
      endHour: 24.0,
      color: const Color(0xFFBF5AF2),
    ),
    OrganCluster(
      name: 'Muscles',
      relativePos: const Offset(0.45, 0.45),
      startHour: 3.0,
      peakHour: 8.0,
      endHour: 20.0,
      color: AppColors.accent,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!MedAiA11y.reducedMotion(context)) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.value = 0.5;
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onSliderChanged(double value) {
    setState(() => _currentHour = value);
  }

  void _onSliderChangeEnd(double value) {
    HapticEngine.selection();
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final size = MediaQuery.of(context).size;
    final center = Offset(size.width / 2, size.height / 2 - 20);
    final drawRadiusX = size.width * 0.4;
    final drawRadiusY = size.height * 0.32;
    final labelFadeDuration =
        MedAiA11y.motion(context, const Duration(milliseconds: 200));

    return AppScaffold(
      showAurora: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
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
                        Color.lerp(
                                L.bg,
                                L.text,
                                0.05 *
                                    maxAct *
                                    (0.8 + 0.2 * _pulseController.value)) ??
                            Colors.transparent,
                        L.bg,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
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
          ..._organs.map((organ) {
            final act = organ.getActivation(_currentHour);
            final pos = Offset(
              center.dx + organ.relativePos.dx * drawRadiusX,
              center.dy + organ.relativePos.dy * drawRadiusY,
            );

            final isLeft = organ.relativePos.dx < 0;
            final labelOffset =
                isLeft ? const Offset(-90, -10) : const Offset(32, -10);

            return Positioned(
              left: pos.dx + labelOffset.dx,
              top: pos.dy + labelOffset.dy,
              child: AnimatedOpacity(
                opacity: act > 0.05 ? 1.0 : 0.45,
                duration: labelFadeDuration,
                child: Semantics(
                  label: '${organ.name} ${(act * 100).toInt()} percent active',
                  child: Column(
                    crossAxisAlignment: isLeft
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        organ.name,
                        style: AppTypography.labelSmall.copyWith(
                          color: act > 0.1
                              ? organ.color
                              : L.sub.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                          fontSize: 11,
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
                          color: act > 0.1
                              ? L.text
                              : L.text.withValues(alpha: 0.5),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding, vertical: 16),
                  child: Row(
                    children: [
                      Semantics(
                        button: true,
                        label: 'Back',
                        child: AnimatedPressable(
                          onTap: () {
                            HapticEngine.selection();
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: MedAiA11y.minTapTarget,
                            height: MedAiA11y.minTapTarget,
                            decoration: BoxDecoration(
                              color: L.card.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: L.border.withValues(alpha: 0.3),
                                width: 0.5,
                              ),
                              boxShadow: AppShadows.subtle,
                            ),
                            child: Icon(Icons.arrow_back_ios_new_rounded,
                                color: L.text, size: 18),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Organ impact map',
                            style: AppTypography.titleMedium.copyWith(
                              color: L.text,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: MedAiA11y.minTapTarget),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Semantics(
                    label:
                        'Time since dose. Currently ${_currentHour.toStringAsFixed(1)} hours',
                    child: MedAiGlass(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 20),
                      radius: AppRadius.squircle,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '0h (Dose)',
                                style: AppTypography.labelSmall.copyWith(
                                  color: L.sub,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                '24h (Clearance)',
                                style: AppTypography.labelSmall.copyWith(
                                  color: L.sub,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 6,
                              activeTrackColor: L.accent,
                              inactiveTrackColor:
                                  L.text.withValues(alpha: 0.08),
                              thumbColor: Colors.white,
                              overlayColor: L.accent.withValues(alpha: 0.2),
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 12,
                                elevation: 4,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: MedAiA11y.minTapTarget / 2,
                              ),
                              trackShape: const RoundedRectSliderTrackShape(),
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
                                  color: L.sub,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${_currentHour.toStringAsFixed(1)} Hours',
                                style: AppTypography.titleMedium.copyWith(
                                  color: L.text,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

    path.addOval(Rect.fromCircle(
      center: Offset(mapX(0.5), mapY(0.1)),
      radius: radiusX * 0.28,
    ));

    path.moveTo(mapX(0.45), mapY(0.18));
    path.quadraticBezierTo(mapX(0.4), mapY(0.22), mapX(0.25), mapY(0.22));
    path.quadraticBezierTo(mapX(0.15), mapY(0.22), mapX(0.15), mapY(0.3));
    path.lineTo(mapX(0.15), mapY(0.5));
    path.quadraticBezierTo(mapX(0.15), mapY(0.55), mapX(0.2), mapY(0.55));
    path.lineTo(mapX(0.25), mapY(0.3));
    path.lineTo(mapX(0.3), mapY(0.55));
    path.lineTo(mapX(0.25), mapY(0.9));
    path.quadraticBezierTo(mapX(0.25), mapY(0.95), mapX(0.35), mapY(0.95));
    path.lineTo(mapX(0.45), mapY(0.6));
    path.quadraticBezierTo(mapX(0.5), mapY(0.55), mapX(0.55), mapY(0.6));
    path.lineTo(mapX(0.65), mapY(0.95));
    path.quadraticBezierTo(mapX(0.75), mapY(0.95), mapX(0.75), mapY(0.9));
    path.lineTo(mapX(0.7), mapY(0.55));
    path.lineTo(mapX(0.75), mapY(0.3));
    path.lineTo(mapX(0.85), mapY(0.55));
    path.quadraticBezierTo(mapX(0.9), mapY(0.55), mapX(0.9), mapY(0.5));
    path.lineTo(mapX(0.9), mapY(0.3));
    path.quadraticBezierTo(mapX(0.9), mapY(0.22), mapX(0.75), mapY(0.22));
    path.quadraticBezierTo(mapX(0.6), mapY(0.22), mapX(0.55), mapY(0.18));
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    canvas.save();
    canvas.clipPath(path);

    final gridPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const lines = 12;
    for (int i = 0; i <= lines; i++) {
      final y = mapY(i / lines);
      canvas.drawLine(
          Offset(center.dx - radiusX, y), Offset(center.dx + radiusX, y), gridPaint);
      final x = mapX(i / lines);
      canvas.drawLine(Offset(x, center.dy - radiusY * 1.2),
          Offset(x, center.dy + radiusY * 1.2), gridPaint);
    }

    canvas.restore();

    final laserY = mapY(0.08 + pulse * 0.77);
    final laserPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.save();
    canvas.clipPath(path);

    laserPaint.shader = LinearGradient(
      colors: [
        borderColor.withValues(alpha: 0.0),
        borderColor.withValues(alpha: 0.4),
        borderColor.withValues(alpha: 0.0),
      ],
    ).createShader(
      Rect.fromLTRB(center.dx - radiusX, laserY, center.dx + radiusX, laserY + 2),
    );
    canvas.drawLine(
      Offset(center.dx - radiusX * 1.5, laserY),
      Offset(center.dx + radiusX * 1.5, laserY),
      laserPaint,
    );

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
      Rect.fromLTRB(
          center.dx - radiusX, laserY - 2, center.dx + radiusX, laserY + 4),
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

    final allNodes = <Map<String, dynamic>>[];

    for (var organ in organs) {
      final act = organ.getActivation(currentHour);
      final cPos = Offset(
        center.dx + organ.relativePos.dx * radiusX,
        center.dy + organ.relativePos.dy * doubleRadiusY,
      );

      final clusterSize = 7 + random.nextInt(5);

      for (int i = 0; i < clusterSize; i++) {
        final angle = random.nextDouble() * 2 * pi;
        final dist = random.nextDouble() * 32;
        final nPos =
            Offset(cPos.dx + cos(angle) * dist, cPos.dy + sin(angle) * dist);

        allNodes.add({
          'pos': nPos,
          'act': act,
          'color': organ.color,
        });
      }
    }

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
            edgePaint.color = edgeColor
                .withValues(alpha: 0.15 + 0.35 * edgeAct * (0.8 + 0.2 * pulse));
            edgePaint.strokeWidth = 0.8 + 1.2 * edgeAct;
          } else {
            edgePaint.color = subColor.withValues(alpha: 0.08);
            edgePaint.strokeWidth = 0.5;
          }
          canvas.drawLine(pos1, pos2, edgePaint);
        }
      }
    }

    for (var node in allNodes) {
      final pos = node['pos'] as Offset;
      final act = node['act'] as double;
      final col = node['color'] as Color;

      if (act > 0.05) {
        glowPaint.color =
            col.withValues(alpha: 0.6 * act * (0.8 + 0.2 * pulse));
        glowPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 16.0);
        canvas.drawCircle(pos, 10 + 6 * act * pulse, glowPaint);

        nodePaint.color = col;
        canvas.drawCircle(pos, 3.5 + 2 * act, nodePaint);

        final corePaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.8)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos, 1.5, corePaint);
      } else {
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
