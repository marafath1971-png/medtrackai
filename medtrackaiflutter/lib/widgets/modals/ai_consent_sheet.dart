import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';
import '../common/animated_pressable.dart';

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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.L.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: context.L.text.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.security_rounded, size: 24, color: context.L.text),
            )
            .animate()
            .scale(duration: 400.ms, curve: Curves.easeOutBack),
            
            Text(
              'AI Data Processing',
              style: AppTypography.titleMedium.copyWith(
                fontSize: 24, 
                fontWeight: FontWeight.bold,
                color: context.L.text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            Text(
              'Med AI uses Google Gemini AI to analyze your imagery and data. By hitting continue, you agree to securely share your photo and prompts with our AI processing partner.',
              style: AppTypography.bodyMedium.copyWith(
                color: context.L.sub,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            AnimatedPressable(
              onTap: () async {
                HapticEngine.heavy();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('has_ai_consent', true);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: context.L.text,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Continue',
                    style: AppTypography.titleMedium.copyWith(
                      color: context.L.bg,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
