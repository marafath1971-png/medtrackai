import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/premium_graphics.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/premium_page_header.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../widgets/common/app_feedback.dart';

class ScannerHelpScreen extends StatelessWidget {
  const ScannerHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final reduceMotion = MedAiA11y.reducedMotion(context);

    return AppScaffold(
      showAurora: false,
      body: CustomScrollView(
        physics:
            const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: PremiumPageHeader(
              title: 'Scanning Tips',
              subtitle: 'Get better results in every scan',
              onBack: () {
                HapticEngine.selection();
                Navigator.pop(context);
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: L.card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: L.border.withValues(alpha: 0.35)),
                ),
                child: SvgPicture.asset(
                  PremiumGraphics.onboardingDiagnose,
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _TipCard(
                  icon: Icons.lightbulb_outline_rounded,
                  title: 'Good Lighting is Key',
                  description:
                      'Make sure the pill or bottle is well-lit. Avoid strong shadows or reflections on glossy labels.',
                  delay: 0,
                  reduceMotion: reduceMotion,
                ),
                const SizedBox(height: 16),
                _TipCard(
                  icon: Icons.center_focus_strong_rounded,
                  title: 'Keep it Centered',
                  description:
                      'Place the medication right in the middle of the brackets. Hold your phone steady until the scan completes.',
                  delay: 100,
                  reduceMotion: reduceMotion,
                ),
                const SizedBox(height: 16),
                _TipCard(
                  icon: Icons.qr_code_scanner_rounded,
                  title: 'Scan the NDC or Barcode',
                  description:
                      'For the highest accuracy, scan the barcode or the NDC number on the side of the prescription bottle.',
                  delay: 200,
                  reduceMotion: reduceMotion,
                ),
                const SizedBox(height: 16),
                _TipCard(
                  icon: Icons.mic_rounded,
                  title: 'Try Voice Mode',
                  description:
                      'If you can\'t scan the label, try using Voice Mode to simply speak the name of the medication.',
                  delay: 300,
                  reduceMotion: reduceMotion,
                ),
                const SizedBox(height: 48),
                Center(
                  child: _entrance(
                    reduceMotion,
                    MedAiCTA(
                      label: 'Contact Support',
                      fullWidth: false,
                      onTap: () {
                        HapticEngine.selection();
                        AppFeedback.toast(
                          context,
                          'Support chat opening soon…',
                          type: 'info',
                        );
                      },
                    ),
                    delay: 500.ms,
                  ),
                ),
                const SizedBox(height: 48),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _entrance(bool reduceMotion, Widget child, {Duration? delay}) {
    if (reduceMotion) return child;
    return child
        .animate(delay: delay)
        .fadeIn(duration: AppDurations.fast, curve: AppCurves.smooth)
        .slideY(begin: 0.2, end: 0, curve: AppCurves.smooth);
  }
}

class _TipCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final int delay;
  final bool reduceMotion;

  const _TipCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.delay,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    Widget card = MedAiDepthCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: MedAiA11y.minTapTarget,
            height: MedAiA11y.minTapTarget,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.accent, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: L.sub.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (reduceMotion) return card;
    return card
        .animate()
        .fadeIn(delay: delay.ms, duration: AppDurations.fast)
        .slideX(begin: 0.05, end: 0, curve: AppCurves.smooth);
  }
}
