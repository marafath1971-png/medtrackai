import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../providers/app_state.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../widgets/modals/mascot_shop_sheet.dart';
import '../../../widgets/mascot_widget.dart';
import '../../../widgets/common/animated_pressable.dart';
import '../../../services/gemini_service.dart';

class HomeMascotCard extends StatefulWidget {
  const HomeMascotCard({super.key});

  @override
  State<HomeMascotCard> createState() => _HomeMascotCardState();
}

class _HomeMascotCardState extends State<HomeMascotCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceCtrl;

  String _currentQuote = "Your future self is thanking you for every dose you take.";
  bool _isLoading = false;

  final List<String> _sleepyQuotes = [
    "One gentle dose at a time — your future self is already proud.",
    "Rest easy. When you're ready, we'll start your win streak together.",
    "Peace begins with showing up. Log a dose when you can.",
    "You're not behind — you're building. Start when you're ready.",
  ];

  final List<String> _normalQuotes = [
    "Your future self is thanking you for every dose you take.",
    "Consistency is how success becomes real — you've got this.",
    "Hydrate, take your meds, trust the plan made for you.",
    "Knowing your medicine is an act of self-respect.",
    "Small daily wins compound into the life you want.",
    "This app was built for people like you — keep going.",
    "Stay steady. Stay hopeful. You're on the right path.",
    "Taking meds on time is how you choose yourself.",
  ];

  final List<String> _energeticQuotes = [
    "You're proving what consistency can do — keep the streak alive.",
    "This is what winning looks like: calm, clear, on time.",
    "Lock in today's doses — you're becoming your strongest self.",
    "Trust the process. Trust yourself. Success is showing up.",
    "You're not just tracking meds — you're building a better life.",
    "Level up: one more perfect day of care.",
  ];

  final List<String> _happyQuotes = [
    "You're living proof that consistency works. Share the win.",
    "Legendary streak energy — you are succeeding.",
    "This is the #1 habit that protects your future.",
    "Unstoppable — because you showed up for yourself.",
    "Your success is real. Keep believing. Keep taking.",
  ];

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: AppDurations.fast,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshQuote();
    });
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshQuote() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final appState = context.read<AppState>();
    final streak = appState.getStreak();
    final recentMeds = appState.meds.map((m) => m.name).toList();

    String mood = 'content';
    if (streak == 0) {
      mood = 'sleepy';
    } else if (streak > 0 && streak < 3) {
      mood = 'content';
    } else if (streak >= 3 && streak < 7) {
      mood = 'energetic';
    } else {
      mood = 'happy';
    }

    String aiQuote = '';
    try {
      aiQuote = await GeminiService.generateMascotQuote(
        streak: streak,
        recentMeds: recentMeds,
        mood: mood,
      );
    } catch (e) {
      debugPrint('Error generating mascot quote: $e');
    }

    if (aiQuote.isNotEmpty) {
      if (mounted) {
        setState(() {
          _currentQuote = aiQuote;
          _isLoading = false;
        });
      }
      return;
    }

    List<String> pool;
    if (streak == 0) {
      pool = _sleepyQuotes;
    } else if (streak > 0 && streak < 3) {
      pool = _normalQuotes;
    } else if (streak >= 3 && streak < 7) {
      pool = _energeticQuotes;
    } else {
      pool = _happyQuotes;
    }

    final random = Random();
    String nextQuote = pool[random.nextInt(pool.length)];
    if (pool.length > 1) {
      while (nextQuote == _currentQuote) {
        nextQuote = pool[random.nextInt(pool.length)];
      }
    }

    if (mounted) {
      setState(() {
        _currentQuote = nextQuote;
        _isLoading = false;
      });
    }
  }

  void _onTap() {
    HapticEngine.selection();
    if (!MedAiA11y.reducedMotion(context)) {
      _bounceCtrl.forward(from: 0.0);
    }
    _refreshQuote();
  }

  String _moodForStreak(int streak) {
    if (streak == 0) return 'sleepy';
    if (streak < 3) return 'content';
    if (streak < 7) return 'energetic';
    return 'happy';
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final reduceMotion = MedAiA11y.reducedMotion(context);
    final streak = context.select<AppState, int>((s) => s.getStreak());
    final mood = _moodForStreak(streak);

    Widget mascot = Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: L.accent.withValues(alpha: 0.06),
            shape: BoxShape.circle,
          ),
        ),
        MascotWidget(size: 64, mood: mood),
        Positioned(
          bottom: 0,
          right: 0,
          child: Semantics(
            button: true,
            label: 'Mascot shop',
            child: AnimatedPressable(
              onTap: () => MascotShopSheet.show(context),
              child: Container(
                width: 28,
                height: 28,
                padding: const EdgeInsets.all(AppSpacing.p4),
                decoration: BoxDecoration(
                  color: L.card,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: const Center(
                  child: Text('👕', style: TextStyle(fontSize: 12)),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (!reduceMotion) {
      mascot = ScaleTransition(
        scale: _bounceCtrl.drive(
          TweenSequence([
            TweenSequenceItem(
                tween: Tween<double>(begin: 1.0, end: 1.15), weight: 30),
            TweenSequenceItem(
                tween: Tween<double>(begin: 1.15, end: 1.0), weight: 70),
          ]),
        ),
        child: mascot,
      );
    }

    return Semantics(
      button: true,
      label: 'MedAI companion. Tap for a new coaching message.',
      child: MedAiDepthCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.p16),
        onTap: _onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            mascot,
            const SizedBox(width: AppSpacing.p16),
            Expanded(
              child: MedAiGlass(
                padding: const EdgeInsets.fromLTRB(AppSpacing.p16, AppSpacing.p12, AppSpacing.p16, AppSpacing.p12),
                radius: 16,
                tint: L.fill.withValues(alpha: 0.3),
                child: AnimatedSwitcher(
                  duration: MedAiA11y.motion(context, 250.ms),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: _isLoading
                      ? Container(
                          key: const ValueKey('mascot_coaching_loading'),
                          height: 38,
                          alignment: AlignmentDirectional.centerStart,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Coaching',
                                style: AppTypography.labelSmall.copyWith(
                                  color: L.accent.withValues(alpha: 0.8),
                                  fontSize: 10,
                                  letterSpacing: 0.1,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.p8),
                              ...List.generate(3, (index) {
                                return Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 1.5),
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: L.accent
                                        .withValues(alpha: 0.45 + (index * 0.15)),
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }),
                            ],
                          ),
                        )
                      : Column(
                          key: ValueKey(_currentQuote),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'MedAI companion',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: L.accent,
                                    fontSize: 10,
                                    letterSpacing: 0.1,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: L.accent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: L.accent.withValues(alpha: 0.2),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.auto_awesome_rounded,
                                          size: 7, color: L.accent),
                                      const SizedBox(width: 2.5),
                                      Text(
                                        'Live',
                                        style: AppTypography.labelSmall.copyWith(
                                          color: L.accent,
                                          fontSize: 7,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.p4),
                            Text(
                              _currentQuote,
                              style: AppTypography.bodyMedium.copyWith(
                                color: L.text,
                                fontWeight: FontWeight.w500,
                                fontSize: 13.5,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
