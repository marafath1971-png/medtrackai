import 'package:flutter/material.dart';

import '../../core/utils/haptic_engine.dart';
import '../../domain/entities/medicine.dart';
import '../../services/share_service.dart';
import '../../theme/med_ai_ui.dart';
import '../common/animated_pressable.dart';

/// Post-scan success moment — hope, trust, worth-it, share.
/// Returns `'home'`, `'detail'`, or null if dismissed.
class ScanSuccessSheet extends StatelessWidget {
  final Medicine med;

  const ScanSuccessSheet({super.key, required this.med});

  static Future<String?> show(BuildContext context, {required Medicine med}) {
    HapticEngine.success();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => ScanSuccessSheet(med: med),
    );
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final hasReminder = med.schedule.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: L.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.p20,
        AppSpacing.gutter,
        AppSpacing.p24 + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: L.border.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.p24),
          Container(
            padding: const EdgeInsets.all(AppSpacing.p20),
            decoration: BoxDecoration(
              color: AppColors.pastelMint,
              borderRadius: BorderRadius.circular(AppRadius.l),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_rounded,
                      size: 34, color: AppColors.sageGreen),
                ),
                const SizedBox(height: AppSpacing.p16),
                Text(
                  HopeVibe.scanSuccessTitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineSmall.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.p8),
                Text(
                  HopeVibe.scanSuccessBody(med.name),
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: L.sub,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.p16),
          Row(
            children: [
              Expanded(
                child: _TrustChip(
                  icon: Icons.shield_rounded,
                  label: 'Safety saved',
                  tint: AppColors.pastelSky,
                ),
              ),
              const SizedBox(width: AppSpacing.p8),
              // Only promise a reminder when a schedule actually exists —
              // claiming "Reminder on" for an as-needed med with no schedule
              // would be a false trust signal on the app's core moment.
              Expanded(
                child: hasReminder
                    ? _TrustChip(
                        icon: Icons.schedule_rounded,
                        label: 'Reminder on',
                        tint: AppColors.pastelSun,
                      )
                    : _TrustChip(
                        icon: Icons.touch_app_rounded,
                        label: 'As needed',
                        tint: AppColors.pastelSun,
                      ),
              ),
              const SizedBox(width: AppSpacing.p8),
              Expanded(
                child: _TrustChip(
                  icon: Icons.favorite_rounded,
                  label: 'Made for you',
                  tint: AppColors.pastelLilac,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.p24),
          MedAiCTA(
            label: 'See it on Home',
            icon: Icons.home_rounded,
            onTap: () {
              HapticEngine.selection();
              Navigator.of(context).pop('home');
            },
          ),
          const SizedBox(height: AppSpacing.p12),
          MedAiCTA(
            label: 'Review medicine details',
            secondary: true,
            icon: Icons.menu_book_rounded,
            onTap: () {
              HapticEngine.selection();
              Navigator.of(context).pop('detail');
            },
          ),
          const SizedBox(height: AppSpacing.p12),
          Semantics(
            button: true,
            label: 'Share your win',
            child: AnimatedPressable(
              onTap: () async {
                HapticEngine.selection();
                await ShareService.shareScanResult(med.name);
              },
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                constraints: const BoxConstraints(
                  minHeight: MedAiA11y.minTapTarget,
                ),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.p12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.ios_share_rounded, size: 18, color: L.text),
                    const SizedBox(width: AppSpacing.p8),
                    Text(
                      HopeVibe.shareYourWin,
                      style: AppTypography.labelLarge.copyWith(
                        color: L.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color tint;

  const _TrustChip({
    required this.icon,
    required this.label,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.p8,
        vertical: AppSpacing.p12,
      ),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: L.text),
          const SizedBox(height: AppSpacing.p4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.labelSmall.copyWith(
              color: L.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
