import 'package:flutter/material.dart';

import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';

class HomeSectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const HomeSectionTitle({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.p12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                color: L.text,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            Semantics(
              button: true,
              label: actionLabel,
              child: AnimatedPressable(
                onTap: onAction,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: MedAiA11y.minTapTargetCompact,
                    minHeight: MedAiA11y.minTapTargetCompact,
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      actionLabel!,
                      style: AppTypography.labelMedium.copyWith(
                        color: L.sub,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
