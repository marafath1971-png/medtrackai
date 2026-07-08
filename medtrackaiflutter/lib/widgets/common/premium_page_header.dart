import 'package:flutter/material.dart';

import '../../core/utils/haptic_engine.dart';
import '../../theme/med_ai_ui.dart';
import 'animated_pressable.dart';

class PremiumPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;

  const PremiumPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          12,
          AppSpacing.screenPadding,
          16,
        ),
        child: Row(
          children: [
            if (onBack != null) ...[
              Semantics(
                button: true,
                label: 'Back',
                child: AnimatedPressable(
                  onTap: () {
                    HapticEngine.selection();
                    onBack!.call();
                  },
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: L.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: L.border.withValues(alpha: 0.45)),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: L.text,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.headlineMedium.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      fontSize: 24,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTypography.bodySmall.copyWith(
                        color: L.sub,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
