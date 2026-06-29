import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/med_ai_ui.dart';
import '../../core/utils/haptic_engine.dart';

class AIConsentSheet extends StatelessWidget {
  const AIConsentSheet({super.key});

  static Future<void> checkAndShow(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hasConsented = prefs.getBool('has_ai_consent') ?? false;

    if (!hasConsented && context.mounted) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (ctx) => const AIConsentSheet(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final reduceMotion = MedAiA11y.reducedMotion(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    Widget icon = Semantics(
      label: 'Security icon',
      child: Container(
        width: MedAiA11y.minTapTarget,
        height: MedAiA11y.minTapTarget,
        decoration: BoxDecoration(
          color: L.text.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.security_rounded, size: 24, color: L.text),
      ),
    );

    if (!reduceMotion) {
      icon = icon.animate().scale(
          duration: AppDurations.fast, curve: AppCurves.smooth);
    }

    return ClipRRect(
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(AppRadius.squircle)),
      child: MedAiGlass(
        radius: AppRadius.squircle,
        showBorder: false,
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: icon),
              const SizedBox(height: 24),
              Text(
                'AI Data Processing',
                style: AppTypography.titleMedium.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: L.text,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Med AI uses Google Gemini AI to analyze your imagery and data. By hitting continue, you agree to securely share your photo and prompts with our AI processing partner.',
                style: AppTypography.bodyMedium.copyWith(
                  color: L.sub,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              MedAiCTA(
                label: 'Continue',
                semanticsLabel: 'Accept AI data processing and continue',
                onTap: () async {
                  HapticEngine.heavy();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('has_ai_consent', true);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
