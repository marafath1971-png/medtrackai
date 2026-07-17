import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/premium_graphics.dart';
import '../../theme/med_ai_ui.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/app_loading_indicator.dart';
import '../../widgets/common/premium_illustration_banner.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return AppScaffold(
      showAurora: true,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: MedAiDepthCard(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PremiumIllustrationBanner(
                  asset: PremiumGraphics.onboardingDiagnose,
                  height: 120,
                  padding: EdgeInsets.all(10),
                ),
                const SizedBox(height: 20),
                Text(
                  'MedTrack AI',
                  style: AppTypography.displaySmall.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    color: L.text,
                  ),
                ).medAiChain(
                  context,
                  (w) => w.animate().fadeIn(duration: 450.ms),
                ),
                const SizedBox(height: 8),
                Text(
                  'Preparing your health workspace',
                  style: AppTypography.bodySmall.copyWith(
                    color: L.sub,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                const AppLoadingIndicator(size: 18),
              ],
            ),
          ).medAiChain(
            context,
            (w) => w.animate().fadeIn(duration: 500.ms).slideY(begin: 0.05, end: 0),
          ),
        ),
      ),
    );
  }
}
