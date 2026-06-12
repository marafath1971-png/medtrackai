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
// HOOK D: PHARMACOKINETICS VISUALIZER (Viral / Biohacking)
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

class _PharmaTimelineWidgetState extends State<PharmaTimelineWidget> with SingleTickerProviderStateMixin {
  double _timeScrubber = 0.0; // 0 to 24 hours
  final GlobalKey _boundaryKey = GlobalKey();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  String? _selectedOrgan;
  bool _isCinematicMode = false;
  double? _lastSnappedPoint;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getInterpolatedColor(double t) {
    final onsetHrs = widget.onsetMinutes / 60.0;
    final peakHrs = widget.peakHours;
    final durHrs = widget.durationHours;

    // Smooth Yellow (Onset) -> Green (Peak) -> Red (Wear Off) Interpolation
    const colorInactive = Color(0xFF94A3B8); // Slate 400
    const colorOnset = Color(0xFFFBBF24);    // Amber/Yellow
    const colorPeak = Color(0xFF10B981);     // Emerald/Green
    const colorWearOff = Color(0xFFEF4444);  // Rose/Red

    if (t < onsetHrs) {
      final double ratio = onsetHrs > 0 ? t / onsetHrs : 0.0;
      return Color.lerp(colorInactive, colorOnset, ratio) ?? colorOnset;
    } else if (t < peakHrs) {
      final double ratio = (peakHrs - onsetHrs) > 0 ? (t - onsetHrs) / (peakHrs - onsetHrs) : 0.0;
      return Color.lerp(colorOnset, colorPeak, ratio) ?? colorPeak;
    } else if (t < durHrs) {
      final double ratio = (durHrs - peakHrs) > 0 ? (t - peakHrs) / (durHrs - peakHrs) : 0.0;
      return Color.lerp(colorPeak, colorWearOff, ratio) ?? colorWearOff;
    } else {
      final double ratio = (24.0 - durHrs) > 0 ? (t - durHrs) / (24.0 - durHrs) : 0.0;
      return Color.lerp(colorWearOff, colorInactive, ratio.clamp(0.0, 1.0)) ?? colorInactive;
    }
  }

  String _getCurrentPhaseText() {
    if (_timeScrubber == 0) return 'Pre-dose';
    if (_timeScrubber < (widget.onsetMinutes / 60)) return 'Absorbing in stomach';
    if (_timeScrubber < widget.peakHours) return 'Building in bloodstream';
    if (_timeScrubber < widget.durationHours) return 'Peak therapeutic window';
    return 'Metabolizing out';
  }

  void _updateScrubber(double val) {
    final onsetHrs = widget.onsetMinutes / 60.0;
    final peakHrs = widget.peakHours;
    final durHrs = widget.durationHours;

    // Magnetic Snap Points
    final snaps = [0.0, onsetHrs, peakHrs, durHrs, 24.0];
    const snapThreshold = 0.4; // Magnetic force field radius

    double finalVal = val;
    double? matchedSnap;
    for (final snap in snaps) {
      if ((val - snap).abs() < snapThreshold) {
        finalVal = snap;
        matchedSnap = snap;
        break;
      }
    }

    if (finalVal != _timeScrubber) {
      if (matchedSnap != null && _lastSnappedPoint != matchedSnap) {
        HapticEngine.selection();
        _lastSnappedPoint = matchedSnap;
      } else if (matchedSnap == null) {
        _lastSnappedPoint = null;
      }
      setState(() {
        _timeScrubber = finalVal;
      });
    }
  }

  List<OrganDef> _getActiveOrgans() {
    final active = <OrganDef>[];
    final med = widget.medName.toLowerCase();
    
    for (final organ in widget.targetOrgans) {
      final name = organ.trim();
      final lower = name.toLowerCase();
      
      if (lower.contains('brain')) {
        active.add(OrganDef(
          name: name,
          emoji: '🧠',
          dx: 0.5,
          dy: 0.12,
          impactText: _getOrganImpact(med, 'brain'),
        ));
      } else if (lower.contains('heart') || lower.contains('cardio')) {
        active.add(OrganDef(
          name: name,
          emoji: '🫀',
          dx: 0.46,
          dy: 0.31,
          impactText: _getOrganImpact(med, 'heart'),
        ));
      } else if (lower.contains('stomach') || lower.contains('digest')) {
        active.add(OrganDef(
          name: name,
          emoji: '🥣',
          dx: 0.54,
          dy: 0.39,
          impactText: _getOrganImpact(med, 'stomach'),
        ));
      } else if (lower.contains('liver') || lower.contains('hepat')) {
        active.add(OrganDef(
          name: name,
          emoji: '🩸',
          dx: 0.43,
          dy: 0.39,
          impactText: _getOrganImpact(med, 'liver'),
        ));
      } else if (lower.contains('kidney') || lower.contains('renal')) {
        active.add(OrganDef(
          name: name,
          emoji: '🫘',
          dx: 0.5,
          dy: 0.45,
          impactText: _getOrganImpact(med, 'kidney'),
        ));
      } else if (lower.contains('lung') || lower.contains('respir')) {
        active.add(OrganDef(
          name: name,
          emoji: '🫁',
          dx: 0.5,
          dy: 0.28,
          impactText: _getOrganImpact(med, 'lung'),
        ));
      } else if (lower.contains('nervous') || lower.contains('neural')) {
        active.add(OrganDef(
          name: name,
          emoji: '⚡',
          dx: 0.5,
          dy: 0.22,
          impactText: _getOrganImpact(med, 'nervous'),
        ));
      }
    }
    return active;
  }

  String _getOrganImpact(String med, String organ) {
    if (med.contains('aspirin') || med.contains('advil') || med.contains('ibuprofen')) {
      if (organ == 'stomach') return "Inhibits COX-1 enzymes, reducing protective stomach mucus. Take with food.";
      if (organ == 'brain') return "Blocks prostaglandin synthesis in the brain to reduce pain and fever signals.";
      if (organ == 'heart') return "At low doses, inhibits platelet aggregation, thinning blood to protect coronary arteries.";
      if (organ == 'kidney') return "Reduces renal blood flow; monitor hydration to prevent filtration strain.";
    }
    if (med.contains('caffeine') || med.contains('coffee') || med.contains('theanine') || med.contains('energy')) {
      if (organ == 'brain') return "Blocks adenosine receptors, triggering release of dopamine & norepinephrine for peak focus.";
      if (organ == 'heart') return "Mild vasoconstriction & catecholamine release, temporarily raising heart rate.";
      if (organ == 'stomach') return "Stimulates gastric acid secretion, accelerating overall digestive transit.";
    }
    switch (organ) {
      case 'brain':
        return "Cellular receptors targeted. Modulates neurotransmitter release for target therapeutic outcome.";
      case 'heart':
        return "Systemic blood flow modulation. Balances cardiovascular strain and targets vascular wall receptors.";
      case 'stomach':
        return "Primary dissolution site. Active compound enters mucosal barrier to begin absorption.";
      case 'liver':
        return "First-pass hepatic clearance. Enzymes metabolize molecules into active clinical agents.";
      case 'kidney':
        return "Renal filtration pathway. Regulates compound excretion rates over the 24h cycle.";
      case 'lung':
        return "Oxygenation efficiency. Promotes airway passage comfort or vascular dilation.";
      case 'nervous':
        return "Neural synapse moderation. Stabilizes signal conduction velocity across nerve tracts.";
      default:
        return "Direct metabolic activation. Supports targeted cellular physiological response.";
    }
  }

  void _enterCinematicMode() {
    HapticEngine.heavyImpact();
    setState(() {
      _isCinematicMode = true;
      // Slow down breathing pulse animation for recording
      _pulseController.duration = const Duration(milliseconds: 3000);
      _pulseController.repeat(reverse: true);
    });

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        barrierColor: Colors.black,
        pageBuilder: (context, _, __) {
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              final interpolatedColor = _getInterpolatedColor(_timeScrubber);
              final activeOrgans = _getActiveOrgans();
              
              return Scaffold(
                backgroundColor: Colors.black,
                body: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      children: [
                        // Cinematic Minimal Header (No Personal Info)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PHARMACOKINETICS VISUALIZER',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    letterSpacing: 2,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
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
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 24),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Large body view
                        Expanded(
                          child: Center(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Stack(
                                  alignment: Alignment.center,
                                  clipBehavior: Clip.none,
                                  children: [
                                    CustomPaint(
                                      size: Size(constraints.maxWidth, constraints.maxHeight),
                                      painter: _HumanBodyWireframePainter(color: interpolatedColor),
                                    ),
                                    ...activeOrgans.map((organ) {
                                      final isSelected = _selectedOrgan == organ.name;
                                      return Positioned(
                                        left: organ.dx * constraints.maxWidth - 24,
                                        top: organ.dy * constraints.maxHeight - 24,
                                        child: GestureDetector(
                                          onTap: () {
                                            HapticEngine.selection();
                                            setStateDialog(() {
                                              _selectedOrgan = isSelected ? null : organ.name;
                                            });
                                            setState(() {});
                                          },
                                          child: AnimatedBuilder(
                                            animation: _pulseAnimation,
                                            builder: (context, child) {
                                              final double pulse = _pulseAnimation.value;
                                              return Container(
                                                width: 48,
                                                height: 48,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: isSelected
                                                      ? interpolatedColor.withValues(alpha: 0.3)
                                                      : interpolatedColor.withValues(alpha: 0.15 * pulse),
                                                  border: Border.all(
                                                    color: isSelected ? Colors.white : interpolatedColor.withValues(alpha: 0.8),
                                                    width: isSelected ? 2.5 : 1.5,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: interpolatedColor.withValues(alpha: 0.4 * pulse),
                                                      blurRadius: (isSelected ? 16 : 8) * pulse,
                                                    )
                                                  ],
                                                ),
                                                child: Text(
                                                  organ.emoji,
                                                  style: const TextStyle(fontSize: 24),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        if (_selectedOrgan != null) ...[
                          _buildSelectedOrganTooltip(
                            activeOrgans.firstWhere((o) => o.name == _selectedOrgan),
                            interpolatedColor,
                            onClose: () {
                              setStateDialog(() {
                                _selectedOrgan = null;
                              });
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                        // Wave Chart
                        SizedBox(
                          height: 100,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _PharmacokineticsWavePainter(
                              currentTime: _timeScrubber,
                              onset: widget.onsetMinutes / 60,
                              peak: widget.peakHours,
                              duration: widget.durationHours,
                              activeColor: interpolatedColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Scrubber Slider
                        Column(
                          children: [
                            SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: interpolatedColor,
                                inactiveTrackColor: Colors.white24,
                                thumbColor: Colors.white,
                                overlayColor: interpolatedColor.withValues(alpha: 0.2),
                                trackHeight: 4,
                              ),
                              child: Slider(
                                value: _timeScrubber,
                                min: 0,
                                max: 24,
                                onChanged: (val) {
                                  setStateDialog(() {
                                    _updateScrubber(val);
                                  });
                                  setState(() {});
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _timeScrubber == 0 ? 'T-0:00' : 'T+${_timeScrubber.toStringAsFixed(1)} HR',
                                    style: AppTypography.labelMedium.copyWith(color: interpolatedColor, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    _getCurrentPhaseText(),
                                    style: AppTypography.labelMedium.copyWith(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Small footnote
                        Text(
                          'educational visualization, not medical advice',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    ).then((_) {
      setState(() {
        _isCinematicMode = false;
        // Restore standard breathing pulse duration
        _pulseController.duration = const Duration(milliseconds: 1500);
        _pulseController.repeat(reverse: true);
      });
    });
  }

  Widget _buildSelectedOrganTooltip(OrganDef organ, Color color, {required VoidCallback onClose}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(organ.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  organ.name.toUpperCase(),
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  organ.impactText,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white60, size: 16),
            onPressed: onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Future<void> _shareViralScreenshot(AppThemeColors L) async {
    HapticEngine.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Generating biohacking share card...'),
        backgroundColor: L.secondary.withValues(alpha: 0.2),
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
    final interpolatedColor = _getInterpolatedColor(_timeScrubber);
    final activeOrgans = _getActiveOrgans();

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
              border: Border.all(color: interpolatedColor.withValues(alpha: 0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: interpolatedColor.withValues(alpha: 0.15),
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
                        color: interpolatedColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: interpolatedColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        _timeScrubber == 0 ? 'T-0:00' : 'T+${_timeScrubber.toStringAsFixed(1)} HR',
                        style: AppTypography.labelMedium.copyWith(
                          color: interpolatedColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),

                // Interactive Body Visualizer (New Feature)
                SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          CustomPaint(
                            size: Size(constraints.maxWidth, constraints.maxHeight),
                            painter: _HumanBodyWireframePainter(color: interpolatedColor),
                          ),
                          ...activeOrgans.map((organ) {
                            final isSelected = _selectedOrgan == organ.name;
                            return Positioned(
                              left: organ.dx * constraints.maxWidth - 20,
                              top: organ.dy * constraints.maxHeight - 20,
                              child: GestureDetector(
                                onTap: () {
                                  HapticEngine.selection();
                                  setState(() {
                                    _selectedOrgan = isSelected ? null : organ.name;
                                  });
                                },
                                child: AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, child) {
                                    final double pulse = _pulseAnimation.value;
                                    return Container(
                                      width: 40,
                                      height: 40,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? interpolatedColor.withValues(alpha: 0.3)
                                            : interpolatedColor.withValues(alpha: 0.15 * pulse),
                                        border: Border.all(
                                          color: isSelected ? Colors.white : interpolatedColor.withValues(alpha: 0.8),
                                          width: isSelected ? 2.0 : 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: interpolatedColor.withValues(alpha: 0.4 * pulse),
                                            blurRadius: (isSelected ? 12 : 8) * pulse,
                                          )
                                        ],
                                      ),
                                      child: Text(
                                        organ.emoji,
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),

                if (_selectedOrgan != null) ...[
                  const SizedBox(height: 12),
                  _buildSelectedOrganTooltip(
                    activeOrgans.firstWhere((o) => o.name == _selectedOrgan),
                    interpolatedColor,
                    onClose: () => setState(() => _selectedOrgan = null),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // The Wave Chart Visualizer
                SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _PharmacokineticsWavePainter(
                      currentTime: _timeScrubber,
                      onset: widget.onsetMinutes / 60,
                      peak: widget.peakHours,
                      duration: widget.durationHours,
                      activeColor: interpolatedColor,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
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
                          color: interpolatedColor,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.glow(interpolatedColor, intensity: 0.5),
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
                  children: activeOrgans.map((organ) {
                    final isSelected = _selectedOrgan == organ.name;
                    return GestureDetector(
                      onTap: () {
                        HapticEngine.selection();
                        setState(() {
                          _selectedOrgan = isSelected ? null : organ.name;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _timeScrubber > (widget.onsetMinutes/60) 
                              ? interpolatedColor.withValues(alpha: isSelected ? 0.35 : 0.15) 
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _timeScrubber > (widget.onsetMinutes/60) 
                                ? (isSelected ? Colors.white : interpolatedColor.withValues(alpha: 0.3)) 
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          organ.name.toUpperCase(),
                          style: AppTypography.labelSmall.copyWith(
                            color: _timeScrubber > (widget.onsetMinutes/60) 
                                ? (isSelected ? Colors.white : interpolatedColor) 
                                : Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Scrubber Slider (Not part of the shareable image)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TIME SIMULATOR',
                    style: AppTypography.labelSmall.copyWith(
                      color: L.sub.withValues(alpha: 0.5),
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'Snaps to phases',
                    style: AppTypography.labelSmall.copyWith(
                      color: L.sub.withValues(alpha: 0.3),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: interpolatedColor,
                  inactiveTrackColor: L.border.withValues(alpha: 0.2),
                  thumbColor: Colors.white,
                  overlayColor: interpolatedColor.withValues(alpha: 0.2),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _timeScrubber,
                  min: 0,
                  max: 24, // 24 hour simulation
                  onChanged: _updateScrubber,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0h', style: AppTypography.labelSmall.copyWith(color: L.sub)),
                  Text('Active Effect Phase', style: AppTypography.labelSmall.copyWith(color: interpolatedColor)),
                  Text('24h', style: AppTypography.labelSmall.copyWith(color: L.sub)),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),

        // Disclaimer Footnote
        Center(
          child: Text(
            'educational visualization, not medical advice',
            style: AppTypography.labelSmall.copyWith(
              color: L.sub.withValues(alpha: 0.3),
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Control Row: Cinematic Mode & Share Button
        Row(
          children: [
            Expanded(
              child: BouncingButton(
                onTap: _enterCinematicMode,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: interpolatedColor.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(color: interpolatedColor.withValues(alpha: 0.1), blurRadius: 10)
                    ]
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.movie_creation_outlined, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Cinematic Mode',
                        style: AppTypography.labelLarge.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BouncingButton(
                onTap: () => _shareViralScreenshot(L),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: L.border.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.ios_share_rounded, color: L.text, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Share Visual',
                        style: AppTypography.labelLarge.copyWith(color: L.text),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════
// CUSTOM PAINTER: Stylized Vector Human Body Contour
// ══════════════════════════════════════════════
class _HumanBodyWireframePainter extends CustomPainter {
  final Color color;
  _HumanBodyWireframePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5;

    final path = Path();
    final w = size.width;
    final h = size.height;

    // Stylized wireframe body model:
    // Head: Circle at top
    final headCenter = Offset(w / 2, h * 0.12);
    final headRadius = h * 0.055;
    canvas.drawCircle(headCenter, headRadius, paint);
    canvas.drawCircle(headCenter, headRadius, glowPaint);

    // Left shoulder & arm
    path.moveTo(w / 2 - 4, h * 0.175);
    path.quadraticBezierTo(w * 0.36, h * 0.19, w * 0.32, h * 0.23);
    path.lineTo(w * 0.28, h * 0.46);
    path.quadraticBezierTo(w * 0.27, h * 0.48, w * 0.29, h * 0.49);
    path.lineTo(w * 0.33, h * 0.25);

    // Left chest/torso outline
    path.moveTo(w * 0.37, h * 0.25);
    path.quadraticBezierTo(w * 0.39, h * 0.38, w * 0.41, h * 0.46);

    // Right shoulder & arm
    path.moveTo(w / 2 + 4, h * 0.175);
    path.quadraticBezierTo(w * 0.64, h * 0.19, w * 0.68, h * 0.23);
    path.lineTo(w * 0.72, h * 0.46);
    path.quadraticBezierTo(w * 0.73, h * 0.48, w * 0.71, h * 0.49);
    path.lineTo(w * 0.67, h * 0.25);

    // Right chest/torso outline
    path.moveTo(w * 0.63, h * 0.25);
    path.quadraticBezierTo(w * 0.61, h * 0.38, w * 0.59, h * 0.46);

    // Hip/Pelvic region
    path.moveTo(w * 0.41, h * 0.46);
    path.quadraticBezierTo(w * 0.39, h * 0.54, w * 0.42, h * 0.57);
    path.moveTo(w * 0.59, h * 0.46);
    path.quadraticBezierTo(w * 0.61, h * 0.54, w * 0.58, h * 0.57);

    // Left leg
    path.moveTo(w * 0.42, h * 0.57);
    path.lineTo(w * 0.43, h * 0.86);
    path.quadraticBezierTo(w * 0.425, h * 0.88, w * 0.45, h * 0.88);
    path.lineTo(w * 0.47, h * 0.57);

    // Right leg
    path.moveTo(w * 0.58, h * 0.57);
    path.lineTo(w * 0.57, h * 0.86);
    path.quadraticBezierTo(w * 0.575, h * 0.88, w * 0.55, h * 0.88);
    path.lineTo(w * 0.53, h * 0.57);

    canvas.drawPath(path, paint);
    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ══════════════════════════════════════════════
// CUSTOM PAINTER: Smooth Pharmacokinetics Wave with Markers
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
    
    double xForTime(double t) => (t / 24) * width;
    
    final path = Path();
    path.moveTo(0, height);
    
    for (double i = 0; i <= width; i++) {
      double t = (i / width) * 24;
      double y = height;
      if (t >= onset) {
        if (t <= peak) {
          double progress = (t - onset) / (peak - onset);
          y = height - (height * math.sin(progress * (math.pi / 2)));
        } else if (t <= duration) {
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
    
    final fillPath = Path.from(path)
      ..lineTo(activeX, height)
      ..lineTo(0, height)
      ..close();
      
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          activeColor.withValues(alpha: 0.5),
          activeColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height));
      
    canvas.drawPath(fillPath, fillPaint);
    
    final linePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
      
    canvas.drawPath(path, linePaint);
    canvas.restore();
    
    // Draw snap vertical dashed lines at key phase markers
    void drawDashedLine(Canvas canvas, double x, Color snapColor, String label) {
      if (x <= 0 || x >= width) return;
      final paint = Paint()
        ..color = snapColor.withValues(alpha: 0.3)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      
      const dashHeight = 4;
      const dashSpace = 4;
      double startY = 0;
      while (startY < height) {
        canvas.drawLine(Offset(x, startY), Offset(x, startY + dashHeight), paint);
        startY += dashHeight + dashSpace;
      }

      final tp = TextPainter(textDirection: TextDirection.ltr);
      tp.text = TextSpan(
        text: label,
        style: TextStyle(
          color: snapColor.withValues(alpha: 0.6),
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      );
      tp.layout();
      tp.paint(canvas, Offset(x - (tp.width / 2), -14));
    }

    drawDashedLine(canvas, xForTime(onset), const Color(0xFFFBBF24), 'Onset');
    drawDashedLine(canvas, xForTime(peak), const Color(0xFF10B981), 'Peak');
    drawDashedLine(canvas, xForTime(duration), const Color(0xFFEF4444), 'Wear-off');

    // Draw current time marker (the glowing dot)
    if (currentTime > 0) {
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
        5, 
        Paint()..color = Colors.white
      );
      
      canvas.drawCircle(
        Offset(activeX, markerY), 
        12, 
        Paint()..color = activeColor.withValues(alpha: 0.4)
      );
    }
  }

  @override
  bool shouldRepaint(_PharmacokineticsWavePainter old) {
    return old.currentTime != currentTime || old.activeColor != activeColor;
  }
}

// Helper Organ Definition Class
class OrganDef {
  final String name;
  final String emoji;
  final double dx;
  final double dy;
  final String impactText;

  OrganDef({
    required this.name,
    required this.emoji,
    required this.dx,
    required this.dy,
    required this.impactText,
  });
}
