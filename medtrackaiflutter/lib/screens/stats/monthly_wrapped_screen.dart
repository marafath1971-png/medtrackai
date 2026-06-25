import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../widgets/shared/shared_widgets.dart';

class MonthlyWrappedScreen extends StatefulWidget {
  const MonthlyWrappedScreen({super.key});

  @override
  State<MonthlyWrappedScreen> createState() => _MonthlyWrappedScreenState();
}

class _MonthlyWrappedScreenState extends State<MonthlyWrappedScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _nextPage() {
    HapticEngine.selection();
    if (_currentPage < 2) {
      _pageController.nextPage(duration: 400.ms, curve: Curves.easeInOut);
    } else {
      Navigator.pop(context);
    }
  }

  void _shareWrapped(AppState state, AppThemeColors L) {
    HapticEngine.heavyImpact();
    final adherence = (state.getAdherenceScore() * 100).round();
    Share.share('I crushed it this month! 🚀 $adherence% Adherence Score on Medai. #HealthWrapped #GenZHealth');
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final state = context.watch<AppState>();
    
    final adherence = (state.getAdherenceScore() * 100).round();
    final streak = state.getStreak();
    final totalDoses = state.history.values.fold<int>(0, (sum, list) => sum + list.length);

    return Scaffold(
      backgroundColor: L.bg,
      body: Stack(
        children: [
          // Dynamic mesh gradient background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    L.primary.withValues(alpha: 0.1),
                    L.secondary.withValues(alpha: 0.2),
                    L.bg,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 5.seconds, color: L.primary.withValues(alpha: 0.2)),

          SafeArea(
            child: Column(
              children: [
                // Top Progress Indicators
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: List.generate(3, (index) {
                      return Expanded(
                        child: AnimatedContainer(
                          duration: 300.ms,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 4,
                          decoration: BoxDecoration(
                            color: _currentPage >= index ? L.primary : L.border.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // Close Button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: BouncingButton(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: L.card.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close_rounded, color: L.text, size: 20),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: GestureDetector(
                    onTapUp: (details) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      if (details.globalPosition.dx > screenWidth / 2) {
                        _nextPage();
                      } else {
                        if (_currentPage > 0) {
                          HapticEngine.selection();
                          _pageController.previousPage(duration: 400.ms, curve: Curves.easeInOut);
                        }
                      }
                    },
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                        HapticEngine.lightImpact();
                      },
                      children: [
                        // Page 1: Total Doses
                        _WrappedPage(
                          L: L,
                          title: 'You took',
                          value: '$totalDoses',
                          subtitle: 'Doses this month.',
                          bottomText: 'Consistency is key. You crushed it! 💊',
                          icon: Icons.medication_liquid_rounded,
                        ),

                        // Page 2: Longest Streak
                        _WrappedPage(
                          L: L,
                          title: 'Your longest streak',
                          value: '$streak Days',
                          subtitle: 'Unstoppable Energy ⚡',
                          bottomText: 'You are literally glowing.',
                          icon: Icons.local_fire_department_rounded,
                        ),

                        // Page 3: Overall Score
                        _WrappedPage(
                          L: L,
                          title: 'Longevity Score',
                          value: '$adherence%',
                          subtitle: 'Top 5% of Medai Users 🚀',
                          bottomText: 'Keep protecting your peace and health.',
                          icon: Icons.bolt_rounded,
                          isLast: true,
                          onShare: () => _shareWrapped(state, L),
                        ),
                      ],
                    ),
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

class _WrappedPage extends StatelessWidget {
  final AppThemeColors L;
  final String title;
  final String value;
  final String subtitle;
  final String bottomText;
  final IconData icon;
  final bool isLast;
  final VoidCallback? onShare;

  const _WrappedPage({
    required this.L,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.bottomText,
    required this.icon,
    this.isLast = false,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 64, color: L.primary)
            .animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 32),
          Text(
            title,
            style: AppTypography.headlineMedium.copyWith(
              color: L.text,
              fontWeight: FontWeight.w900,
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.5, end: 0, curve: Curves.easeOutQuart),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.displayLarge.copyWith(
              color: L.primary,
              fontSize: 64,
              fontWeight: FontWeight.w900,
              height: 1.0,
              letterSpacing: -2.0,
            ),
          ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack).shimmer(duration: 2.seconds, delay: 1.seconds),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: AppTypography.titleLarge.copyWith(
              color: L.secondary,
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.5, end: 0, curve: Curves.easeOutQuart),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: L.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: L.border.withValues(alpha: 0.1)),
              boxShadow: AppShadows.neumorphic,
            ),
            child: Text(
              bottomText,
              style: AppTypography.bodyLarge.copyWith(
                color: L.text,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.5, end: 0),
          
          if (isLast) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onShare,
              style: ElevatedButton.styleFrom(
                backgroundColor: L.primary,
                foregroundColor: L.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                padding: const EdgeInsets.symmetric(vertical: 20),
                minimumSize: const Size(double.infinity, 60),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.ios_share_rounded, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Share to IG Story',
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 1200.ms).scale(),
          ],
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
