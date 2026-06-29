import 'package:flutter/material.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/med_ai_mascot.dart';

/// Premium empty/error state for scanner flows.
class ScanEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ScanEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return MedAiGlass(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MedAiMascot(size: 88, showGlow: false),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.titleLarge.copyWith(
              color: context.L.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: context.L.sub,
              height: 1.45,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            MedAiCTA(
              label: actionLabel!,
              onTap: onAction!,
              fullWidth: true,
            ),
          ],
        ],
      ),
    );
  }
}
