import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../providers/app_state.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/premium_page_header.dart';
import '../../../core/utils/haptic_engine.dart';

class MedBuddiesScreen extends StatefulWidget {
  const MedBuddiesScreen({super.key});

  @override
  State<MedBuddiesScreen> createState() => _MedBuddiesScreenState();
}

class _MedBuddiesScreenState extends State<MedBuddiesScreen> {
  bool _nudged = false;

  Widget _entrance(Widget child, {Duration delay = Duration.zero}) {
    if (MedAiA11y.reducedMotion(context)) return child;
    return child
        .animate(delay: delay)
        .fadeIn(duration: AppDurations.fast, curve: AppCurves.smooth)
        .slideY(begin: 0.1, end: 0, curve: AppCurves.smooth);
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final state = context.watch<AppState>();
    final myStreak = state.getStreak();

    const buddyName = 'Sarah';
    const buddyStreak = 14;
    final combinedStreak = myStreak + buddyStreak;

    Widget linkIcon = Icon(Icons.link_rounded, color: L.onPrimary, size: 32);

    final streakNumber = Text(
      '$combinedStreak',
      style: AppTypography.displayLarge.copyWith(
        color: L.onPrimary,
        fontSize: 72,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.5,
        height: 1.0,
      ),
    );

    return AppScaffold(
      showAurora: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PremiumPageHeader(
              title: 'Med buddies',
              subtitle: 'Social accountability',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.screenPadding),
                    children: [
                      _entrance(
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [L.primary, L.secondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            boxShadow: [
                              BoxShadow(
                                color: L.primary.withValues(alpha: 0.3),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _AvatarRing(
                                      color: L.onPrimary, initials: 'ME'),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: linkIcon,
                                  ),
                                  _AvatarRing(
                                      color: L.onPrimary, initials: 'SR'),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Combined streak',
                                style: AppTypography.labelLarge.copyWith(
                                  color: L.onPrimary.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              streakNumber,
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
                        ),
                      ),
                      const SizedBox(height: 32),
                      _entrance(
                        MedAiDepthCard(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: MedAiA11y.minTapTarget,
                                    height: MedAiA11y.minTapTarget,
                                    decoration: BoxDecoration(
                                      color: L.accent.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                        Icons.notifications_active_rounded,
                                        color: L.accent,
                                        size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Nudge $buddyName',
                                          style: AppTypography.titleLarge
                                              .copyWith(
                                            color: L.text,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          'Send a gentle reminder to stay on track.',
                                          style:
                                              AppTypography.bodyMedium.copyWith(
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
                              MedAiCTA(
                                label: _nudged ? 'Nudge Sent! 🎉' : 'Send Nudge',
                                enabled: !_nudged,
                                onTap: _nudged
                                    ? null
                                    : () {
                                        HapticEngine.heavyImpact();
                                        setState(() => _nudged = true);
                                      },
                              ),
                            ],
                          ),
                        ),
                        delay: 200.ms,
                      ),
                      const SizedBox(height: 32),
                      _entrance(
                        _LeaderboardSection(
                          myStreak: myStreak,
                          buddyStreak: buddyStreak,
                          buddyName: buddyName,
                        ),
                        delay: 400.ms,
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
        MedAiSectionHeader(title: 'Global ranking'),
        _LeaderboardRow(
          rank: 1,
          name: firstPlaceName,
          initials: firstPlaceInitials,
          streak: firstPlaceStreak,
          isMe: iAmWinning,
          L: L,
        ),
        const SizedBox(height: 12),
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

    return MedAiDepthCard(
      accentGlow: isMe,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: isMe ? L.accent.withValues(alpha: 0.08) : L.card,
      child: Row(
        children: [
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFirst
                  ? L.secondary.withValues(alpha: 0.1)
                  : L.text.withValues(alpha: 0.05),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 16)),
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
