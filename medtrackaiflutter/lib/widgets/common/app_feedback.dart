import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/haptic_engine.dart';
import '../../providers/app_state.dart';
import '../../theme/med_ai_ui.dart';

/// Consistent success / error / undo feedback — prefer this over raw SnackBars.
abstract final class AppFeedback {
  static void toast(
    BuildContext context,
    String message, {
    String type = 'success',
  }) {
    context.read<AppState>().showToast(message, type: type);
  }

  /// Undo-capable strip (delete alarm, etc.). Matches brand floating style.
  static void undo(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
    Duration duration = const Duration(seconds: 3),
  }) {
    final L = context.L;
    HapticEngine.selection();
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTypography.bodySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(
          AppSpacing.p16,
          0,
          AppSpacing.p16,
          100 + MediaQuery.paddingOf(context).bottom,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundM),
        backgroundColor: L.text.withValues(alpha: 0.92),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.limeDeep,
          onPressed: () {
            HapticEngine.selection();
            onUndo();
          },
        ),
      ),
    );
  }
}
