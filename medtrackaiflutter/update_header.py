import re

with open('lib/screens/home/widgets/home_header.dart', 'r') as f:
    content = f.read()

# Replace the build method contents down to the Spacer
new_header_code = """
  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final isScrolled = scrollOffset > 20;
    final reduceMotion = MedAiA11y.reducedMotion(context);
    final userName = state.activeProfile?.name ?? state.profile?.name ?? 'Arafat';

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isScrolled ? 24 : 0,
          sigmaY: isScrolled ? 24 : 0,
        ),
        child: AnimatedContainer(
          duration: MedAiA11y.motion(context, const Duration(milliseconds: 300)),
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          decoration: BoxDecoration(
            color: isScrolled
                ? (context.isDark ? L.bg : Colors.white).withValues(alpha: 0.85)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: L.border.withValues(alpha: isScrolled ? 0.08 : 0.0),
                width: 0.5,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(
              children: [
                // ── User Avatar & Greeting ──
                AnimatedPressable(
                  onTap: () {
                    HapticEngine.selection();
                    onTap?.call();
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: L.accent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                          style: AppTypography.titleLarge.copyWith(
                            color: L.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getFormattedDate(),
                            style: AppTypography.labelSmall.copyWith(
                              color: L.sub.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              letterSpacing: 1.0,
                            ),
                          ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0),
                          const SizedBox(height: 2),
                          Text(
                            'Hi, $userName',
                            style: AppTypography.headlineSmall.copyWith(
                              color: L.text,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
"""

content = re.sub(
    r'  @override\n  Widget build\(BuildContext context\) \{.*?const Spacer\(\),',
    new_header_code.strip('\n'),
    content,
    flags=re.DOTALL
)

# Replace _getGreetingLine() with _getFormattedDate()
date_func = """
  String _getFormattedDate() {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}'.toUpperCase();
  }
"""
content = re.sub(
    r'  String _getGreetingLine\(\) \{.*?\}',
    date_func.strip('\n'),
    content,
    flags=re.DOTALL
)

with open('lib/screens/home/widgets/home_header.dart', 'w') as f:
    f.write(content)

