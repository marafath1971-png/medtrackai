import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../theme/app_theme.dart';
import '../../../../domain/entities/body_impact.dart';
import '../../../widgets/biohacking/pharma_timeline_widget.dart';

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

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: L.meshBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: L.border.withValues(alpha: 0.1), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: L.card,
              border: Border(
                bottom: BorderSide(
                  color: L.border.withValues(alpha: 0.1),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: L.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('🧬', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'BODY IMPACT',
                    style: AppTypography.titleMedium.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Mechanism of Action
                Text(
                  'HOW IT WORKS',
                  style: AppTypography.labelSmall.copyWith(
                    color: L.sub.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  impact.mechanismOfAction.isNotEmpty
                      ? impact.mechanismOfAction
                      : 'AI is analyzing cellular impact mechanisms...',
                  style: AppTypography.bodyMedium.copyWith(
                    color: L.text.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Journey Timeline & Body Systems (Pharmacokinetics)
                PharmaTimelineWidget(
                  medName: medName ?? 'Medicine',
                  onsetMinutes: impact.onsetMinutes.toDouble(),
                  peakHours: impact.peakHours,
                  durationHours: impact.durationHours,
                  targetOrgans: impact.bodySystems,
                ),
                const SizedBox(height: 24),

                // 3. Wow Facts Carousel
                if (impact.ahaFacts.isNotEmpty) ...[
                  _buildAhaCarousel(L, impact.ahaFacts),
                  const SizedBox(height: 24),
                ],

                // Ask AI CTA
                if (onAskAIPressed != null)
                  GestureDetector(
                    onTap: onAskAIPressed,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: L.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: L.secondary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('💬', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(
                            'Ask AI Coach about this',
                            style: AppTypography.labelLarge.copyWith(
                              color: L.secondary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().scale(
                      duration: 400.ms,
                      curve: Curves.easeOutCubic,
                      delay: 200.ms),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildAhaCarousel(AppThemeColors L, List<String> facts) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: facts.length,
        itemBuilder: (context, index) {
          return Container(
            width: 250,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: L.text.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Text(
                      'DID YOU KNOW?',
                      style: AppTypography.labelSmall.copyWith(
                        color: L.text,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    facts[index],
                    style: AppTypography.bodySmall.copyWith(
                      color: L.sub,
                      height: 1.3,
                      fontSize: 12,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
