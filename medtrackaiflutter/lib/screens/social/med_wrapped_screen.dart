import 'dart:ui' as ui;
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import '../../providers/app_state.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/common/ambient_mesh_bg.dart';
import '../../widgets/common/mesh_gradient.dart';
import '../../theme/app_theme.dart';
import 'package:medai/widgets/common/animated_pressable.dart';

class MedWrappedScreen extends StatefulWidget {
  const MedWrappedScreen({super.key});

  @override
  State<MedWrappedScreen> createState() => _MedWrappedScreenState();
}

class _MedWrappedScreenState extends State<MedWrappedScreen> {
  int _currentSlide = 0;
  Timer? _slideTimer;
  final PageController _pageController = PageController();
  final GlobalKey _shareKey = GlobalKey();

  // Stats computed from history
  int _totalDoses = 0;
  int _longestStreak = 0;
  int _adherenceScore = 0;
  String _archetype = 'Steady Guardian';
  String _archetypeDesc = 'You keep your health routine balanced and predictable.';
  Color _archetypeColor = const Color(0xFF10B981);
  Gradient _archetypeGradient = const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)]);

  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    _computeStats();
    _startSlideshow();
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _pageController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _computeStats() {
    final state = Provider.of<AppState>(context, listen: false);
    _longestStreak = state.getStreak();
    
    // Total doses
    int dosesCount = 0;
    int takenCount = 0;
    
    int morningDoses = 0;
    int nightDoses = 0;
    int weekendMisses = 0;
    int weekdayMisses = 0;

    final today = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final date = today.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().substring(0, 10);
      final list = state.history[dateStr] ?? [];
      final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

      for (var dose in list) {
        dosesCount++;
        if (dose.taken) {
          takenCount++;
          // Parse hour
          try {
            final parts = dose.time.split(':');
            if (parts.isNotEmpty) {
              final hr = int.parse(parts[0]);
              if (hr >= 5 && hr < 10) morningDoses++;
              if (hr >= 21 || hr < 4) nightDoses++;
            }
          } catch (_) {}
        } else if (dose.skipped || !dose.taken) {
          if (isWeekend) {
            weekendMisses++;
          } else {
            weekdayMisses++;
          }
        }
      }
    }

    _totalDoses = takenCount;
    _adherenceScore = dosesCount > 0 ? ((takenCount / dosesCount) * 100).round() : 92;

    // Archetype assignment
    if (_adherenceScore >= 98) {
      _archetype = 'Consistency Champion';
      _archetypeDesc = 'Flawless execution. Your health routine is absolute.';
      _archetypeColor = const Color(0xFF10B981);
      _archetypeGradient = const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]);
    } else if (morningDoses > nightDoses && morningDoses >= 5) {
      _archetype = '8am Perfectionist';
      _archetypeDesc = 'You conquer your day early. Sunrise, medication, action.';
      _archetypeColor = const Color(0xFFFFD700);
      _archetypeGradient = const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]);
    } else if (nightDoses > morningDoses && nightDoses >= 5) {
      _archetype = 'Night Owl Doser';
      _archetypeDesc = 'Circadian routine engineered. Unlocking peak sleep recovery.';
      _archetypeColor = const Color(0xFF8B5CF6);
      _archetypeGradient = const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)]);
    } else if (weekendMisses > weekdayMisses && weekendMisses >= 2) {
      _archetype = 'Weekend Wildcard';
      _archetypeDesc = 'Locked in during the week, but Saturdays are a gamble.';
      _archetypeColor = const Color(0xFFEF4444);
      _archetypeGradient = const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFF97316)]);
    } else {
      _archetype = 'Steady Guardian';
      _archetypeDesc = 'Balanced, structured, and resilient. Maintaining the optimal baseline.';
      _archetypeColor = const Color(0xFF00E5FF);
      _archetypeGradient = const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF3B82F6)]);
    }
  }

  void _startSlideshow() {
    _slideTimer?.cancel();
    _slideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentSlide < 5) {
        setState(() {
          _currentSlide++;
          if (_currentSlide == 5) {
            _confettiController.play();
          }
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutExpo,
        );
      } else {
        _slideTimer?.cancel();
      }
    });
  }

  void _onTapSlide(TapUpDetails details) {
    final width = MediaQuery.of(context).size.width;
    final tapX = details.globalPosition.dx;

    HapticEngine.selection();
    _slideTimer?.cancel();

    if (tapX < width * 0.35) {
      // Go Back
      if (_currentSlide > 0) {
        setState(() => _currentSlide--);
        _pageController.previousPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutExpo,
        );
      }
    } else {
      // Go Next
      if (_currentSlide < 5) {
        setState(() {
          _currentSlide++;
          if (_currentSlide == 5) {
            _confettiController.play();
          }
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutExpo,
        );
      }
    }
    _startSlideshow();
  }

  Future<void> _shareWrapped() async {
    HapticEngine.medium();
    try {
      final boundary = _shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/medai_wrapped.png');
      await file.writeAsBytes(bytes);

      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '⚡ My MedAI Wrapped Archetype: $_archetype! Streak: $_longestStreak days. How consistent are you? 💊 #MedAIWrapped',
      );
    } catch (e) {
      debugPrint('Share Wrapped error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Scaffold(
      backgroundColor: L.bg,
      body: Stack(
        children: [
          // Ambient Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.8, -0.6),
                  radius: 1.5,
                  colors: [
                    AppColors.cyanAccent.withValues(alpha: 0.15),
                    L.bg,
                  ],
                ),
              ),
            ),
          ),
          const Positioned.fill(child: AmbientMeshBackground()),

          SafeArea(
            child: Column(
              children: [
            // Top story progress bar indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: List.generate(6, (index) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 3.5,
                      decoration: BoxDecoration(
                        color: index <= _currentSlide
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Main body
            Expanded(
              child: RepaintBoundary(
                key: _shareKey,
                child: GestureDetector(
                  onTapUp: _onTapSlide,
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // Slide 1: Welcome
                      _buildSlide(
                        accentColor: const Color(0xFF00E5A0),
                        number: '2026',
                        label: 'Your year in consistency, quantified.',
                        subtext: 'Let\'s review your biohacking journey.',
                      ),
                      // Slide 2: Doses Taken
                      _buildSlide(
                        accentColor: const Color(0xFF00E5FF),
                        number: '$_totalDoses',
                        label: 'Total doses logged and verified by AI.',
                        subtext: 'Every single microdose matters.',
                      ),
                      // Slide 3: Longest Streak
                      _buildSlide(
                        accentColor: const Color(0xFFFFC857),
                        number: '$_longestStreak',
                        label: 'Day streak was your maximum momentum.',
                        subtext: 'Building permanent neural habits.',
                      ),
                      // Slide 4: Adherence Score
                      _buildSlide(
                        accentColor: const Color(0xFFEF4444),
                        number: '$_adherenceScore%',
                        label: 'Overall adherence score this year.',
                        subtext: 'Above 90% is clinical perfection.',
                      ),
                      // Slide 5: The Archetype Slide
                      _buildArchetypeSlide(),
                      // Slide 6: Summary & Share
                      _buildSummarySlide(),
                    ],
                  ),
                ),
              ),
            ),

            // Confetti Layer
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                maxBlastForce: 30, // More explosive
                minBlastForce: 10,
                emissionFrequency: 0.08,
                numberOfParticles: 40,
                gravity: 0.25,
                colors: const [
                  Color(0xFF00E5A0), // Green
                  Color(0xFF00E5FF), // Cyan
                  Color(0xFF8B5CF6), // Purple
                  Color(0xFFFFD700), // Gold
                  Color(0xFFEF4444), // Red
                ],
              ),
            ),

            // Bottom bar (Share & Close buttons)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white54,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AnimatedPressable(
                      onTap: _shareWrapped,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF00E5A0), Color(0xFF059669)]),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5A0).withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.ios_share_rounded, color: Colors.black, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Share Wrapped',
                              style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 16, letterSpacing: -0.5),
                            ),
                          ],
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 3.seconds, color: Colors.white.withValues(alpha: 0.3)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ],
      ),
    );
  }

  Widget _buildSlide({
    required Color accentColor,
    required String number,
    required String label,
    required String subtext,
  }) {
    final L = context.L;
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: L.glass,
            borderRadius: BorderRadius.circular(48),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
            boxShadow: AppShadows.glass,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Massive 2026 Number
                  Text(
                    number,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 110, // Massive size
                      fontFamily: 'Courier', fontWeight: FontWeight.w900,
                      letterSpacing: -5,
                      height: 1.0,
                      shadows: [
                        Shadow(color: accentColor.withValues(alpha: 0.5), blurRadius: 24, offset: const Offset(0, 8)),
                      ],
                    ),
                  ).animate().fadeIn(duration: 800.ms, curve: Curves.easeOut).scale(begin: const Offset(0.5, 0.5), end: const Offset(1.0, 1.0), curve: Curves.elasticOut, duration: 1600.ms),
                  const SizedBox(height: 24),
                  // Punchy Single Sentence
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 600.ms).slideY(begin: 0.4, curve: Curves.easeOutBack),
                  const SizedBox(height: 16),
                  // Short description
                  Text(
                    subtext,
                    style: TextStyle(
                      color: L.sub.withValues(alpha: 0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ).animate().fadeIn(delay: 500.ms, duration: 600.ms),
                  const SizedBox(height: 48), // Padding for watermark
                ],
              ),
              // TrackAI Watermark
              Positioned(
                bottom: -16,
                right: -16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.blur_on_rounded, color: Colors.white70, size: 14),
                      const SizedBox(width: 6),
                      Text('TrackAI', style: AppTypography.labelSmall.copyWith(fontFamily: 'Courier', color: Colors.white70, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                    ],
                  ),
                ).animate().fadeIn(delay: 1.seconds, duration: 1.seconds),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArchetypeSlide() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'YOUR ARCHETYPE',
            style: TextStyle(
              color: Color(0xFF6B7280),
              letterSpacing: 2.5,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 20),
          // Holographic styled Archetype Badge
          Container(
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: _archetypeColor.withValues(alpha: 0.4),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(
                children: [
                  // Mesh Gradient background
                  Positioned.fill(
                    child: MeshGradient(
                      colors: [
                        _archetypeColor,
                        _archetypeGradient.colors.last,
                        Colors.black,
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.2), // Darken slightly for text contrast
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.shield_rounded, color: Colors.white, size: 48),
                        const Spacer(),
                        Text(
                          _archetype,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _archetypeDesc,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Watermark inside Archetype badge
                  Positioned(
                    top: 24,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Text('TrackAI', style: AppTypography.labelSmall.copyWith(fontFamily: 'Courier', color: Colors.white70, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 800.ms).scale(begin: const Offset(0.9, 0.9), curve: Curves.elasticOut, duration: 1600.ms),
          const SizedBox(height: 36),
          const Text(
            'Calculated based on your historical dose logging timestamp profiles.',
            style: TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 13,
              height: 1.4,
            ),
          ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
        ],
      ),
    );
  }

  Widget _buildSummarySlide() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF00E5A0), size: 48)
              .animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          const Text(
            'Habit Architecture Locked.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(begin: 0.2),
          const SizedBox(height: 12),
          const Text(
            'Keep sharing your consistency. You inspire others to optimize their routines.',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 16,
              height: 1.4,
            ),
          ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
          const SizedBox(height: 40),
          // High fidelity stats grid preview
          Row(
            children: [
              _buildMiniStat('Streak', '$_longestStreak Days'),
              const SizedBox(width: 16),
              _buildMiniStat('Adherence', '$_adherenceScore%'),
            ],
          ).animate().fadeIn(delay: 800.ms, duration: 600.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    final L = context.L;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: L.glass,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: L.glassBorder),
          boxShadow: AppShadows.glass,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
