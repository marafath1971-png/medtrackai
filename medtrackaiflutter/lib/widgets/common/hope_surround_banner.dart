import 'package:flutter/material.dart';

import '../../theme/med_ai_ui.dart';

/// Soft trust surround — “#1 / made for you / you’ll succeed” micro-banner.
class HopeSurroundBanner extends StatelessWidget {
  final String? eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? tint;

  const HopeSurroundBanner({
    super.key,
    this.eyebrow,
    required this.title,
    required this.subtitle,
    this.icon = Icons.auto_awesome_rounded,
    this.tint,
  });

  factory HopeSurroundBanner.homeSuccess() => const HopeSurroundBanner(
        eyebrow: 'MADE FOR YOU',
        title: HopeVibe.numberOneFeel,
        subtitle: HopeVibe.manifestation,
        icon: Icons.workspace_premium_rounded,
        tint: AppColors.pastelMint,
      );

  @override
  Widget build(BuildContext context) {
    final bg = tint ?? AppColors.pastelMint;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.p16),
      decoration: HopeVibe.softCard(tint: bg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(AppRadius.s),
            ),
            child: Icon(icon, size: 20, color: AppColors.limeInk),
          ),
          const SizedBox(width: AppSpacing.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.accentDeep,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.p4),
                ],
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    // Pastel fill → fixed dark ink (never theme L.text).
                    color: AppColors.inkStrong,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.p4),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.grey600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
