import 'package:flutter/material.dart';
import '../../../widgets/common/premium_empty_state.dart';

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
    return PremiumEmptyState(
      compact: true,
      title: title,
      subtitle: message,
      mascotFeature: 'scan',
      icon: Icons.qr_code_scanner_rounded,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
