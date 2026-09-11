import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../services/pin_service.dart';

/// Verifies [entered] against [profile]'s stored PIN and, on success, silently
/// upgrades a legacy plaintext PIN to a hash.
///
/// The upgrade happens here rather than at load time because this is the only
/// moment the plaintext PIN is actually known — a hash cannot be derived from
/// the stored value alone. It is also the natural point: the user has just
/// proved they know the PIN, so re-saving it costs them nothing.
///
/// Returns whether the PIN was correct. A failed upgrade never fails the
/// unlock: the user gets in, and the next successful unlock retries.
Future<bool> verifyAndUpgradePin(
  BuildContext context, {
  required ManagedProfile profile,
  required String entered,
}) async {
  final stored = profile.pin;
  if (!PinService.verifyPin(entered, stored)) return false;

  if (PinService.needsRehash(stored)) {
    try {
      final state = context.read<AppState>();
      await state.updateFamilyMember(
        profile.copyWith(pin: PinService.hashPin(entered)),
      );
    } catch (_) {
      // Best-effort: the unlock already succeeded, and leaving the legacy value
      // in place is no worse than before. Retried on the next unlock.
    }
  }

  return true;
}
