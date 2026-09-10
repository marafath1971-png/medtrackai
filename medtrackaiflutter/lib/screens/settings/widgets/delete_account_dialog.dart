import 'package:flutter/material.dart';

import '../../../core/utils/haptic_engine.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../l10n/app_localizations.dart';

/// The single confirmation for permanent account deletion.
///
/// There were two, reached by different routes, with different safety:
///
/// * `profile_tab._confirmDeleteAccount` — the one behind Home's gear icon,
///   and so the one users actually reach — was a plain AlertDialog whose
///   "Delete" sat at the same visual weight as "Cancel". One stray tap erased
///   every medication record and the account.
/// * `global_settings_screen._confirmDelete` had haptics, a red title and a
///   warning banner, but still confirmed on a single tap.
///
/// Which safeguards a user got depended on how they navigated. This replaces
/// both with one dialog that requires the word DELETE to be typed, so the
/// action cannot be completed by muscle memory or a mis-tap.
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  /// Returns true only if the user typed the confirmation and confirmed.
  static Future<bool> show(BuildContext context) async {
    HapticEngine.heavyImpact();
    final result = await showDialog<bool>(
      context: context,
      // A mis-tap outside must not be a decision either way, but it should not
      // be the thing that deletes an account — barrier dismiss cancels.
      barrierDismissible: true,
      builder: (_) => const DeleteAccountDialog(),
    );
    return result ?? false;
  }

  /// The word the user has to type. Uppercase and checked case-insensitively
  /// after trimming, so autocapitalise on mobile does not fight the user.
  static const confirmWord = 'DELETE';

  /// Whether [input] unlocks the destructive action.
  @visibleForTesting
  static bool isConfirmed(String input) =>
      input.trim().toUpperCase() == confirmWord;

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _controller = TextEditingController();
  bool _armed = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final armed = DeleteAccountDialog.isConfirmed(_controller.text);
      if (armed != _armed) setState(() => _armed = armed);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final L = context.L;
    const danger = Color(0xFFB4494A);

    return AlertDialog(
      backgroundColor: L.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.l),
      ),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: danger, size: 22),
          const SizedBox(width: AppSpacing.p8),
          Expanded(
            child: Text(
              l10n.settingsDeleteAccount,
              style: AppTypography.titleLarge.copyWith(
                color: L.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.settingsThisPermanentlyErasesYourMedicationHistory,
            style: AppTypography.bodySmall.copyWith(color: L.sub, height: 1.5),
          ),
          const SizedBox(height: AppSpacing.p16),
          Text(
            l10n.settingsTypeToConfirm(DeleteAccountDialog.confirmWord),
            style: AppTypography.caption.copyWith(
              color: L.sub,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.p8),
          TextField(
            controller: _controller,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.characters,
            style: AppTypography.bodyMedium.copyWith(
              color: L.text,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            decoration: InputDecoration(
              hintText: DeleteAccountDialog.confirmWord,
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: L.sub.withValues(alpha: 0.5),
                letterSpacing: 1.5,
              ),
              filled: true,
              fillColor: L.card,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.p12, vertical: AppSpacing.p12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.s),
                borderSide: BorderSide(color: L.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.s),
                borderSide: BorderSide(color: L.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.s),
                borderSide: const BorderSide(color: danger, width: 1.5),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            l10n.settingsKeepMyAccount,
            style: AppTypography.labelLarge.copyWith(
              color: L.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        // Disabled until the word is typed: the destructive choice must never
        // be the one a stray tap lands on.
        TextButton(
          onPressed: _armed
              ? () {
                  HapticEngine.heavyImpact();
                  Navigator.pop(context, true);
                }
              : null,
          child: Text(
            l10n.settingsDeleteForever,
            style: AppTypography.labelLarge.copyWith(
              color: _armed ? danger : L.sub.withValues(alpha: 0.4),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
