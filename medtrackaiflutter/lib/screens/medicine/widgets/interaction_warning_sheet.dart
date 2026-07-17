import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/med_ai_ui.dart';

class InteractionWarningSheet extends StatelessWidget {
  final String medicineName;
  final String interactionName;
  final String interactionDetails;

  const InteractionWarningSheet({
    super.key,
    required this.medicineName,
    required this.interactionName,
    required this.interactionDetails,
  });

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const InteractionWarningSheet(
        medicineName: "Lisinopril",
        interactionName: "Vitamin C",
        interactionDetails: "Taking this with Vitamin C reduces absorption. Space them out by 2 hours.",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    
    // Using a soft amber/warning tint
    final warningColor = Colors.amber.shade700;

    return Container(
      decoration: BoxDecoration(
        color: L.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: AppShadows.premium,
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(24, 12, 24, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: L.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.p32),
          
          // Icon and Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.p12),
                decoration: BoxDecoration(
                  color: warningColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_amber_rounded, color: warningColor, size: 28),
              ).animate().scale(delay: 100.ms, duration: 400.ms, curve: Curves.easeOutBack),
              const SizedBox(width: AppSpacing.p16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Wait! Interaction Alert",
                      style: AppTypography.headlineSmall.copyWith(
                        color: L.text,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ).animate().fade(delay: 200.ms).slideX(begin: 0.1, end: 0),
                    const SizedBox(height: AppSpacing.p4),
                    Text(
                      "$medicineName + $interactionName",
                      style: AppTypography.titleMedium.copyWith(
                        color: warningColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ).animate().fade(delay: 300.ms).slideX(begin: 0.1, end: 0),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.p24),
          
          // Details
          MedAiDepthCard(
            color: warningColor.withValues(alpha: 0.05),
            padding: const EdgeInsets.all(AppSpacing.p20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: warningColor, size: 20),
                const SizedBox(width: AppSpacing.p12),
                Expanded(
                  child: Text(
                    interactionDetails,
                    style: AppTypography.bodyLarge.copyWith(
                      color: L.text,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fade(delay: 400.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: AppSpacing.p32),

          // Actions
          Row(
            children: [
              Expanded(
                child: MedAiCTA(
                  label: "Got it",
                  secondary: true,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: AppSpacing.p12),
              Expanded(
                child: MedAiCTA(
                  label: "Adjust Time",
                  icon: Icons.access_time_filled,
                  onTap: () {
                    Navigator.of(context).pop();
                    // Open schedule configuration (hypothetical)
                  },
                ),
              ),
            ],
          ).animate().fade(delay: 500.ms, duration: 300.ms),
        ],
      ),
    );
  }
}
