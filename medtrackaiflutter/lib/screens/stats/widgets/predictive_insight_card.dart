import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../domain/entities/predictive_insight.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared/shared_widgets.dart';

class PredictiveInsightCard extends StatelessWidget {
  final PredictiveInsight insight;

  const PredictiveInsightCard({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final color = _getColor(insight.type, L);

    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      tintColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12),
                  ],
                ),
                child: Center(
                  child: Text(_getEmoji(insight.type), style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  insight.title,
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    letterSpacing: -0.5,
                    color: L.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            insight.description,
            style: AppTypography.bodyMedium.copyWith(
              color: L.sub,
              height: 1.5,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          // Action button — Apple Elevated style
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: L.fill,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ADJUST NOTIFICATIONS',
                  style: AppTypography.labelSmall.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios_rounded, size: 10, color: L.sub),
              ],
            ),
          ),
        ],
      ),
    )
    .animate(
      key: ValueKey('predictive_entrance_${insight.title}'),
    )
    .fadeIn(duration: 600.ms)
    .slideY(begin: 0.1, end: 0);
  }

  // On-brand semantic colors — using AppColors tokens
  Color _getColor(PredictiveType type, AppThemeColors L) {
    switch (type) {
      case PredictiveType.eveningRisk:   return AppColors.purple;      // evening/night → purple
      case PredictiveType.weekendSlump:  return AppColors.accent;       // slump warning → orange accent
      case PredictiveType.travelRisk:    return AppColors.accent;       // travel → orange
      case PredictiveType.heatWarning:   return L.error;                // danger → red (from theme)
    }
  }

  String _getEmoji(PredictiveType type) {
    switch (type) {
      case PredictiveType.eveningRisk:  return '🌃';
      case PredictiveType.weekendSlump: return '⚖️';
      case PredictiveType.travelRisk:   return '🌐';
      case PredictiveType.heatWarning:  return '🌡️';
    }
  }
}
