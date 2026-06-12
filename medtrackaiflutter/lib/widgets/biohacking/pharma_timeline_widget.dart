import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../../theme/app_theme.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../widgets/shared/shared_widgets.dart';

// ══════════════════════════════════════════════
// HOOK D: PHARMACOKINETICS VISUALIZER (Viral)
// Shows exactly how supplements/meds absorb into the body over time.
// ══════════════════════════════════════════════

class PharmaTimelineWidget extends StatefulWidget {
  final String medName;
  final double onsetMinutes;
  final double peakHours;
  final double durationHours;
  final List<String> targetOrgans;

  const PharmaTimelineWidget({
    super.key,
    required this.medName,
    required this.onsetMinutes,
    required this.peakHours,
    required this.durationHours,
    required this.targetOrgans,
  });

  @override
  State<PharmaTimelineWidget> createState() => _PharmaTimelineWidgetState();
}

class _PharmaTimelineWidgetState extends State<PharmaTimelineWidget> {
  double _timeScrubber = 0.0; // 0 to 24 hours
  final GlobalKey _boundaryKey = GlobalKey();

  Color _getCurrentPhaseColor(AppThemeColors L) {
    if (_timeScrubber < (widget.onsetMinutes / 60)) {
      return L.sub; // Not active yet
    } else if (_timeScrubber < widget.peakHours) {
      return AppColors.limeAccent; // Absorbing / Building up
    } else if (_timeScrubber < widget.durationHours) {
      return const Color(0xFF00E5FF); // Peak Flow State (Cyan)
    } else {
      return const Color(0xFFFF3D00); // Metabolizing out (Red/Orange)
    }
  }

  String _getCurrentPhaseText() {
    if (_timeScrubber == 0) return 'Pre-dose';
    if (_timeScrubber < (widget.onsetMinutes / 60)) return 'Absorbing in stomach';
    if (_timeScrubber < widget.peakHours) return 'Building in bloodstream';
    if (_timeScrubber < widget.durationHours) return 'Peak therapeutic window';
    return 'Metabolizing out';
  }

  Future<void> _shareViralScreenshot(AppThemeColors L) async {
    HapticEngine.heavyImpact();
    
    // Show a quick loading toast
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Generating biohacking share card...'),
        backgroundColor: AppColors.limeAccent.withValues(alpha: 0.2),
        duration: const Duration(milliseconds: 1500),
      ),
    );

    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/med_ai_biohack.png');
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: '🧬 Engineered my stack: ${widget.medName}\nPeak focus unlocked at hour ${widget.peakHours}.\n\n#MedAI #Biohacking #FlowState',
        ),
      );
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final phaseColor = _getCurrentPhaseColor(L);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shareable Render Boundary
        RepaintBoundary(
          key: _boundaryKey,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black, // True black for AMOLED
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: phaseColor.withValues(alpha: 0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: phaseColor.withValues(alpha: 0.15),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PHARMACOKINETICS',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.5),
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.medName.toUpperCase(),
                          style: AppTypography.titleLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: phaseColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: phaseColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        _timeScrubber == 0 ? 'T-0:00' : 'T+${_timeScrubber.toStringAsFixed(1)} HR',
                        style: AppTypography.labelMedium.copyWith(
                          color: phaseColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // The Wave Chart Visualizer
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _PharmacokineticsWavePainter(
                      currentTime: _timeScrubber,
                      onset: widget.onsetMinutes / 60,
                      peak: widget.peakHours,
                      duration: widget.durationHours,
                      activeColor: phaseColor,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Dynamic Status Text
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: phaseColor,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.glow(phaseColor, intensity: 0.5),
                        ),
                      ).animate(target: _timeScrubber > 0 ? 1 : 0).shimmer(duration: 1.seconds, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getCurrentPhaseText(),
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Target Organs Glowing Tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.targetOrgans.map((organ) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _timeScrubber > (widget.onsetMinutes/60) 
                          ? phaseColor.withValues(alpha: 0.15) 
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _timeScrubber > (widget.onsetMinutes/60) 
                            ? phaseColor.withValues(alpha: 0.3) 
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      organ.toUpperCase(),
                      style: AppTypography.labelSmall.copyWith(
                        color: _timeScrubber > (widget.onsetMinutes/60) 
                            ? phaseColor 
                            : Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Scrubber Slider (Not part of the shareable image)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TIME SIMULATOR',
                style: AppTypography.labelSmall.copyWith(
                  color: L.sub.withValues(alpha: 0.5),
                  letterSpacing: 1.5,
                ),
              ),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: phaseColor,
                  inactiveTrackColor: L.border.withValues(alpha: 0.2),
                  thumbColor: Colors.white,
                  overlayColor: phaseColor.withValues(alpha: 0.2),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _timeScrubber,
                  min: 0,
                  max: 24, // 24 hour simulation
                  onChanged: (val) {
                    setState(() => _timeScrubber = val);
                    if (val > 0 && val < 0.5) HapticEngine.selection(); // Taptic feedback at start
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0h', style: AppTypography.labelSmall.copyWith(color: L.sub)),
                  Text('Peak', style: AppTypography.labelSmall.copyWith(color: phaseColor)),
                  Text('24h', style: AppTypography.labelSmall.copyWith(color: L.sub)),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Share Button Hook
        BouncingButton(
          onTap: () => _shareViralScreenshot(L),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.ios_share_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Share Stack Visualization',
                  style: AppTypography.labelLarge.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════
// CUSTOM PAINTER: Smooth Pharmacokinetics Wave
// ══════════════════════════════════════════════
class _PharmacokineticsWavePainter extends CustomPainter {
  final double currentTime; // 0 to 24
  final double onset;       // hours
  final double peak;        // hours
  final double duration;    // hours
  final Color activeColor;

  _PharmacokineticsWavePainter({
    required this.currentTime,
    required this.onset,
    required this.peak,
    required this.duration,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    
    // Map 24 hours to width
    double xForTime(double t) => (t / 24) * width;
    
    final path = Path();
    path.moveTo(0, height);
    
    // Calculate blood concentration curve
    // We use a skewed bell curve to simulate rapid absorption and slow elimination
    for (double i = 0; i <= width; i++) {
      double t = (i / width) * 24; // convert pixel x to hours
      
      double y = height;
      if (t >= onset) {
        if (t <= peak) {
          // Ascending phase (rapid)
          double progress = (t - onset) / (peak - onset);
          y = height - (height * math.sin(progress * (math.pi / 2)));
        } else if (t <= duration) {
          // Elimination phase (exponential decay)
          double progress = (t - peak) / (duration - peak);
          y = height - (height * math.pow(1 - progress, 2));
        }
      }
      
      path.lineTo(i, y);
    }

    // Background track line
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, trackPaint);

    // Active fill gradient up to current time
    final activeX = xForTime(currentTime);
    final clipRect = Rect.fromLTRB(0, 0, activeX, height);
    
    canvas.save();
    canvas.clipRect(clipRect);
    
    // Gradient fill below curve
    final fillPath = Path.from(path)
      ..lineTo(activeX, height)
      ..lineTo(0, height)
      ..close();
      
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          activeColor.withValues(alpha: 0.6),
          activeColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height));
      
    canvas.drawPath(fillPath, fillPaint);
    
    // Active glowing line
    final linePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
      
    canvas.drawPath(path, linePaint);
    canvas.restore();
    
    // Draw current time marker (the glowing dot)
    if (currentTime > 0) {
      // Find y position at current time
      double t = currentTime;
      double markerY = height;
      if (t >= onset) {
        if (t <= peak) {
          double progress = (t - onset) / (peak - onset);
          markerY = height - (height * math.sin(progress * (math.pi / 2)));
        } else if (t <= duration) {
          double progress = (t - peak) / (duration - peak);
          markerY = height - (height * math.pow(1 - progress, 2));
        }
      }
      
      canvas.drawCircle(
        Offset(activeX, markerY), 
        6, 
        Paint()..color = Colors.white
      );
      
      canvas.drawCircle(
        Offset(activeX, markerY), 
        14, 
        Paint()..color = activeColor.withValues(alpha: 0.4)
      );
    }
    
    // Draw X-axis markers
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    
    void drawLabel(String text, double x) {
      textPainter.text = TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - (textPainter.width / 2), height + 4));
    }
    
    drawLabel('0h', 0);
    drawLabel('12h', width / 2);
    drawLabel('24h', width);
  }

  @override
  bool shouldRepaint(_PharmacokineticsWavePainter old) {
    return old.currentTime != currentTime || old.activeColor != activeColor;
  }
}
