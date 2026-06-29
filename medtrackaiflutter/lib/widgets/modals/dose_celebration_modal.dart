import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/constants/med_ai_assets.dart';
import '../../widgets/common/med_ai_animation.dart';
import '../../theme/design_2026.dart';
import '../../core/utils/haptic_engine.dart';
import '../../services/share_service.dart';
import '../../services/review_service.dart';
import '../../providers/app_state.dart';

class DoseCelebrationModal extends StatelessWidget {
  final String medName;
  final String message;

  const DoseCelebrationModal({
    super.key,
    required this.medName,
    this.message =
        "Great job! Staying consistent is the key to a healthier you.",
  });

  static void show(BuildContext context, String medName) {
    HapticEngine.successScan();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.15),
      builder: (context) => DoseCelebrationModal(medName: medName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.zero, // Take full screen for backdrop filter
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Full-screen blurred backdrop ────────────────────────────
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  color: context.isDark
                      ? Colors.black.withValues(alpha: 0.45)
                      : const Color(0xFFF5F5F0).withValues(alpha: 0.35),
                ),
              ),
            ),
          ),

          // ── Centered Card Content and Confetti ─────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // ── Soft glowing halo behind card ──
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(alpha: 0.08),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        blurRadius: 100,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),

                // ── Rich Confetti Particle Burst ──
                ...List.generate(36, (i) {
                  // Deterministic pseudo-random parameters based on index
                  final angle = (i * 9.87) % (2 * math.pi);
                  final vx = math.cos(angle);
                  final vy = math.sin(angle);
                  final isCircle = (i % 3) != 0;
                  final size = 6.0 + (i % 4) * 3.0;
                  final durationMs = 650 + (i % 3) * 150;
                  final maxDist = 90.0 + (i % 6) * 20.0;
                  final rotationSpeed = ((i % 4) - 2) * 2.0;
                  
                  final color = [
                    AppColors.accent,
                    AppColors.success,
                    AppColors.amber,
                    AppColors.purple,
                    AppColors.blue,
                  ][i % 5];

                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: durationMs),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      // Parabolic gravity path
                      final currentDist = maxDist * value;
                      final dx = currentDist * vx;
                      // Gravity starts acting slowly
                      final dy = (currentDist * vy) + (100.0 * value * value);
                      
                      final opacity = (1.0 - value * 0.95).clamp(0.0, 1.0);
                      final rotation = rotationSpeed * value * math.pi;

                      return Transform.translate(
                        offset: Offset(dx, dy),
                        child: Opacity(
                          opacity: opacity,
                          child: Transform.rotate(
                            angle: isCircle ? 0.0 : rotation,
                            child: Container(
                              width: isCircle ? size : size * 1.8,
                              height: size,
                              decoration: BoxDecoration(
                                color: color,
                                shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
                                borderRadius: isCircle ? null : BorderRadius.circular(size * 0.4),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),

                // ── Main Card ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? Colors.black.withValues(alpha: 0.55)
                        : Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.25),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Animated success badge ──
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            MedAiAnimation(
                              kind: MedAiAnimationKind.celebrationCheck,
                              width: 120,
                              height: 120,
                            ),
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppThemeColors2026.electric.withValues(alpha: 0.08),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.check_rounded,
                                  color: AppThemeColors2026.wellness,
                                  size: 36,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

                      const SizedBox(height: 24),

                      // ── Med Name ──
                      Text(
                        medName,
                        textAlign: TextAlign.center,
                        style: AppTypography.headlineLarge.copyWith(
                          color: L.text,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 8),

                      // ── Dose Logged Badge ──
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'DOSE LOGGED ✓',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms),

                      const SizedBox(height: 20),

                      // ── Message ──
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyLarge.copyWith(
                          color: L.sub,
                          fontSize: 14.5,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ).animate().fadeIn(delay: 350.ms),

                      const SizedBox(height: 32),

                      // ── Actions ──
                      Row(
                        children: [
                          // Share Button
                          Expanded(
                            child: _InteractiveButton(
                              onTap: () {
                                ShareService.shareAchievement(
                                  title: '$medName Logged',
                                  subtitle: 'Staying consistent with my medication! 💪',
                                  emoji: '💊',
                                );
                              },
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  color: L.fill.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: L.border.withValues(alpha: 0.6),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.ios_share_rounded, color: L.text, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Share',
                                      style: AppTypography.labelLarge.copyWith(
                                        color: L.text,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Close / Awesome Button
                          Expanded(
                            flex: 2,
                            child: _InteractiveButton(
                              primary: true,
                              onTap: () {
                                final state = Provider.of<AppState>(context, listen: false);
                                final dosesMarked = state.profile?.dosesMarked ?? 0;
                                if (dosesMarked == 7 || dosesMarked == 14 || dosesMarked == 50) {
                                  ReviewService.requestReview();
                                }
                                Navigator.pop(context);
                              },
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF4A9E86), // Sage Green
                                      Color(0xFF327A65), // Dark Sage Green
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4A9E86).withValues(alpha: 0.25),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    'Awesome! ⚡',
                                    style: AppTypography.titleLarge.copyWith(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ).animate().scale(
                            delay: 600.ms,
                            duration: 400.ms,
                            curve: Curves.elasticOut,
                          ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms).scale(
                      begin: const Offset(0.9, 0.9),
                      curve: Curves.easeOutBack,
                      duration: 450.ms,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool primary;

  const _InteractiveButton({
    required this.child,
    required this.onTap,
    this.primary = false,
  });

  @override
  State<_InteractiveButton> createState() => _InteractiveButtonState();
}

class _InteractiveButtonState extends State<_InteractiveButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticEngine.light();
        setState(() => _scale = 0.96);
      },
      onTapUp: (_) {
        setState(() => _scale = 1.0);
      },
      onTapCancel: () {
        setState(() => _scale = 1.0);
      },
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
