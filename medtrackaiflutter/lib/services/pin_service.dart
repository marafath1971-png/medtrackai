import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Hashing and verification for dependent-profile PINs.
///
/// PINs gate access to a dependent's medication data, but were stored — and
/// synced to Firestore — as plaintext. Anyone with read access to the profile
/// document could read the PIN directly.
///
/// A 4-digit PIN has only 10,000 possible values, so a hash alone buys very
/// little: the entire space can be enumerated instantly. What actually helps is
/// a per-PIN random salt (so one precomputed table cannot cover every user) and
/// a deliberately slow KDF (so enumerating that space costs real time). PBKDF2
/// with a high iteration count gives both.
///
/// This raises the cost of an attacker who has *already* obtained the stored
/// record. It cannot make a 4-digit secret strong, and it is not a substitute
/// for the Firestore rules that keep the record private in the first place.
class PinService {
  /// Marks a stored value as a hash produced by this service. Anything without
  /// it is a legacy plaintext PIN.
  static const String _prefix = r'pbkdf2$';

  /// Cost factor, chosen by measurement rather than by round number.
  ///
  /// On a desktop VM this costs ~150 ms per verification, so exhausting the
  /// whole 4-digit space against one stored record takes ~25 minutes — versus
  /// microseconds against the plaintext this replaces. A phone is slower
  /// still, which helps the attacker case and hurts the unlock case, so this
  /// is deliberately not pushed higher: at 100k, unlock measured ~300 ms on
  /// desktop and would be plainly laggy on a mid-range device.
  ///
  /// The value is recorded in each hash, so raising it later does not
  /// invalidate existing PINs — [needsRehash] upgrades them on next unlock.
  static const int _iterations = 50000;

  static const int _saltLength = 16;
  static const int _keyLength = 32;

  static final Random _random = Random.secure();

  /// True when [stored] was produced by [hashPin] rather than being a legacy
  /// plaintext PIN.
  static bool isHashed(String? stored) =>
      stored != null && stored.startsWith(_prefix);

  /// Hashes [pin] with a fresh random salt.
  ///
  /// Format: `pbkdf2$<iterations>$<base64 salt>$<base64 hash>`. The parameters
  /// travel with the value so the cost factor can be raised later without
  /// invalidating existing PINs.
  static String hashPin(String pin) {
    final salt = Uint8List.fromList(
      List<int>.generate(_saltLength, (_) => _random.nextInt(256)),
    );
    final hash = _derive(pin, salt, _iterations);
    return '$_prefix$_iterations\$${base64.encode(salt)}\$${base64.encode(hash)}';
  }

  /// Verifies [pin] against [stored].
  ///
  /// Accepts a legacy plaintext value so that switching to hashing does not
  /// lock anyone out of a dependent profile; callers should re-save via
  /// [hashPin] once verified. See [needsRehash].
  static bool verifyPin(String pin, String? stored) {
    if (stored == null || stored.isEmpty) return false;

    if (!isHashed(stored)) {
      // Legacy plaintext. Compared in constant time anyway — there is no reason
      // to leak length or prefix information just because the value is old.
      return _constantTimeEquals(
        utf8.encode(pin),
        utf8.encode(stored),
      );
    }

    final parts = stored.substring(_prefix.length).split(r'$');
    if (parts.length != 3) return false;

    final iterations = int.tryParse(parts[0]);
    if (iterations == null || iterations <= 0) return false;

    try {
      final salt = base64.decode(parts[1]);
      final expected = base64.decode(parts[2]);
      final actual = _derive(pin, Uint8List.fromList(salt), iterations);
      return _constantTimeEquals(actual, expected);
    } catch (_) {
      // Malformed record — treat as a failed verification rather than throwing
      // into the unlock path.
      return false;
    }
  }

  /// True when [stored] should be replaced by a fresh [hashPin] result: either
  /// it is still plaintext, or it was hashed with a weaker cost factor than the
  /// current one.
  static bool needsRehash(String? stored) {
    if (stored == null || stored.isEmpty) return false;
    if (!isHashed(stored)) return true;

    final parts = stored.substring(_prefix.length).split(r'$');
    if (parts.length != 3) return true;
    final iterations = int.tryParse(parts[0]);
    return iterations == null || iterations < _iterations;
  }

  static Uint8List _derive(String pin, Uint8List salt, int iterations) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, iterations, _keyLength));
    return derivator.process(Uint8List.fromList(utf8.encode(pin)));
  }

  /// Length-independent comparison, so verification time does not reveal how
  /// much of the value matched.
  static bool _constantTimeEquals(List<int> a, List<int> b) {
    var diff = a.length ^ b.length;
    for (var i = 0; i < a.length && i < b.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
