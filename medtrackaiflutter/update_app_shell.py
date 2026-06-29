import re

with open('lib/screens/app_shell.dart', 'r') as f:
    content = f.read()

# Replace _buildBottomIsland, _buildScanButton, _buildNavItem
new_widgets_code = """
  Widget _buildBottomIsland(AppThemeColors L, int unseenAlerts) {
    const labels = ['Home', 'Analytics', 'Alarms', 'Circle'];
    const iconPaths = [
      MedAiAssets.iconHome,
      MedAiAssets.iconAnalytics,
      MedAiAssets.iconAlarms,
      MedAiAssets.iconFamily,
    ];
    final badges = [0, 0, 0, unseenAlerts];
    final currentIndex = _calculateSelectedIndex(context);

    // Dynamic Island container
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: context.isDark
                    ? L.card.withValues(alpha: 0.65)
                    : Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: context.isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : L.border.withValues(alpha: 0.5),
                  width: 0.5,
                ),
                boxShadow: context.isDark
                    ? AppShadows.premium
                    : [
                        BoxShadow(
                          color: AppColors.eatoNavy.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavItem(0, iconPaths[0], labels[0], L, badges[0], currentIndex),
                  _buildNavItem(1, iconPaths[1], labels[1], L, badges[1], currentIndex),
                  const SizedBox(width: 72), // Space for breakout scan button
                  _buildNavItem(2, iconPaths[2], labels[2], L, badges[2], currentIndex),
                  _buildNavItem(3, iconPaths[3], labels[3], L, badges[3], currentIndex),
                ],
              ),
            ),
          ),
        ),
        
        // Breakout Scan Button
        Positioned(
          bottom: 8, // Floats slightly above the bar
          child: _buildScanButton(L),
        ),
      ],
    );
  }

  Widget _buildScanButton(AppThemeColors L) {
    return Semantics(
      button: true,
      label: 'Smart Scan',
      child: AnimatedPressable(
        onTap: _openScan,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: context.isDark
                  ? [L.accent, L.accent.withValues(alpha: 0.7)]
                  : [AppColors.eatoGold, AppColors.eatoGold.withValues(alpha: 0.8)],
            ),
            boxShadow: [
              BoxShadow(
                color: (context.isDark ? L.accent : AppColors.eatoGold).withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.3),
                blurRadius: 0,
                spreadRadius: 1,
                offset: const Offset(0, 1), // Inner highlight
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Center(
            child: AppSvgIcon(
              assetPath: MedAiAssets.iconScan,
              size: 26,
              color: Colors.white,
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scaleXY(begin: 1.0, end: 1.05, duration: 1.5.seconds, curve: Curves.easeInOut),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String iconPath, String label, AppThemeColors L, int cnt, int currentIndex) {
    final selected = currentIndex == index;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: AnimatedPressable(
        onTap: () {
          HapticEngine.selection();
          _navigateToTab(index);
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: selected
              ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
              : const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: selected
              ? BoxDecoration(
                  color: L.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(30),
                )
              : const BoxDecoration(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  AppSvgIcon(
                    assetPath: iconPath,
                    size: 24,
                    color: selected ? L.accent : L.sub.withValues(alpha: 0.5),
                  ),
                  if (cnt > 0)
                    Positioned(
                      top: -2,
                      right: -4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: L.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: L.card, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: L.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
"""

content = re.sub(
    r'  Widget _buildBottomIsland\(.*?Widget _buildNavItem\(.*?\}\n'
    r'  \}\n\}', 
    new_widgets_code.strip() + '\n}', 
    content, 
    flags=re.DOTALL
)

with open('lib/screens/app_shell.dart', 'w') as f:
    f.write(content)

