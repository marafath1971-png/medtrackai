import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/haptic_engine.dart';
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared/shared_widgets.dart';

// ─────────────────────────────────────────────────────────────
// EMERGENCY WARNING CARD — shown after a severe (≥8/10) symptom
// logged in the last 24h. Extracted verbatim from home_tab.dart.
// ─────────────────────────────────────────────────────────────
class EmergencyWarningCard extends StatelessWidget {
  final Symptom symptom;
  const EmergencyWarningCard({super.key, required this.symptom});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.dangerRed,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.glow(const Color(0xFF991B1B), intensity: 0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emergency_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'CRITICAL MEDICAL ADVISORY',
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'You logged a severe symptom of ${symptom.name} (Severity: ${symptom.severity}/10) recently. If you are experiencing chest pain, difficulty breathing, sudden weakness, or any life-threatening symptoms, seek medical help immediately.',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          AnimatedPressable(
            onTap: () async {
              HapticEngine.heavyImpact();
              final url = Uri.parse('tel:911');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone_in_talk_rounded, color: L.error, size: 20),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'CALL EMERGENCY SERVICES (911)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTypography.labelLarge.copyWith(
                        color: L.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
