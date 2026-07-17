import 'dart:ui' as ui;
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';
import '../../services/growth_tracker.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

class _PharmaTimelineWidgetState extends State<PharmaTimelineWidget>
    with SingleTickerProviderStateMixin {
  double _currentTime = 0.0; // 0 to 24 hours
  bool _recordMode = false;
  bool _revealMedName = false;
  bool _isPlaying = false;
  Timer? _playbackTimer;
  String? _selectedOrganTooltip;
  
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _glowController.dispose();
    super.dispose();
  }

  // Calculate drug concentration based on pharmacokinetic parameters
  double _calculateConcentration(double timeHours) {
    if (widget.durationHours <= 0) return 0.0;
    
    final onsetHours = widget.onsetMinutes / 60.0;
    final peak = widget.peakHours;
    final duration = widget.durationHours;

    if (timeHours < onsetHours) {
      return 0.0;
    } else if (timeHours >= onsetHours && timeHours < peak) {
      // Rise phase (linear interpolation from 0 to 1.0)
      if (peak == onsetHours) return 1.0;
      return (timeHours - onsetHours) / (peak - onsetHours);
    } else if (timeHours >= peak && timeHours < duration) {
      // Decay phase (decaying down to 0.1)
      if (duration == peak) return 0.0;
      return 1.0 - 0.9 * ((timeHours - peak) / (duration - peak));
    } else {
      // Residual concentration (exponential decay)
      final timeSinceDuration = timeHours - duration;
      return 0.1 * math.exp(-timeSinceDuration / 4.0);
    }
  }

  void _togglePlayback() {
    HapticEngine.selection();
    if (_isPlaying) {
      _playbackTimer?.cancel();
      setState(() => _isPlaying = false);
    } else {
      setState(() {
        _isPlaying = true;
        if (_currentTime >= 24.0) _currentTime = 0.0;
      });
      _playbackTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        setState(() {
          _currentTime += 0.5;
          if (_currentTime >= 24.0) {
            _currentTime = 24.0;
            _isPlaying = false;
            _playbackTimer?.cancel();
          }
        });
      });
    }
  }

  void _triggerRecordModePlay() {
    HapticEngine.medium();
    GrowthTracker.trackFeatureUsed('record_mode');
    setState(() {
      _recordMode = true;
      _revealMedName = false;
      _currentTime = 0.0;
      _isPlaying = true;
    });
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      setState(() {
        _currentTime += 0.5;
        if (_currentTime >= 24.0) {
          _currentTime = 24.0;
          _isPlaying = false;
          _playbackTimer?.cancel();
        }
      });
    });
  }

  // Map user input targetOrgans to visual categories
  Set<String> _getActiveOrgans() {
    final Set<String> active = {};
    for (var org in widget.targetOrgans) {
      final o = org.toLowerCase();
      if (o.contains('brain') || o.contains('nervous') || o.contains('cognitive')) {
        active.add('brain');
      }
      if (o.contains('heart') || o.contains('cardio') || o.contains('vascular')) {
        active.add('heart');
      }
      if (o.contains('stomach') || o.contains('digestive') || o.contains('gut') || o.contains('gastro')) {
        active.add('stomach');
      }
      if (o.contains('liver') || o.contains('hepatic') || o.contains('metabol')) {
        active.add('liver');
      }
      if (o.contains('kidney') || o.contains('renal') || o.contains('urinary')) {
        active.add('kidneys');
      }
      if (o.contains('blood') || o.contains('circulat') || o.contains('systemic')) {
        active.add('bloodstream');
      }
    }
    return active;
  }

  Widget _buildBlurredMedName(AppThemeColors L) {
    return GestureDetector(
      onTap: () {
        HapticEngine.selection();
        setState(() => _revealMedName = !_revealMedName);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              widget.medName,
              style: AppTypography.titleMedium.copyWith(
                color: L.text,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!_revealMedName)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.1),
                    child: const Center(
                      child: Text(
                        'Tap to reveal',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataPlaceholder(AppThemeColors L) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: L.fill.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: L.border.withValues(alpha: 0.08)),
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
                  Container(
                    height: 12,
                    width: 140,
                    decoration: BoxDecoration(color: L.sub.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 18,
                    width: 100,
                    decoration: BoxDecoration(color: L.sub.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                  ),
                ],
              ),
            ],
          ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 1500.ms, color: L.sub.withValues(alpha: 0.1)),
          const SizedBox(height: 32),
          Center(
            child: Container(
              width: 200,
              height: 260,
              decoration: BoxDecoration(
                color: L.sub.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 1500.ms, color: L.sub.withValues(alpha: 0.1)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    
    // Check if pharmacokinetic data is valid/present
    if (widget.durationHours <= 0) {
      return _buildNoDataPlaceholder(L);
    }

    final activeOrgans = _getActiveOrgans();
    final double currentConcentration = _calculateConcentration(_currentTime);

    // Compute glow intensity per organ
    final Map<String, double> organGlows = {};
    for (var org in ['brain', 'heart', 'stomach', 'liver', 'kidneys', 'bloodstream']) {
      if (activeOrgans.contains(org)) {
        organGlows[org] = currentConcentration * (0.8 + 0.2 * _glowController.value);
      } else {
        organGlows[org] = 0.0;
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _recordMode ? Colors.black : L.fill.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _recordMode ? Colors.white10 : L.border.withValues(alpha: 0.08),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row (Chrome)
          if (!_recordMode) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bioimpact timeline',
                      style: AppTypography.labelMedium.copyWith(
                        color: L.sub,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.medName,
                      style: AppTypography.titleMedium.copyWith(
                        color: L.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Buttons
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.videocam_rounded),
                      color: L.sub,
                      onPressed: _triggerRecordModePlay,
                      tooltip: 'Record Mode',
                    ),
                    IconButton(
                      icon: Icon(_isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded),
                      color: L.sub,
                      onPressed: _togglePlayback,
                      tooltip: _isPlaying ? 'Pause' : 'Play',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
          ] else ...[
            // Record Mode Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBlurredMedName(L),
                TextButton.icon(
                  onPressed: () => setState(() => _recordMode = false),
                  icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white60),
                  label: const Text('Exit Record Mode', style: TextStyle(color: Colors.white60, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // Body Silhouette View
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 260,
                  child: CustomPaint(
                    painter: SilhouettePainter(
                      organGlows: organGlows,
                      activeOrgans: activeOrgans,
                      kidneyGlow: L.success,
                    ),
                  ),
                ),

                // Interactive Positioned Organ Taps
                if (!_recordMode) ...[
                  // Brain (x: 100, y: 70)
                  if (activeOrgans.contains('brain'))
                    Positioned(
                      top: 55,
                      left: 85,
                      child: _buildOrganTapTarget('Brain', 'Cognitive center. Regulates systemic autonomic safety.', L),
                    ),
                  // Heart (x: 95, y: 110)
                  if (activeOrgans.contains('heart'))
                    Positioned(
                      top: 95,
                      left: 80,
                      child: _buildOrganTapTarget('Heart', 'Cardiovascular engine. Drives cellular delivery.', L),
                    ),
                  // Stomach (x: 100, y: 132)
                  if (activeOrgans.contains('stomach'))
                    Positioned(
                      top: 118,
                      left: 85,
                      child: _buildOrganTapTarget('Stomach', 'Absorption gateway. Drives initial bioavailability.', L),
                    ),
                  // Liver (x: 92, y: 127)
                  if (activeOrgans.contains('liver'))
                    Positioned(
                      top: 115,
                      left: 77,
                      child: _buildOrganTapTarget('Liver', 'Metabolic refinery. Handles drug clearance rates.', L),
                    ),
                  // Kidneys (x: 92, 108, y: 142)
                  if (activeOrgans.contains('kidneys'))
                    Positioned(
                      top: 130,
                      left: 80,
                      child: _buildOrganTapTarget('Kidneys', 'Renal filtration system. Manages drug excretion.', L),
                    ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Timeline Scrubber
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0h (Onset)', style: TextStyle(color: L.sub.withValues(alpha: 0.5), fontSize: 11)),
                  Text(
                    'Time: ${_currentTime.toStringAsFixed(1)}h',
                    style: TextStyle(color: L.text, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text('24h (Residual)', style: TextStyle(color: L.sub.withValues(alpha: 0.5), fontSize: 11)),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: L.secondary,
                  inactiveTrackColor: L.border.withValues(alpha: 0.2),
                  thumbColor: L.secondary,
                  overlayColor: L.secondary.withValues(alpha: 0.15),
                  trackHeight: 3.0,
                ),
                child: Slider(
                  value: _currentTime,
                  min: 0.0,
                  max: 24.0,
                  onChanged: (val) {
                    _playbackTimer?.cancel();
                    setState(() {
                      _isPlaying = false;
                      _currentTime = val;
                    });
                  },
                ),
              ),
            ],
          ),

          // Tooltip display
          if (_selectedOrganTooltip != null && !_recordMode) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: L.fill.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: L.border.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'General Information Tag',
                        style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      Semantics(
                        button: true,
                        label: 'Dismiss organ info',
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedOrganTooltip = null),
                          child: Icon(Icons.close_rounded,
                              size: 14, color: L.sub),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(_selectedOrganTooltip!, style: AppTypography.bodySmall.copyWith(color: L.text)),
                  const SizedBox(height: 6),
                  const Text(
                    'Disclaimer: Visualizer is for educational purposes and maps standard pharmacokinetics. Seek medical advice for personalized biology.',
                    style: TextStyle(color: Colors.white24, fontSize: 9, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrganTapTarget(String name, String info, AppThemeColors L) {
    return GestureDetector(
      onTap: () {
        HapticEngine.selection();
        setState(() {
          _selectedOrganTooltip = '$name: $info';
        });
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class SilhouettePainter extends CustomPainter {
  final Map<String, double> organGlows;
  final Set<String> activeOrgans;
  final Color kidneyGlow;

  SilhouettePainter({
    required this.organGlows,
    required this.activeOrgans,
    required this.kidneyGlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paintBody = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final paintStroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Draw stylized head, torso, limbs
    // Head:
    canvas.drawCircle(Offset(center.dx, center.dy - 60), 16, paintBody);
    canvas.drawCircle(Offset(center.dx, center.dy - 60), 16, paintStroke);

    // Torso:
    final torsoPath = Path()
      ..moveTo(center.dx - 22, center.dy - 35)
      ..lineTo(center.dx + 22, center.dy - 35)
      ..lineTo(center.dx + 18, center.dy + 25)
      ..lineTo(center.dx - 18, center.dy + 25)
      ..close();
    canvas.drawPath(torsoPath, paintBody);
    canvas.drawPath(torsoPath, paintStroke);

    // Arms:
    final armL = Path()
      ..moveTo(center.dx - 22, center.dy - 35)
      ..lineTo(center.dx - 36, center.dy + 15);
    final armR = Path()
      ..moveTo(center.dx + 22, center.dy - 35)
      ..lineTo(center.dx + 36, center.dy + 15);
    
    final Paint armPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(armL, armPaint);
    canvas.drawPath(armR, armPaint);

    // Legs:
    final legPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx - 10, center.dy + 25), Offset(center.dx - 12, center.dy + 80), legPaint);
    canvas.drawLine(Offset(center.dx + 10, center.dy + 25), Offset(center.dx + 12, center.dy + 80), legPaint);

    // Draw glowing zones for active organs
    void drawGlow(Offset pos, double radius, Color color, double intensity) {
      if (intensity <= 0) return;
      final glowPaint = Paint()
        ..color = color.withValues(alpha: intensity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(pos, radius + 8, glowPaint);

      final corePaint = Paint()
        ..color = color.withValues(alpha: intensity * 0.8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, radius, corePaint);
    }

    if (activeOrgans.contains('brain')) {
      drawGlow(Offset(center.dx, center.dy - 60), 6, const Color(0xFF00FFCC), organGlows['brain'] ?? 0);
    }
    if (activeOrgans.contains('heart')) {
      drawGlow(Offset(center.dx - 5, center.dy - 20), 5, const Color(0xFFFF3B30), organGlows['heart'] ?? 0);
    }
    if (activeOrgans.contains('stomach')) {
      drawGlow(Offset(center.dx, center.dy + 2), 6, const Color(0xFFFFCC00), organGlows['stomach'] ?? 0);
    }
    if (activeOrgans.contains('liver')) {
      drawGlow(Offset(center.dx - 8, center.dy - 3), 5, const Color(0xFFFF9500), organGlows['liver'] ?? 0);
    }
    if (activeOrgans.contains('kidneys')) {
      drawGlow(Offset(center.dx - 8, center.dy + 12), 4, kidneyGlow, organGlows['kidneys'] ?? 0);
      drawGlow(Offset(center.dx + 8, center.dy + 12), 4, kidneyGlow, organGlows['kidneys'] ?? 0);
    }
    if (activeOrgans.contains('bloodstream')) {
      final outlineGlow = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: (organGlows['bloodstream'] ?? 0) * 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(center.dx, center.dy - 60), 16, outlineGlow);
      canvas.drawPath(torsoPath, outlineGlow);
    }
  }

  @override
  bool shouldRepaint(covariant SilhouettePainter oldDelegate) {
    return true;
  }
}
