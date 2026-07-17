import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../theme/med_ai_ui.dart';
import '../../../../domain/entities/body_impact.dart';
import '../../../widgets/biohacking/pharma_timeline_widget.dart';
import '../../../widgets/biohacking/interactive_body_map.dart';

class BodyImpactCard extends StatelessWidget {
  final BodyImpactSummary impact;
  final VoidCallback? onAskAIPressed;
  final String? medName;

  const BodyImpactCard({
    super.key,
    required this.impact,
    this.onAskAIPressed,
    this.medName,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final reduceMotion = MedAiA11y.reducedMotion(context);

    Widget card = MedAiDepthCard(
      accentGlow: true,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.p20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.p8),
                  decoration: BoxDecoration(
                    color: AppColors.pastelMint,
                    borderRadius: BorderRadius.circular(AppRadius.s),
                  ),
                  child: Icon(Icons.monitor_heart_rounded,
                      size: 18, color: L.text),
                ),
                const SizedBox(width: AppSpacing.p12),
                Expanded(
                  child: Text(
                    HopeVibe.bodyImpactTitle,
                    style: AppTypography.titleMedium.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: L.border.withValues(alpha: 0.1)),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.p20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  HopeVibe.bodyImpactHow,
                  style: AppTypography.labelSmall.copyWith(
                    color: L.sub,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.p8),
                Text(
                  impact.mechanismOfAction.isNotEmpty
                      ? impact.mechanismOfAction
                      : 'AI is analyzing cellular impact mechanisms...',
                  style: AppTypography.bodyMedium.copyWith(
                    color: L.text.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.p24),
                InteractiveBodyMap(
                  activeSystems: impact.bodySystems,
                  medName: medName ?? 'Medicine',
                ),
                const SizedBox(height: AppSpacing.p24),
                PharmaTimelineWidget(
                  medName: medName ?? 'Medicine',
                  onsetMinutes: impact.onsetMinutes.toDouble(),
                  peakHours: impact.peakHours,
                  durationHours: impact.durationHours,
                  targetOrgans: impact.bodySystems,
                ),
                if (impact.bodySystems.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.p16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: impact.bodySystems
                        .map(
                          (s) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.p12,
                              vertical: AppSpacing.p8,
                            ),
                            decoration: BoxDecoration(
                              color: L.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppRadius.max),
                              border: Border.all(
                                color: L.accent.withValues(alpha: 0.26),
                                width: 0.7,
                              ),
                            ),
                            child: Text(
                              s,
                              style: AppTypography.labelSmall.copyWith(
                                color: L.text,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: AppSpacing.p24),
                if (impact.ahaFacts.isNotEmpty) ...[
                  _buildAhaCarousel(L, impact.ahaFacts),
                  const SizedBox(height: AppSpacing.p24),
                ],
                if (onAskAIPressed != null)
                  MedAiCTA(
                    label: 'Ask AI Assistant About This',
                    icon: Icons.chat_bubble_outline_rounded,
                    secondary: true,
                    onTap: onAskAIPressed,
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!reduceMotion) {
      card = card
          .animate()
          .fadeIn(duration: AppDurations.fast)
          .slideY(begin: 0.05, end: 0);
    }

    return card;
  }

  Widget _buildAhaCarousel(AppThemeColors L, List<String> facts) {
    return SizedBox(
      height: 125,
      child: ListView.builder(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: facts.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.p12),
            child: MedAiGlass(
              padding: const EdgeInsets.all(AppSpacing.p16),
              radius: AppRadius.m,
              child: SizedBox(
                width: 220,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: AppSpacing.p8),
                        Text(
                          'Did you know?',
                          style: AppTypography.labelSmall.copyWith(
                            color: L.text,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.p12),
                    Expanded(
                      child: Text(
                        facts[index],
                        style: AppTypography.bodySmall.copyWith(
                          color: L.sub,
                          height: 1.4,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
