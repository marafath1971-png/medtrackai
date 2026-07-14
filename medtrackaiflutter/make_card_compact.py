import re

with open('lib/screens/home/home_tab.dart', 'r') as f:
    content = f.read()

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

    final ringColors = isAllDone
        ? [L.green, const Color(0xFF00E676)]
        : [L.accent, Color.lerp(L.accent, Colors.teal, 0.355)!];
        
    final trackColor = isDark
        ? L.accent.withValues(alpha: 0.1)
        : L.accent.withValues(alpha: 0.05);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: L.border.withValues(alpha: 0.3),
          width: 0.5,
        ),
        boxShadow: AppShadows.premium,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tiny Smart Ring
          _AnimatedRing(
            percent: dosePct,
            colors: ringColors,
            trackColor: trackColor,
            size: 44,
            strokeWidth: 4,
            child: Icon(
              isAllDone ? Icons.check_rounded : Icons.medication_liquid_rounded,
              size: 20,
              color: isAllDone ? L.green : L.accent,
            ),
          ),
          const SizedBox(width: 14),
          
          // Compact Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAllDone ? 'All Done for Today ✨' : 'Daily Progress',
                  style: AppTypography.labelMedium.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isAllDone
                      ? 'You completed all doses.'
                      : '$takenCount of $total doses taken',
                  style: AppTypography.bodySmall.copyWith(
                    color: L.sub.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Streak Flame (only if active)
          if (streak > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9F0A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    '$streak',
                    style: TextStyle(
                      color: const Color(0xFFFF9F0A),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}"""

# Since _CalAiRingHero is rendered inside a SliverToBoxAdapter in home_tab.dart,
# we need to replace the entire class.
content = re.sub(
    r'class _CalAiRingHero extends StatelessWidget \{.*?\n\}\n(?=\nclass _ShareMilestoneCardCTA)',
    new_class + '\n',
    content,
    flags=re.DOTALL
)

# Also remove the padding wrapper around the hero since the margin is inside now
content = re.sub(
    r'SliverPadding\(\s*padding: const EdgeInsets\.fromLTRB\(20, 16, 20, 16\),\s*sliver: SliverToBoxAdapter\(\s*child: _CalAiRingHero\(.*?\),\s*\),\s*\),',
    r'SliverToBoxAdapter(\n                        child: Padding(\n                          padding: const EdgeInsets.only(top: 16, bottom: 8),\n                          child: _CalAiRingHero(\n                            takenCount: takenCount,\n                            total: total,\n                            dosePct: dosePct,\n                            streak: streak,\n                            remaining: remaining,\n                          ),\n                        ),\n                      ),',
    content,
    flags=re.DOTALL
)

with open('lib/screens/home/home_tab.dart', 'w') as f:
    f.write(content)

