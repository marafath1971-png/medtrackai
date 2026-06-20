import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';
import '../../providers/app_state.dart';
import '../../screens/paywall/premium_paywall_overlay.dart';
import '../../widgets/shared/shared_widgets.dart';

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

  void _handleUseFreeze() async {
    if (_isApplyingFreeze) return;
    HapticEngine.selection();
    setState(() => _isApplyingFreeze = true);
    
    final state = context.read<AppState>();
    await state.useStreakFreeze();
    
    HapticEngine.heavyImpact();
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
    final state = context.watch<AppState>();
    final freezes = state.profile?.streakFreezes ?? 0;
    
    // State determination
    final bool isStreakMaintained = widget.missedDoses == 0 || _freezeApplied;
    final bool hasFreezes = freezes > 0;

    String emoji = '👋';
    String title = 'Welcome back, ${widget.userName}';
    String subtitle = 'Ready to continue your health journey?';
    
    if (isStreakMaintained) {
      emoji = '🔥';
      title = 'Streak maintained!';
      subtitle = 'You\'re crushing it, ${widget.userName}. Let\'s keep the momentum going.';
    } else if (hasFreezes) {
      emoji = '🧊';
      title = 'Oops! You missed a dose.';
      subtitle = 'But wait... you have $freezes streak freeze${freezes == 1 ? '' : 's'} available to save your streak.';
    } else {
      emoji = '🥀';
      title = 'Streak lost...';
      subtitle = 'You missed a dose and have no streak freezes left. Time to start fresh.';
    }

    if (_freezeApplied) {
      emoji = '🛡️';
      title = 'Streak Saved!';
      subtitle = 'Freeze applied successfully. Your streak is safe.';
    }

    return Stack(
      children: [
        // Background blur
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              color: L.bg.withValues(alpha: 0.8),
            ),
          ),
        ),
        
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Emoji Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: L.card,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.soft,
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 48)),
                  ),
                ).animate(key: ValueKey(emoji))
                 .scale(duration: 400.ms, curve: Curves.easeOutBack)
                 .shimmer(delay: 500.ms, duration: 1000.ms),
                
                const SizedBox(height: 32),
                
                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.displaySmall.copyWith(
                    color: L.text,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ).animate(key: ValueKey(title)).fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
                
                const SizedBox(height: 16),
                
                // Subtitle
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: L.sub,
                    height: 1.5,
                    fontSize: 16,
                  ),
                ).animate(key: ValueKey(subtitle)).fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
                
                const SizedBox(height: 48),
                
                // Action Buttons
                if (isStreakMaintained)
                  SizedBox(
                    width: double.infinity,
                    child: BouncingButton(
                      onTap: () => _handleDismiss(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: L.text,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: L.text.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_forward_rounded, size: 20, color: L.bg),
                            const SizedBox(width: 8),
                            Text(
                              'CONTINUE',
                              style: AppTypography.labelLarge.copyWith(
                                fontFamily: 'Courier',
                                fontWeight: FontWeight.w900,
                                color: L.bg,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0)
                else if (hasFreezes) ...[
                  SizedBox(
                    width: double.infinity,
                    child: BouncingButton(
                      onTap: _handleUseFreeze,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _isApplyingFreeze 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.ac_unit_rounded, size: 20, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              _isApplyingFreeze ? 'APPLYING...' : 'USE STREAK FREEZE',
                              style: AppTypography.labelLarge.copyWith(
                                fontFamily: 'Courier',
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => _handleDismiss(false),
                    child: Text(
                      'I\'ll start over',
                      style: AppTypography.labelLarge.copyWith(
                        color: L.sub,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: BouncingButton(
                      onTap: () {
                        HapticEngine.selection();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const PremiumPaywallOverlay(),
                            fullscreenDialog: true,
                          ),
                        ).then((_) {
                          _handleDismiss(false);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star_rounded, size: 20, color: Colors.black),
                            const SizedBox(width: 8),
                            Text(
                              'GET PREMIUM FREEZES',
                              style: AppTypography.labelLarge.copyWith(
                                fontFamily: 'Courier',
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => _handleDismiss(false),
                    child: Text(
                      'Start new streak',
                      style: AppTypography.labelLarge.copyWith(
                        color: L.sub,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }
}
