import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/constants/med_ai_assets.dart';
import '../../core/utils/haptic_engine.dart';
import '../../providers/app_state.dart';
import '../../services/review_service.dart';
import '../../services/share_service.dart';
import '../../theme/med_ai_ui.dart';
import '../../widgets/common/med_ai_animation.dart';

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
    HapticEngine.successDose();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      builder: (context) => DoseCelebrationModal(medName: medName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final reduceMotion = MedAiA11y.reducedMotion(context);
    final particleCount = reduceMotion ? 0 : 12;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (!reduceMotion)
              IgnorePointer(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.lime.withValues(alpha: 0.10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.limeDeep.withValues(alpha: 0.18),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),

            if (particleCount > 0)
              RepaintBoundary(
                child: Stack(
                  alignment: Alignment.center,
                  children: List.generate(particleCount, (i) {
                    final angle = (i * 9.87) % (2 * math.pi);
                    final vx = math.cos(angle);
                    final vy = math.sin(angle);
                    final isCircle = (i % 3) != 0;
                    final size = 6.0 + (i % 4) * 2.0;
                    final durationMs = 500 + (i % 3) * 120;
                    final maxDist = 70.0 + (i % 4) * 16.0;
                    final color = [
                      AppColors.lime,
                      AppColors.limeDeep,
                      AppColors.amber,
                      AppColors.pastelSky,
                    ][i % 4];

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: durationMs),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        final currentDist = maxDist * value;
                        final dx = currentDist * vx;
                        final dy = (currentDist * vy) + (70.0 * value * value);
                        final opacity = (1.0 - value * 0.95).clamp(0.0, 1.0);

                        return Transform.translate(
                          offset: Offset(dx, dy),
                          child: Opacity(
                            opacity: opacity,
                            child: Container(
                              width: isCircle ? size : size * 1.6,
                              height: size,
                              decoration: BoxDecoration(
                                color: color,
                                shape: isCircle
                                    ? BoxShape.circle
                                    : BoxShape.rectangle,
                                borderRadius: isCircle
                                    ? null
                                    : BorderRadius.circular(size * 0.4),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
              decoration: BoxDecoration(
                color: context.isDark ? L.card : Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.limeDeep.withValues(alpha: 0.22),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (!reduceMotion)
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
                            color: AppColors.lime.withValues(alpha: 0.18),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check_rounded,
                              color: AppColors.limeInk,
                              size: 36,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate(target: reduceMotion ? 0 : 1)
                      .scale(
                        duration: reduceMotion ? 0.ms : 500.ms,
                        curve: AppCurves.emilOut,
                      ),

                  const SizedBox(height: 24),

                  Text(
                    medName,
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineLarge.copyWith(
                      color: L.text,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                  ),

                  const SizedBox(height: 20),

                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyLarge.copyWith(
                      color: L.sub,
                      fontSize: 14.5,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Expanded(
                        child: _InteractiveButton(
                          onTap: () {
                            ShareService.shareAchievement(
                              title: '$medName Logged',
                              subtitle:
                                  'Staying consistent with my medication!',
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
                                Icon(Icons.ios_share_rounded,
                                    color: L.text, size: 16),
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
                      Expanded(
                        flex: 2,
                        child: _InteractiveButton(
                          primary: true,
                          onTap: () {
                            final state =
                                Provider.of<AppState>(context, listen: false);
                            final dosesMarked = state.profile?.dosesMarked ?? 0;
                            if (dosesMarked == 7 ||
                                dosesMarked == 14 ||
                                dosesMarked == 50) {
                              ReviewService.requestReview();
                            }
                            Navigator.pop(context);
                          },
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.lime,
                                  AppColors.limeDeep,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.limeDeep
                                      .withValues(alpha: 0.22),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'Awesome!',
                                style: AppTypography.titleLarge.copyWith(
                                  color: AppColors.limeInk,
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
                  ),
                ],
              ),
            ),
          ],
        ),
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
