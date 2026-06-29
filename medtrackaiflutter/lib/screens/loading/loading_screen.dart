import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/med_ai_ui.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.oBg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/app_logo.png', width: 120, height: 120)
                .animate()
                .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0)),
            const SizedBox(height: 24),
            Text(
              'MedAI',
              style: AppTypography.displayLarge.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppColors.oText,
                letterSpacing: -1.0,
              ),
            )
                .animate()
                .fadeIn(delay: 400.ms, duration: 800.ms)
                .slideY(begin: 0.5, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 48),
            const SizedBox(
              width: 28,
              height: 2,
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                .animate()
                .fadeIn(delay: 800.ms)
                .shimmer(duration: 1500.ms, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}
