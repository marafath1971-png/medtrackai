import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../shared/shared_widgets.dart';

class PremiumEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  const PremiumEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.emoji = '📝',
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Holographic/Glassmorphic Icon Container
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: L.card, // Glassmorphic card background
              shape: BoxShape.circle,
              border: Border.all(color: L.border.withValues(alpha: 0.1), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  blurRadius: 40,
                  spreadRadius: -10,
                ),
              ],
            ),
            child: Center(
              child: icon != null
                  ? Icon(icon, size: 44, color: AppColors.accent)
                  : Text(emoji,
                      style: AppTypography.displayLarge.copyWith(fontSize: 44)),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(
                  begin: 0,
                  end: -8,
                  duration: 2500.ms,
                  curve: Curves.easeInOutSine)
              .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.05, 1.05),
                  duration: 2500.ms)
              .shimmer(
                  duration: 3.seconds, color: Colors.white.withValues(alpha: 0.2)),

          const SizedBox(height: 32),

          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.headlineLarge.copyWith(
              color: L.text,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
            ),
          ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 12),

          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: L.sub,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.6,
              letterSpacing: -0.2,
            ),
          )
              .animate()
              .fadeIn(duration: 800.ms, delay: 200.ms)
              .slideY(begin: 0.1, end: 0),

          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 40),
            BouncingButton(
              onTap: onAction!,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                decoration: BoxDecoration(
                  gradient: AppGradients.accentOrange,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        actionLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.black, // Dark text on bright neon button
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 18),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 800.ms, delay: 400.ms)
                .scale(begin: const Offset(0.8, 0.8)),
          ],
        ],
      ),
    );
  }
}
