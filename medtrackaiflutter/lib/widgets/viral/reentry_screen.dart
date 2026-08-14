import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../theme/med_ai_ui.dart';
import '../../core/utils/haptic_engine.dart';
import '../../providers/app_state.dart';
import '../../screens/paywall/premium_paywall_overlay.dart';

/// High-conversion re-entry overlay — streak save / paywall moment.
class ReentryScreen extends StatefulWidget {
  final int missedDoses;
  final void Function({required bool streakSaved}) onDismiss;
  final String userName;

  const ReentryScreen({
    super.key,
    required this.missedDoses,
    required this.onDismiss,
    required this.userName,
  });

  @override
  State<ReentryScreen> createState() => _ReentryScreenState();
}

class _ReentryScreenState extends State<ReentryScreen> {
  bool _isApplyingFreeze = false;
  bool _freezeApplied = false;

  Future<void> _handleUseFreeze() async {
    if (_isApplyingFreeze) return;
    HapticEngine.selection();
    setState(() => _isApplyingFreeze = true);

    await context.read<AppState>().useStreakFreeze();

    HapticEngine.heavyImpact();
    if (!mounted) return;
    setState(() {
      _isApplyingFreeze = false;
      _freezeApplied = true;
    });

    await Future.delayed(const Duration(milliseconds: 1500));
    widget.onDismiss(streakSaved: true);
  }

  void _handleDismiss(bool streakSaved) {
    HapticEngine.selection();
    widget.onDismiss(streakSaved: streakSaved);
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final reduceMotion = MedAiA11y.reducedMotion(context);
    final state = context.watch<AppState>();
    final freezes = state.profile?.streakFreezes ?? 0;

    final isStreakMaintained = widget.missedDoses == 0 || _freezeApplied;
    final hasFreezes = freezes > 0;

    String emoji = '👋';
    String title = 'Welcome back, ${widget.userName}';
    String subtitle = 'Ready to continue your health journey?';

    if (isStreakMaintained) {
      emoji = '🔥';
      title = 'Streak maintained!';
      subtitle =
          'You\'re crushing it, ${widget.userName}. Let\'s keep the momentum going.';
    } else if (hasFreezes) {
      emoji = '🧊';
      title = 'Oops! You missed a dose.';
      subtitle =
          'You have $freezes streak freeze${freezes == 1 ? '' : 's'} to save your streak.';
    } else {
      emoji = '🥀';
      title = 'Streak lost...';
      subtitle =
          'You missed a dose and have no streak freezes left. Time to start fresh.';
    }

    if (_freezeApplied) {
      emoji = '🛡️';
      title = 'Streak saved!';
      subtitle = 'Freeze applied. Your streak is safe.';
    }

    Widget hero = MedAiDepthCard(
      accentGlow: false,
      padding: const EdgeInsets.all(28),
      radius: AppRadius.squircle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.displaySmall.copyWith(
              color: L.text,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: L.sub,
              height: 1.5,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );

    if (!reduceMotion) {
      hero = hero
          .animate(key: ValueKey('$emoji$title'))
          .fadeIn(duration: AppDurations.fast, curve: AppCurves.smooth)
          .scale(begin: const Offset(0.94, 0.94), curve: AppCurves.smooth);
    }

    return Material(
      color: L.bg.withValues(alpha: 0.92),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                hero,
                const SizedBox(height: 32),
                if (isStreakMaintained)
                  _entrance(
                    reduceMotion,
                    MedAiCTA(
                      label: 'Continue',
                      icon: Icons.arrow_forward_rounded,
                      onTap: () => _handleDismiss(true),
                    ),
                  )
                else if (hasFreezes) ...[
                  _entrance(
                    reduceMotion,
                    MedAiCTA(
                      label: _isApplyingFreeze
                          ? 'Applying...'
                          : 'Use streak freeze',
                      icon: Icons.ac_unit_rounded,
                      loading: _isApplyingFreeze,
                      onTap: _isApplyingFreeze ? null : _handleUseFreeze,
                    ),
                  ),
                  const SizedBox(height: 12),
                  MedAiCTA(
                    label: 'I\'ll start over',
                    secondary: true,
                    onTap: () => _handleDismiss(false),
                  ),
                ] else ...[
                  _entrance(
                    reduceMotion,
                    MedAiCTA(
                      label: 'Get premium freezes',
                      icon: Icons.star_rounded,
                      onTap: () {
                        HapticEngine.selection();
                        PremiumPaywallOverlay.show(
                          context,
                          triggerSource: 'reentry',
                        ).then((_) => _handleDismiss(false));
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  MedAiCTA(
                    label: 'Start new streak',
                    secondary: true,
                    onTap: () => _handleDismiss(false),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _entrance(bool reduceMotion, Widget child) {
    if (reduceMotion) return child;
    return child
        .animate()
        .fadeIn(duration: AppDurations.fast, delay: 150.ms, curve: AppCurves.smooth)
        .slideY(begin: 0.08, end: 0, curve: AppCurves.smooth);
  }
}
