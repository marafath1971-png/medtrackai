import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/logger.dart';

/// Owns the user's referral identity and the give-a-month / get-a-month loop.
///
/// v1 is client-side and attribution-first: it generates a stable per-install
/// referral code, remembers an inbound code from a deep link until the user
/// signs up, and records who redeemed what. The actual premium *grant* is
/// intentionally routed through [pendingRewardOnRedeem] so it can be hooked to
/// the real entitlement system (or a server) when monetization is switched on —
/// without a backend, a purely client-side grant would be trivially abusable.
class ReferralService {
  static const _keyMyCode = 'referral_my_code';
  static const _keyPendingInbound = 'referral_pending_inbound';
  static const _keyRedeemedInbound = 'referral_redeemed_inbound';
  static const _keySentCount = 'referral_sent_count';

  /// Same unambiguous charset used for care-team invite codes.
  static const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// Returns the user's stable referral code, generating + persisting one on
  /// first call. Six chars, collision-tolerant at this scale.
  static Future<String> myCode() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_keyMyCode);
    if (existing != null && existing.isNotEmpty) return existing;
    final code = _generate();
    await prefs.setString(_keyMyCode, code);
    return code;
  }

  static String _generate() {
    final r = Random.secure();
    return List.generate(6, (_) => _codeChars[r.nextInt(_codeChars.length)])
        .join();
  }

  /// Builds the shareable invite URL for [code]. The `/r/<code>` shape is what
  /// [LinkService] already parses into `onReferralDetected`.
  static String inviteUrl(String code) => 'https://medai.app/r/$code';

  /// Records an inbound referral code (from a deep link) so it can be applied
  /// when the user finishes signing up. Ignores the user's own code and any
  /// code once one has already been redeemed.
  static Future<void> setPendingInbound(String code) async {
    final clean = code.trim().toUpperCase();
    if (clean.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_keyRedeemedInbound) != null) return; // one per user
    if (clean == prefs.getString(_keyMyCode)) return; // no self-referral
    await prefs.setString(_keyPendingInbound, clean);
    appLogger.i('[Referral] Pending inbound code stored: $clean');
  }

  static Future<String?> pendingInbound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPendingInbound);
  }

  /// Consumes a pending inbound code at signup: marks it redeemed and clears
  /// the pending slot. Returns the redeemed code, or null if there was none.
  /// The caller is responsible for granting the reward (see class doc).
  static Future<String?> redeemPendingInbound() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getString(_keyPendingInbound);
    if (pending == null || pending.isEmpty) return null;
    await prefs.setString(_keyRedeemedInbound, pending);
    await prefs.remove(_keyPendingInbound);
    appLogger.i('[Referral] Redeemed inbound code: $pending');
    return pending;
  }

  /// The code this user redeemed at signup, if any (for "invited by" display).
  static Future<String?> redeemedInbound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRedeemedInbound);
  }

  /// Local count of invites this user has sent (for a "N friends invited"
  /// stat). Real conversions require server attribution.
  static Future<int> sentCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySentCount) ?? 0;
  }

  static Future<void> incrementSentCount() async {
    final prefs = await SharedPreferences.getInstance();
    final next = (prefs.getInt(_keySentCount) ?? 0) + 1;
    await prefs.setInt(_keySentCount, next);
  }
}
