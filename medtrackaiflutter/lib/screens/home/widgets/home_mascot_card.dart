import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
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
  
  String _currentQuote = "hydrate before you dehydrate 💧";
  bool _isLoading = false;

  final List<String> _sleepyQuotes = [
    "shhh... i'm resting up. let's wake up with a dose! 😴",
    "still sleepy... did we take our meds yet? ☕",
    "routine loading... log a dose to wake me up! ⏳",
    "dreaming of perfect compliance 💤",
  ];

  final List<String> _normalQuotes = [
    "taking meds = major green flag behavior 💅",
    "your future self is literally thanking you right now! 👑",
    "hydrate before you dehydrate 💧",
    "consistency is the ultimate flex! 💪",
    "self-care isn't selfish, it's essential 🛡️",
    "don't forget to drink some water with that 🌊",
    "let's secure that streak today, bestie! 💅",
    "taking meds is self-love. facts only 🧬",
  ];

  final List<String> _energeticQuotes = [
    "we love a consistent queen/king/legend ⚡",
    "streak is looking fire today! keep it up 🔥",
    "lock in! let's make today 100% compliance 🔒",
    "unlocked: high energy vibe ⚡",
    "you are doing amazing sweetie! 💖",
    "compliance level: god mode 🎮",
  ];

  final List<String> _happyQuotes = [
    "your streak is too hot to handle 🔥",
    "absolute legend behavior right here 🏆",
    "an absolute icon of consistency 👑",
    "we are officially unstoppable 🚀",
    "pure main character energy today ✨",
  ];

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Pick an initial quote based on mood
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

    // Determine mascot mood based on streak
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

    // Local Fallback Pool
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
    _bounceCtrl.forward(from: 0.0);
    _refreshQuote();
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final streak = context.select<AppState, int>((s) => s.getStreak());

    // Determine mascot mood based on streak
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: L.border.withValues(alpha: 0.08),
          width: 1.2,
        ),
        boxShadow: AppShadows.neumorphic,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Mascot Column with Tap Animation
          AnimatedPressable(
            onTap: _onTap,
            child: ScaleTransition(
              scale: _bounceCtrl.drive(
                TweenSequence([
                  TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.15), weight: 30),
                  TweenSequenceItem(tween: Tween<double>(begin: 1.15, end: 1.0), weight: 70),
                ]),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Soft background glow
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
                    child: GestureDetector(
                      onTap: () => MascotShopSheet.show(context),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: L.card,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
                        ),
                        child: Text('👕', style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Speech Bubble
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: L.fill.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                  bottomLeft: Radius.zero,
                ),
                border: Border.all(
                  color: L.border.withValues(alpha: 0.05),
                  width: 1.0,
                ),
              ),
              child: AnimatedSwitcher(
                duration: 250.ms,
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
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'COACHING',
                              style: AppTypography.labelSmall.copyWith(
                                color: L.accent.withValues(alpha: 0.8),
                                fontSize: 9,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ...List.generate(3, (index) {
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: L.accent.withValues(alpha: 0.8),
                                  shape: BoxShape.circle,
                                ),
                              ).animate(
                                onPlay: (c) => c.repeat(),
                              ).scale(
                                begin: const Offset(0.6, 0.6),
                                end: const Offset(1.2, 1.2),
                                duration: 600.ms,
                                delay: (index * 150).ms,
                                curve: Curves.easeInOut,
                              ).fadeIn(
                                begin: 0.4,
                                duration: 600.ms,
                                delay: (index * 150).ms,
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
                                'MEDAI COMPANION',
                                style: AppTypography.labelSmall.copyWith(
                                  color: L.accent,
                                  fontSize: 9,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
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
                                    Icon(Icons.auto_awesome_rounded, size: 7, color: L.accent),
                                    const SizedBox(width: 2.5),
                                    Text(
                                      'AI LIVE',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: L.accent,
                                        fontSize: 6.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
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
    );
  }
}
