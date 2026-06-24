import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../widgets/shared/shared_widgets.dart';

class MedBuddiesScreen extends StatefulWidget {
  const MedBuddiesScreen({super.key});

  @override
  State<MedBuddiesScreen> createState() => _MedBuddiesScreenState();
}

class _MedBuddiesScreenState extends State<MedBuddiesScreen> {
  bool _nudged = false;

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final state = context.watch<AppState>();
    final myStreak = state.getStreak();
    
    // Mock data for demo
    final buddyName = "Sarah";
    final buddyStreak = 14;
    final combinedStreak = myStreak + buddyStreak;

    return Scaffold(
      backgroundColor: L.bg,
      body: Stack(
        children: [
          // Background ambient glows
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: L.secondary.withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(color: L.secondary.withValues(alpha: 0.2), blurRadius: 100)
                ],
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.2,1.2), duration: 4.seconds),
          
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
                              'SOCIAL ACCOUNTABILITY',
                              style: AppTypography.labelLarge.copyWith(
                                color: L.secondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                              ),
                            ),
                            Text(
                              'Med Buddies',
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
                
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.screenPadding),
                    children: [
                      // Combined Streak Card
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [L.primary, L.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(color: L.primary.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 15)),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _AvatarRing(color: L.onPrimary, initials: 'ME'),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Icon(Icons.link_rounded, color: L.onPrimary, size: 32)
                                    .animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.2,1.2)),
                                ),
                                _AvatarRing(color: L.onPrimary, initials: 'SR'),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'COMBINED STREAK',
                              style: AppTypography.labelLarge.copyWith(
                                color: L.onPrimary.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$combinedStreak',
                              style: AppTypography.displayLarge.copyWith(
                                color: L.onPrimary,
                                fontSize: 80,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -2.0,
                                height: 1.0,
                              ),
                            ).animate().shimmer(duration: 2.seconds, delay: 1.seconds, color: L.onPrimary.withValues(alpha: 0.5)),
                            const SizedBox(height: 8),
                            Text(
                              'You and $buddyName are unstoppable! ⚡',
                              style: AppTypography.bodyLarge.copyWith(
                                color: L.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                      
                      const SizedBox(height: 32),
                      
                      // Nudge Buddy Section
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: L.card,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: L.border.withValues(alpha: 0.1)),
                          boxShadow: AppShadows.neumorphic,
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: L.accent.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.notifications_active_rounded, color: L.accent, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Nudge $buddyName',
                                        style: AppTypography.titleLarge.copyWith(
                                          color: L.text,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        'Send a gentle reminder to stay on track.',
                                        style: AppTypography.bodyMedium.copyWith(
                                          color: L.sub,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            BouncingButton(
                              onTap: _nudged ? null : () {
                                HapticEngine.heavyImpact();
                                setState(() => _nudged = true);
                              },
                              child: AnimatedContainer(
                                duration: 300.ms,
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: _nudged ? L.success.withValues(alpha: 0.1) : L.accent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    _nudged ? 'Nudge Sent! 🎉' : 'Send Nudge',
                                    style: AppTypography.labelLarge.copyWith(
                                      color: _nudged ? L.success : L.onPrimary,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                      
                      const SizedBox(height: 32),
                      
                      // Leaderboard Section
                      _LeaderboardSection(myStreak: myStreak, buddyStreak: buddyStreak, buddyName: buddyName)
                        .animate(delay: 400.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
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
}

class _AvatarRing extends StatelessWidget {
  final Color color;
  final String initials;

  const _AvatarRing({required this.color, required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.5), width: 3),
        color: color.withValues(alpha: 0.1),
      ),
      child: Center(
        child: Text(
          initials,
          style: AppTypography.titleLarge.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}

class _LeaderboardSection extends StatelessWidget {
  final int myStreak;
  final int buddyStreak;
  final String buddyName;

  const _LeaderboardSection({
    required this.myStreak,
    required this.buddyStreak,
    required this.buddyName,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    
    // Determine ranking
    final bool iAmWinning = myStreak >= buddyStreak;
    final int firstPlaceStreak = iAmWinning ? myStreak : buddyStreak;
    final String firstPlaceName = iAmWinning ? 'You' : buddyName;
    final String firstPlaceInitials = iAmWinning ? 'ME' : 'SR';
    
    final int secondPlaceStreak = iAmWinning ? buddyStreak : myStreak;
    final String secondPlaceName = iAmWinning ? buddyName : 'You';
    final String secondPlaceInitials = iAmWinning ? 'SR' : 'ME';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GLOBAL RANKING',
          style: AppTypography.labelLarge.copyWith(
            color: L.sub,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 16),
        
        // 1st Place Card
        _LeaderboardRow(
          rank: 1,
          name: firstPlaceName,
          initials: firstPlaceInitials,
          streak: firstPlaceStreak,
          isMe: iAmWinning,
          L: L,
        ),
        
        const SizedBox(height: 12),
        
        // 2nd Place Card
        _LeaderboardRow(
          rank: 2,
          name: secondPlaceName,
          initials: secondPlaceInitials,
          streak: secondPlaceStreak,
          isMe: !iAmWinning,
          L: L,
        ),
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final String name;
  final String initials;
  final int streak;
  final bool isMe;
  final AppThemeColors L;

  const _LeaderboardRow({
    required this.rank,
    required this.name,
    required this.initials,
    required this.streak,
    required this.isMe,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFirst = rank == 1;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isMe ? L.accent.withValues(alpha: 0.1) : L.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isMe ? L.accent.withValues(alpha: 0.3) : L.border.withValues(alpha: 0.1),
          width: isMe ? 2 : 1,
        ),
        boxShadow: isMe ? [
          BoxShadow(
            color: L.accent.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ] : AppShadows.neumorphic,
      ),
      child: Row(
        children: [
          // Rank Number
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style: AppTypography.titleLarge.copyWith(
                color: isFirst ? L.secondary : L.sub,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFirst ? L.secondary.withValues(alpha: 0.1) : L.text.withValues(alpha: 0.05),
            ),
            child: Center(
              child: Text(
                initials,
                style: AppTypography.titleMedium.copyWith(
                  color: isFirst ? L.secondary : L.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Name
          Expanded(
            child: Row(
              children: [
                Text(
                  name,
                  style: AppTypography.titleLarge.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: L.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'YOU',
                      style: AppTypography.labelSmall.copyWith(
                        color: L.onPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),
          
          // Streak Score
          Row(
            children: [
              Text(
                '🔥',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 4),
              Text(
                '$streak',
                style: AppTypography.headlineSmall.copyWith(
                  color: isFirst ? L.secondary : L.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
