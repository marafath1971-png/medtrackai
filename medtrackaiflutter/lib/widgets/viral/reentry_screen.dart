import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';

class ReentryScreen extends StatelessWidget {
  final int missedDoses;
  final VoidCallback onDismiss;
  final String userName;

  const ReentryScreen({
    super.key,
    required this.missedDoses,
    required this.onDismiss,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;

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
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: L.card,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.soft,
                  ),
                  child: const Center(
                    child: Text('👋', style: TextStyle(fontSize: 40)),
                  ),
                ).animate().scale(delay: 100.ms, curve: Curves.easeOutBack),
                
                const SizedBox(height: 24),
                
                Text(
                  'Welcome back, $userName',
                  textAlign: TextAlign.center,
                  style: AppTypography.displaySmall.copyWith(
                    color: L.text,
                    fontSize: 28,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                
                const SizedBox(height: 12),
                
                Text(
                  missedDoses > 0
                      ? 'You missed $missedDoses dose${missedDoses == 1 ? '' : 's'} while you were away. No judgment! Let\'s get back on track.'
                      : 'We missed you! Ready to continue your health journey?',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: L.sub,
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
                
                const SizedBox(height: 48),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticEngine.selection();
                      onDismiss();
                    },
                    icon: Icon(
                      missedDoses > 0 ? Icons.notification_important_rounded : Icons.arrow_forward_rounded,
                      size: 20,
                    ),
                    label: Text(
                      missedDoses > 0 ? 'Review Missed Doses' : 'Continue',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: L.text,
                      foregroundColor: L.bg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
