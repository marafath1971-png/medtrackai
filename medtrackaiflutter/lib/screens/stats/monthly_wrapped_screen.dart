import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../../providers/app_state.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/premium_page_header.dart';

class MonthlyWrappedScreen extends StatefulWidget {
  const MonthlyWrappedScreen({super.key});

  @override
  State<MonthlyWrappedScreen> createState() => _MonthlyWrappedScreenState();
}

class _MonthlyWrappedScreenState extends State<MonthlyWrappedScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticEngine.selection();
    if (_currentPage < 2) {
      final duration = MedAiA11y.reducedMotion(context)
          ? Duration.zero
          : const Duration(milliseconds: 400);
      _pageController.nextPage(duration: duration, curve: Curves.easeInOut);
    } else {
      Navigator.pop(context);
    }
  }

  void _shareWrapped(AppState state) {
    HapticEngine.heavyImpact();
    final adherence = (state.getAdherenceScore() * 100).round();
    SharePlus.instance.share(
      ShareParams(
        text:
            'I crushed it this month! 🚀 $adherence% Adherence Score on Medai. #HealthWrapped #GenZHealth',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final state = context.watch<AppState>();
    final reduceMotion = MedAiA11y.reducedMotion(context);

    final adherence = (state.getAdherenceScore() * 100).round();
    final streak = state.getStreak();
    // Count only doses actually taken (was summing every history entry,
    // inflating the number with skipped/missed doses).
    final totalDoses = state.history.values.fold<int>(
        0, (sum, list) => sum + list.where((e) => e.taken).length);

    // Honest, tiered copy — never a fabricated "top 5%" claim, and
    // forgiveness-first at the low end (blueprint §4 tone).
    final (scoreTag, scoreNote) = adherence >= 90
        ? ('Elite consistency 🚀', 'Keep protecting your peace and health.')
        : adherence >= 70
            ? ('Strong month 💪', 'A little tighter next month — you\'ve got this.')
            : ('Building momentum 🌱',
                'Every dose counts. Next month starts fresh.');

    return AppScaffold(
      showAurora: true,
      body: Stack(
        children: [
          if (!reduceMotion)
            Positioned.fill(
              child: IgnorePointer(
                child: AuroraBackground(opacity: context.isDark ? 0.4 : 0.28),
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                PremiumPageHeader(
                  title: 'Monthly wrapped',
                  subtitle: 'Slide ${_currentPage + 1} of 3',
                  onBack: () => Navigator.pop(context),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Semantics(
                    label: 'Slide ${_currentPage + 1} of 3',
                    child: Row(
                      children: List.generate(3, (index) {
                        return Expanded(
                          child: AnimatedContainer(
                            duration: MedAiA11y.motion(
                                context, const Duration(milliseconds: 300)),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 4,
                            decoration: BoxDecoration(
                              gradient: _currentPage >= index
                                  ? LinearGradient(
                                      colors: [
                                        L.accent,
                                        L.accent.withValues(alpha: 0.7)
                                      ],
                                    )
                                  : null,
                              color: _currentPage >= index
                                  ? null
                                  : L.border.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Semantics(
                    label: 'Tap right to go forward, left to go back',
                    child: GestureDetector(
                      onTapUp: (details) {
                        final screenWidth =
                            MediaQuery.of(context).size.width;
                        if (details.globalPosition.dx > screenWidth / 2) {
                          _nextPage();
                        } else if (_currentPage > 0) {
                          HapticEngine.selection();
                          final duration = reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 400);
                          _pageController.previousPage(
                              duration: duration, curve: Curves.easeInOut);
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
                          _WrappedPage(
                            L: L,
                            title: 'You took',
                            value: '$totalDoses',
                            subtitle: 'Doses this month.',
                            bottomText:
                                'Consistency is key. You crushed it! 💊',
                            icon: Icons.medication_liquid_rounded,
                          ),
                          _WrappedPage(
                            L: L,
                            title: 'Your longest streak',
                            value: '$streak Days',
                            subtitle: 'Unstoppable Energy ⚡',
                            bottomText: 'You are literally glowing.',
                            icon: Icons.local_fire_department_rounded,
                          ),
                          _WrappedPage(
                            L: L,
                            title: 'Longevity Score',
                            value: '$adherence%',
                            subtitle: scoreTag,
                            bottomText: scoreNote,
                            icon: Icons.bolt_rounded,
                            isLast: true,
                            onShare: () => _shareWrapped(state),
                          ),
                        ],
                      ),
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
    final reduceMotion = MedAiA11y.reducedMotion(context);

    Widget withMotion(Widget child, {Duration delay = Duration.zero}) {
      if (reduceMotion) return child;
      return child.animate(delay: delay).fadeIn(duration: AppDurations.fast);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          withMotion(
            Icon(icon, size: 64, color: L.accent),
            delay: 200.ms,
          ),
          const SizedBox(height: 32),
          withMotion(
            Text(
              title,
              style: AppTypography.headlineMedium.copyWith(
                color: L.text,
                fontWeight: FontWeight.w800,
              ),
            ),
            delay: 300.ms,
          ),
          const SizedBox(height: 8),
          withMotion(
            Text(
              value,
              style: AppTypography.displayLarge.copyWith(
                color: L.accent,
                fontSize: 64,
                fontWeight: FontWeight.w800,
                height: 1.0,
                letterSpacing: -1.5,
              ),
            ),
            delay: 400.ms,
          ),
          const SizedBox(height: 16),
          withMotion(
            Text(
              subtitle,
              style: AppTypography.titleLarge.copyWith(
                color: L.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            delay: 500.ms,
          ),
          const Spacer(),
          withMotion(
            MedAiGlass(
              padding: const EdgeInsets.all(24),
              child: Text(
                bottomText,
                style: AppTypography.bodyLarge.copyWith(
                  color: L.text,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            delay: 600.ms,
          ),
          if (isLast) ...[
            const SizedBox(height: 24),
            withMotion(
              MedAiCTA(
                label: 'Share to IG Story',
                icon: Icons.ios_share_rounded,
                onTap: onShare,
                semanticsLabel: 'Share monthly wrapped to Instagram story',
              ),
              delay: 700.ms,
            ),
          ],
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
