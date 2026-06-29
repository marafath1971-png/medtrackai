import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/app_state.dart';
import '../../theme/med_ai_ui.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/animated_pressable.dart';
import '../../widgets/viral/share_milestone_card.dart';

class TrophyCaseScreen extends StatelessWidget {
  const TrophyCaseScreen({super.key});

  Widget _entrance(BuildContext context, Widget child, {Duration? delay}) {
    if (MedAiA11y.reducedMotion(context)) return child;
    return child
        .animate(delay: delay)
        .fadeIn(duration: AppDurations.fast)
        .slideY(begin: 0.08, end: 0, curve: AppCurves.smooth);
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final state = context.watch<AppState>();
    final streak = state.getStreak();
    final reduceMotion = MedAiA11y.reducedMotion(context);

    final List<Map<String, dynamic>> badges = [
      {
        'title': '3 Days',
        'days': 3,
        'color': const Color(0xFFCD7F32),
        'icon': '🥉'
      },
      {
        'title': '7 Days',
        'days': 7,
        'color': const Color(0xFFC0C0C0),
        'icon': '🥈'
      },
      {
        'title': '30 Days',
        'days': 30,
        'color': const Color(0xFFFFD700),
        'icon': '🥇'
      },
      {
        'title': '100 Days',
        'days': 100,
        'color': const Color(0xFFb9f2ff),
        'icon': '💎'
      },
    ];

    return AppScaffold(
      showAurora: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding, vertical: 12),
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'Back',
                    child: AnimatedPressable(
                      onTap: () {
                        HapticEngine.selection();
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: MedAiA11y.minTapTarget,
                        height: MedAiA11y.minTapTarget,
                        decoration: BoxDecoration(
                          color: L.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: L.border.withValues(alpha: 0.12)),
                          boxShadow: AppShadows.soft,
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            color: L.text, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Milestones',
                          style: AppTypography.bodySmall.copyWith(
                            color: L.amber,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Trophy case',
                          style: AppTypography.headlineLarge.copyWith(
                            color: L.text,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding),
              child: MedAiSectionHeader(
                title: 'Your badges',
                subtitle: '$streak day current streak',
              ),
            ),
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
                  final isUnlocked = streak >= (b['days'] as int);

                  return _entrance(
                    context,
                    _BadgeCard(
                      title: b['title'],
                      targetDays: b['days'],
                      icon: b['icon'],
                      color: b['color'],
                      isUnlocked: isUnlocked,
                      currentStreak: streak,
                      L: L,
                      reduceMotion: reduceMotion,
                    ),
                    delay: (100 * index).ms,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: _entrance(
                context,
                MedAiCTA(
                  label: 'Share to Instagram / TikTok',
                  icon: Icons.ios_share_rounded,
                  onTap: () {
                    HapticEngine.heavyImpact();
                    ShareMilestoneCard.share(
                      context,
                      streak,
                      userName: state.profile?.name ?? 'User',
                      adherencePct: state.getAdherenceScore(),
                      totalDosesTaken: state.history.values
                          .expand((e) => e)
                          .where((e) => e.taken)
                          .length,
                    );
                  },
                  semanticsLabel: 'Share milestone to social media',
                ),
                delay: 500.ms,
              ),
            ),
          ],
        ),
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
  final bool reduceMotion;

  const _BadgeCard({
    required this.title,
    required this.targetDays,
    required this.icon,
    required this.color,
    required this.isUnlocked,
    required this.currentStreak,
    required this.L,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    double progress = currentStreak / targetDays;
    if (progress > 1.0) progress = 1.0;

    Widget coin = Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: isUnlocked
              ? [color.withValues(alpha: 0.8), color]
              : [
                  L.border.withValues(alpha: 0.1),
                  L.border.withValues(alpha: 0.2)
                ],
        ),
        border: Border.all(
          color: isUnlocked
              ? Colors.white.withValues(alpha: 0.5)
              : L.border.withValues(alpha: 0.1),
          width: 2,
        ),
        boxShadow: isUnlocked
            ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 20)]
            : AppShadows.soft,
      ),
      child: Center(
        child: Text(
          isUnlocked ? icon : '🔒',
          style: const TextStyle(fontSize: 32),
        ),
      ),
    );

    if (isUnlocked && !reduceMotion) {
      coin = coin
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: -4, end: 4, duration: 1500.ms, curve: Curves.easeInOut);
    }

    return Semantics(
      label: isUnlocked
          ? '$title badge unlocked'
          : '$title badge locked, $currentStreak of $targetDays days',
      child: MedAiDepthCard(
        accentGlow: isUnlocked,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        color: isUnlocked ? L.card : L.card.withValues(alpha: 0.95),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            coin,
            const SizedBox(height: 20),
            Text(
              title,
              style: AppTypography.titleLarge.copyWith(
                color: isUnlocked ? color : L.sub,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: L.border.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          isUnlocked ? color : L.secondary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isUnlocked ? 'Unlocked!' : '$currentStreak/$targetDays days',
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
