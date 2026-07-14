import 'package:flutter/material.dart';

import '../../../core/utils/haptic_engine.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared/shared_widgets.dart';
import '../../../widgets/viral/ai_quick_log_sheet.dart';

// ─────────────────────────────────────────────────────────────
// AI QUICK LOG FAB — glowing "Log Dose" pill button.
// Extracted verbatim from home_tab.dart (was _AiQuickLogFAB).
// ─────────────────────────────────────────────────────────────
class AiQuickLogFab extends StatefulWidget {
  const AiQuickLogFab({super.key});

  @override
  State<AiQuickLogFab> createState() => _AiQuickLogFabState();
}

class _AiQuickLogFabState extends State<AiQuickLogFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      onTapDown: (_) {
        HapticEngine.selection();
        setState(() => _pressed = true);
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => AiQuickLogSheet.show(context),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                // Neutral soft shadow (Cal AI: no brand-color glow on chrome).
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded,
                    color: Colors.black, size: 16),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.auto_awesome_rounded,
                  color: Colors.black87, size: 14),
              const SizedBox(width: 8),
              Text(
                'Log Dose',
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
