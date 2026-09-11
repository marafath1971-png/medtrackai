import 'package:flutter_test/flutter_test.dart';
import 'package:medai/domain/entities/managed_profile.dart';
import 'package:medai/services/pin_service.dart';

/// The plaintext leak was not in PinService but in what reached Firestore:
/// ManagedProfile is serialised into the user profile document. These assert on
/// the serialised form, which is the thing that actually syncs.
void main() {
  test('a profile created with a hashed PIN never serialises the plaintext',
      () {
    const raw = '4821';
    final p = ManagedProfile(
      id: 'a',
      name: 'Dependent',
      relation: 'Child',
      pin: PinService.hashPin(raw),
    );

    final json = p.toJson().toString();
    expect(json.contains(raw), isFalse,
        reason: 'the raw PIN must not reach the synced document');
    expect(PinService.verifyPin(raw, p.pin), isTrue);
  });

  test('survives a toJson/fromJson round trip and still verifies', () {
    const raw = '0000';
    final p = ManagedProfile(
      id: 'b',
      name: 'D',
      relation: 'Child',
      pin: PinService.hashPin(raw),
    );
    final back = ManagedProfile.fromJson(p.toJson());
    expect(PinService.verifyPin(raw, back.pin), isTrue);
    expect(PinService.verifyPin('0001', back.pin), isFalse);
    expect(PinService.needsRehash(back.pin), isFalse);
  });

  test('removing a PIN clears it from the serialised form', () {
    final p = ManagedProfile(
      id: 'c',
      name: 'D',
      relation: 'Child',
      pin: PinService.hashPin('1234'),
    );
    expect(p.copyWith(clearPin: true).toJson()['pin'], isNull);
  });
}
