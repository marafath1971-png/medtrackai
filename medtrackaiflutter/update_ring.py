import re

with open('lib/screens/home/home_tab.dart', 'r') as f:
    content = f.read()

# Replace _CalAiRingHero class
new_class = """class _CalAiRingHero extends StatelessWidget {
  final int takenCount;
  final int total;
  final double dosePct;
  final int streak;
  final int remaining;

  const _CalAiRingHero({
    required this.takenCount,
    required this.total,
    required this.dosePct,
    required this.streak,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final isDark = context.isDark;
    final isAllDone = total > 0 && dosePct >= 1.0;
    final isEmpty = total == 0;

    final ringColors = isAllDone
        ? [L.green, const Color(0xFF00E676)]
        : [L.accent, Color.lerp(L.accent, Colors.teal, 0.355)!];

    final statusText = isEmpty
        ? 'Add meds to start'
        : isAllDone
            ? 'All doses complete 🎉'
            : '$remaining dose${remaining == 1 ? '' : 's'} remaining';

    final streakBg = isDark
        ? const Color(0xFFFF9F0A).withValues(alpha: 0.08)
        : const Color(0xFFFFF3E0);
    final streakBorder = isDark
        ? const Color(0xFFFF9F0A).withValues(alpha: 0.25)
        : const Color(0xFFFFCC80).withValues(alpha: 0.6);
    final streakTextColor = isDark
        ? const Color(0xFFFF9F0A)
        : const Color(0xFFE65100);

    final trackColor = isDark
        ? L.accent.withValues(alpha: 0.08)
        : L.accent.withValues(alpha: 0.05);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: L.border.withValues(alpha: 0.08),
          width: 1.2,
        ),
        boxShadow: AppShadows.neumorphic,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Side: Text and Badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAllDone ? 'All Done!' : 'Daily Progress',
                  style: AppTypography.headlineSmall.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAllDone
                      ? 'Perfect day ✨'
                      : '$takenCount of $total doses taken',
                  style: AppTypography.bodySmall.copyWith(
                    color: L.sub.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Status & Streak Badges side-by-side
                Row(
                  children: [
                    // Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isAllDone
                            ? L.green.withValues(alpha: 0.10)
                            : L.fill.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isAllDone
                              ? L.green.withValues(alpha: 0.18)
                              : L.border.withValues(alpha: 0.5),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        statusText,
                        style: AppTypography.bodySmall.copyWith(
                          color: isAllDone ? L.green : L.sub.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Streak Badge
                    if (streak > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: streakBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: streakBorder, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(
                              '$streak',
                              style: AppTypography.titleMedium.copyWith(
                                color: streakTextColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // Right Side: Small, smart progress ring
          const SizedBox(width: 16),
          _AnimatedRing(
            percent: dosePct,
            colors: ringColors,
            trackColor: trackColor,
            size: 88,
            strokeWidth: 9,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: dosePct * 100),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Text(
                  '${value.round()}%',
                  style: AppTypography.titleLarge.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}"""

content = re.sub(
    r'class _CalAiRingHero extends StatelessWidget \{.*?\n\}\n(?=\nclass _ShareMilestoneCardCTA)',
    new_class + '\n',
    content,
    flags=re.DOTALL
)

with open('lib/screens/home/home_tab.dart', 'w') as f:
    f.write(content)

