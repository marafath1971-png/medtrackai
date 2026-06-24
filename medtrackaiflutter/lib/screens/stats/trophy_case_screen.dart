import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/shared/shared_widgets.dart';
import '../../widgets/viral/share_milestone_card.dart';

class TrophyCaseScreen extends StatelessWidget {
  const TrophyCaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final state = context.watch<AppState>();
    final streak = state.getStreak();

    final List<Map<String, dynamic>> badges = [
      {'title': '3 Days', 'days': 3, 'color': const Color(0xFFCD7F32), 'icon': '🥉'},
      {'title': '7 Days', 'days': 7, 'color': const Color(0xFFC0C0C0), 'icon': '🥈'},
      {'title': '30 Days', 'days': 30, 'color': const Color(0xFFFFD700), 'icon': '🥇'},
      {'title': '100 Days', 'days': 100, 'color': const Color(0xFFb9f2ff), 'icon': '💎'},
    ];

    return Scaffold(
      backgroundColor: L.bg,
      body: Stack(
        children: [
          // Background ambient glows
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(color: Colors.amber.withValues(alpha: 0.1), blurRadius: 100)
                ],
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.2,1.2), duration: 5.seconds),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: 16),
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
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: L.border.withValues(alpha: 0.1)),
                          ),
                          child: Icon(Icons.arrow_back_ios_new_rounded, color: L.text, size: 18),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MILESTONES',
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.amber.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                              ),
                            ),
                            Text(
                              'Trophy Case',
                              style: AppTypography.headlineMedium.copyWith(
                                color: L.text,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(AppSpacing.screenPadding),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: badges.length,
                    itemBuilder: (context, index) {
                      final b = badges[index];
                      final bool isUnlocked = streak >= (b['days'] as int);
                      
                      return _BadgeCard(
                        title: b['title'],
                        targetDays: b['days'],
                        icon: b['icon'],
                        color: b['color'],
                        isUnlocked: isUnlocked,
                        currentStreak: streak,
                        L: L,
                      ).animate(delay: (100 * index).ms).fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0);
                    },
                  ),
                ),
                
                // Share Button at the bottom
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  child: BouncingButton(
                    onTap: () {
                      HapticEngine.heavyImpact();
                      ShareMilestoneCard.share(
                        context,
                        streak,
                        userName: state.profile?.name ?? 'User',
                        adherencePct: state.getAdherenceScore(),
                        totalDosesTaken: state.history.values.expand((e) => e).where((e) => e.taken).length,
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [L.primary, L.secondary],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: L.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.ios_share_rounded, color: L.onPrimary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'SHARE TO INSTAGRAM / TIKTOK',
                            style: AppTypography.labelMedium.copyWith(
                              color: L.onPrimary,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 600.ms).slideY(begin: 0.2, end: 0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final String title;
  final int targetDays;
  final String icon;
  final Color color;
  final bool isUnlocked;
  final int currentStreak;
  final AppThemeColors L;

  const _BadgeCard({
    required this.title,
    required this.targetDays,
    required this.icon,
    required this.color,
    required this.isUnlocked,
    required this.currentStreak,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    double progress = currentStreak / targetDays;
    if (progress > 1.0) progress = 1.0;

    return AnimatedPressable(
      onTap: () {
        if (isUnlocked) {
          HapticEngine.success();
        } else {
          HapticEngine.selection();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isUnlocked ? color.withValues(alpha: 0.5) : L.border.withValues(alpha: 0.1),
            width: isUnlocked ? 2.0 : 1.0,
          ),
          boxShadow: isUnlocked ? [
            BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))
          ] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge Graphic
            Stack(
              alignment: Alignment.center,
              children: [
                if (isUnlocked)
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 30)
                      ],
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.1,1.1), duration: 2.seconds),
                
                // 3D Coin base
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: isUnlocked 
                          ? [color.withValues(alpha: 0.8), color] 
                          : [L.border.withValues(alpha: 0.1), L.border.withValues(alpha: 0.2)],
                    ),
                    border: Border.all(
                      color: isUnlocked ? Colors.white.withValues(alpha: 0.5) : L.border.withValues(alpha: 0.1),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.3),
                        blurRadius: 2,
                        offset: const Offset(0, -2),
                      )
                    ],
                  ),
                  child: Center(
                    child: Text(
                      isUnlocked ? icon : '🔒',
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
              ],
            ).animate(onPlay: isUnlocked ? (c) => c.repeat(reverse: true) : null)
             .moveY(begin: -5, end: 5, duration: 1500.ms, curve: Curves.easeInOut),
             
            const SizedBox(height: 24),
            
            Text(
              title,
              style: AppTypography.titleLarge.copyWith(
                color: isUnlocked ? color : L.sub,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: L.border.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(isUnlocked ? color : L.secondary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isUnlocked ? 'Unlocked!' : '$currentStreak/$targetDays Days',
                    style: AppTypography.labelSmall.copyWith(
                      color: L.sub,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
