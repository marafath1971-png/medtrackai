import 'package:flutter_test/flutter_test.dart';
import 'package:medai/domain/entities/managed_profile.dart';
import 'package:medai/services/pin_service.dart';

/// Dependent-profile PINs gate access to a dependent's medication data, and
/// were stored — and synced to Firestore — as plaintext, readable by anyone
/// with access to the profile document.
///
/// A 4-digit PIN can never be strong (10,000 values), so these tests pin the
/// two properties that actually raise an attacker's cost: a per-PIN random
/// salt, and verification that still works for profiles written before the
/// change so nobody is locked out.
void main() {
  group('hashPin', () {
    test('does not contain the PIN', () {
      final hash = PinService.hashPin('1234');

      expect(hash.contains('1234'), isFalse);
      expect(PinService.isHashed(hash), isTrue);
    });

    test('is salted — the same PIN hashes differently every time', () {
      final a = PinService.hashPin('1234');
      final b = PinService.hashPin('1234');

      expect(a, isNot(b),
          reason: 'a shared salt would let one table cover every user');
      expect(PinService.verifyPin('1234', a), isTrue);
      expect(PinService.verifyPin('1234', b), isTrue);
    });

    test('records its parameters so the cost factor can be raised later', () {
      final hash = PinService.hashPin('1234');
      final parts = hash.split(r'$');

      expect(parts.first, 'pbkdf2');
      expect(int.tryParse(parts[1]), isNotNull);
      expect(parts.length, 4);
    });
  });

  group('verifyPin', () {
    test('accepts the correct PIN and rejects wrong ones', () {
      final hash = PinService.hashPin('4821');

      expect(PinService.verifyPin('4821', hash), isTrue);
      expect(PinService.verifyPin('4822', hash), isFalse);
      expect(PinService.verifyPin('', hash), isFalse);
      expect(PinService.verifyPin('48210', hash), isFalse);
    });

    test('wrong PINs in the 4-digit space are rejected', () {
      final hash = PinService.hashPin('0000');
      // Spot-check rather than all 10,000 — PBKDF2 is deliberately slow.
      for (final candidate in ['0001', '1000', '9999', '0100']) {
        expect(PinService.verifyPin(candidate, hash), isFalse,
            reason: '$candidate must not unlock a profile with PIN 0000');
      }
      expect(PinService.verifyPin('0000', hash), isTrue);
    });

    test('migration: still accepts a legacy plaintext PIN', () {
      // Written by the shipped build. Must keep working or the caregiver is
      // locked out of the dependent profile.
      expect(PinService.verifyPin('1234', '1234'), isTrue);
      expect(PinService.verifyPin('9999', '1234'), isFalse);
    });

    test('a null or empty stored value never verifies', () {
      expect(PinService.verifyPin('1234', null), isFalse);
      expect(PinService.verifyPin('1234', ''), isFalse);
      expect(PinService.verifyPin('', ''), isFalse);
    });

    test('a malformed hash fails closed instead of throwing', () {
      for (final bad in [
        r'pbkdf2$',
        r'pbkdf2$notanumber$c2FsdA==$aGFzaA==',
        r'pbkdf2$1000$!!!not-base64!!!$aGFzaA==',
        r'pbkdf2$1000$c2FsdA==',
      ]) {
        expect(PinService.verifyPin('1234', bad), isFalse,
            reason: 'malformed record: $bad');
      }
    });
  });

  group('needsRehash', () {
    test('true for a legacy plaintext PIN', () {
      expect(PinService.needsRehash('1234'), isTrue);
    });

    test('false for a current hash', () {
      expect(PinService.needsRehash(PinService.hashPin('1234')), isFalse);
    });

    test('true for a hash produced with a weaker cost factor', () {
      expect(PinService.needsRehash(r'pbkdf2$1000$c2FsdA==$aGFzaA=='), isTrue);
    });

    test('false when no PIN is set — nothing to upgrade', () {
      expect(PinService.needsRehash(null), isFalse);
      expect(PinService.needsRehash(''), isFalse);
    });

    test('a rehashed legacy PIN verifies and no longer needs upgrading', () {
      const legacy = '1234';
      expect(PinService.verifyPin('1234', legacy), isTrue);
      expect(PinService.needsRehash(legacy), isTrue);

      final upgraded = PinService.hashPin('1234');
      expect(PinService.verifyPin('1234', upgraded), isTrue);
      expect(PinService.needsRehash(upgraded), isFalse);
    });
  });

  group('ManagedProfile.copyWith PIN semantics', () {
    final profile = ManagedProfile(
      id: 'a',
      name: 'Dependent',
      relation: 'Child',
      pin: PinService.hashPin('1234'),
    );

    test('omitting pin preserves the existing one', () {
      expect(profile.copyWith(name: 'Renamed').pin, profile.pin);
    });

    test('passing a new pin replaces it', () {
      final next = PinService.hashPin('5678');
      expect(profile.copyWith(pin: next).pin, next);
    });

    test('passing null cannot clear the PIN — clearPin is required', () {
      // Null-coalescing means `pin: null` silently keeps the old value, so a
      // "remove PIN" action written that way would appear to work and not.
      expect(profile.copyWith(pin: null).pin, profile.pin);
      expect(profile.copyWith(clearPin: true).pin, isNull);
    });
  });
}
