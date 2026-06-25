import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/modals/premium_paywall.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      title: "Medication, Gamified.",
      description: "Build healthy habits with streaks, beautiful visualizers, and a mascot that grows with you.",
      icon: Icons.auto_awesome_rounded,
      color: const Color(0xFF6C63FF),
    ),
    _OnboardingPage(
      title: "AI Label Scanner",
      description: "Point your camera at any pill bottle to instantly log doses and check for risky interactions.",
      icon: Icons.camera_alt_rounded,
      color: const Color(0xFF00BFA5),
    ),
    _OnboardingPage(
      title: "Protect Your Family",
      description: "Manage multiple Caregiver profiles safely locked behind FaceID/TouchID.",
      icon: Icons.family_restroom_rounded,
      color: const Color(0xFFFF6584),
    ),
  ];

  void _nextPage() {
    HapticEngine.selection();
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() async {
    final state = context.read<AppState>();
    
    // Trigger Paywall right after onboarding completes for maximum conversion
    if (mounted && !state.isPremium) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (c) => const PremiumPaywall(),
      );
    }
    
    // Once they finish the cinematic flow (and see paywall), direct them to the Auth Screen
    if (mounted) {
      state.auth.phase = AppPhase.auth;
    }
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    
    return Scaffold(
      backgroundColor: L.bg,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final page = _pages[index];
              return _buildPageContent(page, L);
            },
          ),
          
          Positioned(
            bottom: 48 + MediaQuery.of(context).padding.bottom,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Indicators
                Row(
                  children: List.generate(_pages.length, (index) {
                    final isActive = _currentPage == index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: isActive ? 24 : 8,
                      decoration: BoxDecoration(
                        color: isActive ? L.primary : L.border.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                
                // Next Button
                GestureDetector(
                  onTap: _nextPage,
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: L.primary,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: L.primary.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _currentPage == _pages.length - 1 ? "Get Started" : "Next",
                        style: AppTypography.titleMedium.copyWith(
                          color: L.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ).animate(target: _currentPage == _pages.length - 1 ? 1 : 0)
                   .scaleX(begin: 1.0, end: 1.1)
                   .scaleY(begin: 1.0, end: 1.1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(_OnboardingPage page, AppThemeColors L) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(page.icon, size: 80, color: page.color)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .slideY(begin: -0.1, end: 0.1, duration: 1.seconds, curve: Curves.easeInOut),
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
          
          const SizedBox(height: 64),
          
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: AppTypography.displaySmall.copyWith(
              color: L.text,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
          
          const SizedBox(height: 16),
          
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge.copyWith(
              color: L.sub,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  _OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
