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
import '../../widgets/common/mesh_gradient.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../theme/med_ai_ui.dart';

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

  int _totalDoses = 0;
  int _longestStreak = 0;
  int _adherenceScore = 0;
  String _archetype = 'Steady Guardian';
  String _archetypeDesc =
      'You keep your health routine balanced and predictable.';
  Color _archetypeColor = const Color(0xFF10B981);
  Gradient _archetypeGradient = const LinearGradient(
      colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)]);

  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 4));
    _computeStats();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSlideshow());
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
      final isWeekend =
          date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

      for (var dose in list) {
        dosesCount++;
        if (dose.taken) {
          takenCount++;
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
    _adherenceScore =
        dosesCount > 0 ? ((takenCount / dosesCount) * 100).round() : 92;

    if (_adherenceScore >= 98) {
      _archetype = 'Consistency Champion';
      _archetypeDesc = 'Flawless execution. Your health routine is absolute.';
      _archetypeColor = const Color(0xFF10B981);
      _archetypeGradient = const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)]);
    } else if (morningDoses > nightDoses && morningDoses >= 5) {
      _archetype = '8am Perfectionist';
      _archetypeDesc =
          'You conquer your day early. Sunrise, medication, action.';
      _archetypeColor = const Color(0xFFFFD700);
      _archetypeGradient = const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)]);
    } else if (nightDoses > morningDoses && nightDoses >= 5) {
      _archetype = 'Night Owl Doser';
      _archetypeDesc =
          'Circadian routine engineered. Unlocking peak sleep recovery.';
      _archetypeColor = const Color(0xFF8B5CF6);
      _archetypeGradient = const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)]);
    } else if (weekendMisses > weekdayMisses && weekendMisses >= 2) {
      _archetype = 'Weekend Wildcard';
      _archetypeDesc =
          'Locked in during the week, but Saturdays are a gamble.';
      _archetypeColor = const Color(0xFFEF4444);
      _archetypeGradient = const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFF97316)]);
    } else {
      _archetype = 'Steady Guardian';
      _archetypeDesc =
          'Balanced, structured, and resilient. Maintaining the optimal baseline.';
      _archetypeColor = const Color(0xFF00E5FF);
      _archetypeGradient = const LinearGradient(
          colors: [Color(0xFF00E5FF), Color(0xFF3B82F6)]);
    }
  }

  void _startSlideshow() {
    if (!mounted || MedAiA11y.reducedMotion(context)) return;
    _slideTimer?.cancel();
    _slideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentSlide < 5) {
        setState(() {
          _currentSlide++;
          if (_currentSlide == 5) _confettiController.play();
        });
        _pageController.nextPage(
          duration: MedAiA11y.motion(context, const Duration(milliseconds: 600)),
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
    final duration =
        MedAiA11y.motion(context, const Duration(milliseconds: 400));

    HapticEngine.selection();
    _slideTimer?.cancel();

    if (tapX < width * 0.35) {
      if (_currentSlide > 0) {
        setState(() => _currentSlide--);
        _pageController.previousPage(
            duration: duration, curve: Curves.easeOutExpo);
      }
    } else if (_currentSlide < 5) {
      setState(() {
        _currentSlide++;
        if (_currentSlide == 5 && !MedAiA11y.reducedMotion(context)) {
          _confettiController.play();
        }
      });
      _pageController.nextPage(duration: duration, curve: Curves.easeOutExpo);
    }
    _startSlideshow();
  }

  Future<void> _shareWrapped() async {
    HapticEngine.medium();
    try {
      final boundary = _shareKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
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
        text:
            '⚡ My MedAI Wrapped Archetype: $_archetype! Streak: $_longestStreak days. How consistent are you? 💊 #MedAIWrapped',
      );
    } catch (e) {
      debugPrint('Share Wrapped error: $e');
    }
  }

  Widget _withMotion(Widget child, {List<Effect>? effects}) {
    if (MedAiA11y.reducedMotion(context)) return child;
    return child.animate(effects: effects);
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final reduceMotion = MedAiA11y.reducedMotion(context);

    return AppScaffold(
      showAurora: true,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  child: Semantics(
                    label: 'Slide ${_currentSlide + 1} of 6',
                    child: Row(
                      children: List.generate(6, (index) {
                        return Expanded(
                          child: AnimatedContainer(
                            duration: MedAiA11y.motion(
                                context, const Duration(milliseconds: 300)),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            height: 3.5,
                            decoration: BoxDecoration(
                              color: index <= _currentSlide
                                  ? L.text
                                  : L.border.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                Expanded(
                  child: RepaintBoundary(
                    key: _shareKey,
                    child: Semantics(
                      label: 'Tap left to go back, right to go forward',
                      child: GestureDetector(
                        onTapUp: _onTapSlide,
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildSlide(
                              accentColor: L.green,
                              number: '2026',
                              label: 'Your year in consistency, quantified.',
                              subtext: 'Let\'s review your biohacking journey.',
                            ),
                            _buildSlide(
                              accentColor: L.accent,
                              number: '$_totalDoses',
                              label:
                                  'Total doses logged and verified by AI.',
                              subtext: 'Every single microdose matters.',
                            ),
                            _buildSlide(
                              accentColor: L.amber,
                              number: '$_longestStreak',
                              label:
                                  'Day streak was your maximum momentum.',
                              subtext: 'Building permanent neural habits.',
                            ),
                            _buildSlide(
                              accentColor: L.error,
                              number: '$_adherenceScore%',
                              label: 'Overall adherence score this year.',
                              subtext: 'Above 90% is clinical perfection.',
                            ),
                            _buildArchetypeSlide(),
                            _buildSummarySlide(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (!reduceMotion)
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      maxBlastForce: 30,
                      minBlastForce: 10,
                      emissionFrequency: 0.08,
                      numberOfParticles: 40,
                      gravity: 0.25,
                      colors: [
                        L.green,
                        L.accent,
                        L.purple,
                        L.amber,
                        L.error,
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: MedAiCTA(
                          label: 'Close',
                          secondary: true,
                          semanticsLabel: 'Close wrapped summary',
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: MedAiCTA(
                          label: 'Share Wrapped',
                          icon: Icons.ios_share_rounded,
                          semanticsLabel: 'Share your Med AI wrapped summary',
                          onTap: _shareWrapped,
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

    Widget content = MedAiGlass(
      padding: const EdgeInsets.all(32),
      radius: AppRadius.squircle,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                number,
                style: AppTypography.displayLarge.copyWith(
                  color: accentColor,
                  fontSize: 96,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -4,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                label,
                style: AppTypography.headlineSmall.copyWith(
                  color: L.text,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                subtext,
                style: AppTypography.bodyMedium.copyWith(
                  color: L.sub,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
          Positioned(
            bottom: -16,
            right: -16,
            child: MedAiGlass(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              radius: AppRadius.xl,
              child: Row(
                children: [
                  Icon(Icons.blur_on_rounded,
                      color: L.sub, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Med AI',
                    style: AppTypography.labelSmall.copyWith(
                      color: L.sub,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    content = _withMotion(
      content,
      effects: [
        FadeEffect(duration: AppDurations.fast, curve: AppCurves.smooth),
        ScaleEffect(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: AppDurations.hero,
          curve: AppCurves.smooth,
        ),
      ],
    );

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.all(32.0),
      child: Center(child: content),
    );
  }

  Widget _buildArchetypeSlide() {
    final L = context.L;

    Widget badge = MedAiDepthCard(
      padding: EdgeInsets.zero,
      radius: AppRadius.xl,
      accentGlow: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: SizedBox(
          height: 220,
          child: Stack(
            children: [
              Positioned.fill(
                child: MeshGradient(
                  colors: [
                    _archetypeColor,
                    _archetypeGradient.colors.last,
                    L.bg,
                  ],
                ),
              ),
              Positioned.fill(
                child: Container(
                  color: L.bg.withValues(alpha: 0.25),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_rounded,
                        color: Colors.white, size: 48),
                    const Spacer(),
                    Text(
                      _archetype,
                      style: AppTypography.displaySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _archetypeDesc,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 24,
                right: 24,
                child: MedAiGlass(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  radius: AppRadius.l,
                  child: Text(
                    'Med AI',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    badge = _withMotion(badge);

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'YOUR ARCHETYPE',
            style: AppTypography.labelSmall.copyWith(
              color: L.sub,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          badge,
          const SizedBox(height: 36),
          Text(
            'Calculated based on your historical dose logging timestamp profiles.',
            style: AppTypography.bodySmall.copyWith(
              color: L.sub,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySlide() {
    final L = context.L;

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: L.green, size: 48),
          const SizedBox(height: 24),
          Text(
            'Habit Architecture Locked.',
            style: AppTypography.headlineSmall.copyWith(
              color: L.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Keep sharing your consistency. You inspire others to optimize their routines.',
            style: AppTypography.bodyMedium.copyWith(
              color: L.sub,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              _buildMiniStat('Streak', '$_longestStreak Days'),
              const SizedBox(width: 16),
              _buildMiniStat('Adherence', '$_adherenceScore%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    final L = context.L;
    return Expanded(
      child: Semantics(
        label: '$label $value',
        child: MedAiDepthCard(
          padding: const EdgeInsets.all(16),
          radius: AppRadius.l,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(color: L.sub),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTypography.titleMedium.copyWith(
                  color: L.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
