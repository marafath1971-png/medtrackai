import 'package:flutter/material.dart';

import '../../../core/constants/premium_photos.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../widgets/common/animated_pressable.dart';
import '../onboarding_l10n.dart';
import 'ob_widgets.dart';

/// Single high-conversion Onboarding Welcome Screen for Med AI.
///
/// Pixel-accurate implementation matching the official reference composition:
/// - Top: Full-bleed lifestyle hero photo (`ob_lifestyle_hero.jpg`) with soft gradient blend
/// - Background ambient accents: Soft electric blue swoosh on right edge, soft lavender circle bottom-left
/// - Editorial Headline (Left-aligned):
///   - "Take Your\nMedicine,\n" in deep navy `#0A194E`
///   - "Stress-Free." in electric royal blue `#0057FD`
/// - Subtitle: "Smart reminders. Peace of mind."
/// - Three Benefit Columns with clean vertical dividers:
///   - "Get Reminders" (Blue bell icon in soft container)
///   - "Stay Safe" (Green shield-check icon in soft container)
///   - "Track Progress" (Purple bar-chart icon in soft container)
/// - Pinned Primary CTA:
///   - Electric Royal Blue gradient pill button "Continue →"
///   - 3-step progress dots below the button (active elongated pill + 2 dots)
class ObMedAiWelcomeScreen extends StatelessWidget {
  final VoidCallback onGetStarted;

  const ObMedAiWelcomeScreen({
    super.key,
    required this.onGetStarted,
  });

  String _t(BuildContext context, String key, String fallback) {
    try {
      final res = ObL10n.of(context).t(key);
      return res == key ? fallback : res;
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.sizeOf(context).height;

    // Responsive hero photo height: ~45-48% of screen on standard phones
    final heroHeight = (screenHeight * 0.46).clamp(260.0, 420.0);

    const brandNavy = Color(0xFF0A194E);
    const primaryBlue = Color(0xFF0057FD);
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final bgCanvas = isDark ? const Color(0xFF0A0F1D) : Colors.white;

    return Scaffold(
      backgroundColor: bgCanvas,
      body: Stack(
        children: [
          // ── Ambient Background Accents ─────────────────────────────
          // 1. Soft blue curve on the right edge behind the headline
          Positioned(
            right: -70,
            top: heroHeight - 35,
            width: 200,
            height: 240,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: (isDark
                          ? const Color(0xFF1E3A8A)
                          : const Color(0xFFE8F1FE))
                      .withValues(alpha: isDark ? 0.22 : 0.65),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(120),
                    bottomLeft: Radius.circular(120),
                  ),
                ),
              ),
            ),
          ),

          // 2. Soft pastel lavender circular blob at bottom-left
          Positioned(
            left: -50,
            bottom: -35,
            width: 140,
            height: 140,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isDark
                          ? const Color(0xFF4C1D95)
                          : const Color(0xFFEDE9FE))
                      .withValues(alpha: isDark ? 0.22 : 0.55),
                ),
              ),
            ),
          ),

          // ── Scrollable Body Content ────────────────────────────────
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Hero Lifestyle Photo ───────────────────────
                      Semantics(
                        label: 'Med AI lifestyle companion hero',
                        image: true,
                        child: Stack(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: heroHeight,
                              child: Image.asset(
                                PremiumPhotos.lifestyleHero,
                                fit: BoxFit.cover,
                                alignment: const Alignment(0, -0.2),
                                filterQuality: FilterQuality.high,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  PremiumPhotos.welcomeHero,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            // Soft gradient fade into white/canvas
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: -1,
                              height: 90,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      bgCanvas.withValues(alpha: 0.0),
                                      bgCanvas.withValues(alpha: 0.65),
                                      bgCanvas,
                                    ],
                                    stops: const [0.0, 0.55, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).obFadeUp(),

                      // ── Content Area ───────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(26, 4, 26, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Editorial Headline ───────────────────
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 34,
                                  height: 1.14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.8,
                                  color: isDark ? Colors.white : brandNavy,
                                ),
                                children: [
                                  TextSpan(
                                    text: _t(
                                      context,
                                      'ob_takeYourMedicinePrefix',
                                      'Take Your\nMedicine,\n',
                                    ),
                                  ),
                                  TextSpan(
                                    text: _t(
                                      context,
                                      'ob_stressFreeSuffix',
                                      'Stress-Free.',
                                    ),
                                    style: const TextStyle(
                                      color: primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ).obFadeUp(delayMs: 60),

                            const SizedBox(height: 10),

                            // ── Subtitle ─────────────────────────────
                            Text(
                              _t(
                                context,
                                'ob_smartRemindersPeaceOfMind',
                                'Smart reminders. Peace of mind.',
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.2,
                                color: textSecondary,
                              ),
                            ).obFadeUp(delayMs: 100),

                            const SizedBox(height: 26),

                            // ── 3 Benefit Indicators with Dividers ───
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              child: Row(
                                children: [
                                  // Tile 1: Get Reminders
                                  Expanded(
                                    child: _BenefitPillar(
                                      icon: Icons.notifications_rounded,
                                      iconColor: primaryBlue,
                                      containerBg: isDark
                                          ? const Color(0xFF0057FD)
                                              .withValues(alpha: 0.18)
                                          : const Color(0xFFEBF3FE),
                                      label: _t(
                                        context,
                                        'ob_getReminders',
                                        'Get Reminders',
                                      ),
                                      textColor: isDark
                                          ? const Color(0xFFCBD5E1)
                                          : const Color(0xFF475569),
                                    ),
                                  ),

                                  // Subtle vertical divider 1
                                  Container(
                                    width: 1,
                                    height: 38,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.10)
                                        : const Color(0xFFE2E8F0),
                                  ),

                                  // Tile 2: Stay Safe
                                  Expanded(
                                    child: _BenefitPillar(
                                      icon: Icons.verified_user_rounded,
                                      iconColor: const Color(0xFF10B981),
                                      containerBg: isDark
                                          ? const Color(0xFF10B981)
                                              .withValues(alpha: 0.18)
                                          : const Color(0xFFE6F9F0),
                                      label: _t(
                                        context,
                                        'ob_staySafe',
                                        'Stay Safe',
                                      ),
                                      textColor: isDark
                                          ? const Color(0xFFCBD5E1)
                                          : const Color(0xFF475569),
                                    ),
                                  ),

                                  // Subtle vertical divider 2
                                  Container(
                                    width: 1,
                                    height: 38,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.10)
                                        : const Color(0xFFE2E8F0),
                                  ),

                                  // Tile 3: Track Progress
                                  Expanded(
                                    child: _BenefitPillar(
                                      icon: Icons.bar_chart_rounded,
                                      iconColor: const Color(0xFF8B5CF6),
                                      containerBg: isDark
                                          ? const Color(0xFF8B5CF6)
                                              .withValues(alpha: 0.18)
                                          : const Color(0xFFF3E8FF),
                                      label: _t(
                                        context,
                                        'ob_trackProgress',
                                        'Track Progress',
                                      ),
                                      textColor: isDark
                                          ? const Color(0xFFCBD5E1)
                                          : const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ).obFadeUp(delayMs: 140),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Pinned Bottom Section (CTA + Dots) ─────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
                decoration: BoxDecoration(
                  color: bgCanvas.withValues(alpha: 0.96),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Continue Button ────────────────────────────
                      AnimatedPressable(
                        onTap: () {
                          HapticEngine.selection();
                          onGetStarted();
                        },
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF0052FF), Color(0xFF1E6BFF)],
                            ),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: primaryBlue.withValues(alpha: 0.36),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _t(context, 'continue', 'Continue'),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 19,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── 3-Step Progress Indicator Dots ─────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 20,
                            height: 6,
                            decoration: BoxDecoration(
                              color: primaryBlue,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF475569)
                                  : const Color(0xFFCBD5E1),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF475569)
                                  : const Color(0xFFCBD5E1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).obFadeUp(delayMs: 180),
            ],
          ),
        ],
      ),
    );
  }
}

class _BenefitPillar extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color containerBg;
  final String label;
  final Color textColor;

  const _BenefitPillar({
    required this.icon,
    required this.iconColor,
    required this.containerBg,
    required this.label,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 42,
          decoration: BoxDecoration(
            color: containerBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
