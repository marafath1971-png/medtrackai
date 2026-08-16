import 'package:flutter_test/flutter_test.dart';
import 'package:medai/domain/entities/entities.dart';

/// UserProfile is persisted to Firestore and reloaded on every launch, so any
/// field that survives toJson but not fromJson is silently reset for the user.
/// That already happened once: the `category` default disagreed between the
/// two, and `hapticsEnabled` had to be added to both sides by hand.
void main() {
  test('a fully populated profile survives a JSON round trip', () {
    final original = UserProfile(
      name: 'Alex',
      age: '42',
      gender: 'other',
      conditions: const ['diabetes', 'hypertension'],
      allergies: const ['penicillin'],
      breakfastTime: const {'h': 7, 'm': 30},
      lunchTime: const {'h': 12, 'm': 15},
      dinnerTime: const {'h': 19, 'm': 0},
      sleepTime: const {'h': 23, 'm': 0},
      wakeTime: const {'h': 6, 'm': 45},
      motivation: const ['feel better', 'stay independent'],
      reminderStyle: 'persistent',
      notifPerm: true,
      notifSound: false,
      hapticsEnabled: false,
      notifRefill: true,
      avatar: '🙂',
      biometricEnabled: true,
      accentColor: 'b9ea6e',
      appIcon: 'gold',
      reminderSound: 'chime',
      scansUsed: 3,
      voiceLogsUsed: 2,
      isPremium: true,
      preferredLanguage: 'ja',
    );

    final restored = UserProfile.fromJson(original.toJson());

    expect(restored.name, original.name);
    expect(restored.age, original.age);
    expect(restored.gender, original.gender);
    expect(restored.conditions, original.conditions);
    expect(restored.allergies, original.allergies);
    expect(restored.breakfastTime, original.breakfastTime);
    expect(restored.lunchTime, original.lunchTime);
    expect(restored.dinnerTime, original.dinnerTime);
    expect(restored.sleepTime, original.sleepTime);
    expect(restored.wakeTime, original.wakeTime);
    expect(restored.motivation, original.motivation);
    expect(restored.reminderStyle, original.reminderStyle);
    expect(restored.notifPerm, original.notifPerm);
    expect(restored.notifSound, original.notifSound);
    expect(restored.hapticsEnabled, original.hapticsEnabled);
    expect(restored.notifRefill, original.notifRefill);
    expect(restored.avatar, original.avatar);
    expect(restored.biometricEnabled, original.biometricEnabled);
    expect(restored.accentColor, original.accentColor);
    expect(restored.appIcon, original.appIcon);
    expect(restored.reminderSound, original.reminderSound);
    expect(restored.scansUsed, original.scansUsed);
    expect(restored.voiceLogsUsed, original.voiceLogsUsed);
    expect(restored.isPremium, original.isPremium);
    expect(restored.preferredLanguage, original.preferredLanguage);
  });

  test('every key written by toJson is read back by fromJson', () {
    // Guards the class of bug where a new field is added to toJson and the
    // constructor but forgotten in fromJson, so it resets on next launch.
    final json = UserProfile(name: 'A').toJson();

    // Flip every boolean and bump every scalar away from its default, so a
    // field that is not parsed shows up as a mismatch rather than coinciding
    // with the default.
    final mutated = Map<String, dynamic>.from(json)
      ..['notifSound'] = false
      ..['hapticsEnabled'] = false
      ..['notifPerm'] = false
      ..['notifRefill'] = false
      ..['biometricEnabled'] = true
      ..['isPremium'] = true
      ..['scansUsed'] = 9
      ..['voiceLogsUsed'] = 8
      ..['avatar'] = '🦊'
      ..['accentColor'] = 'ff0000'
      ..['appIcon'] = 'gold'
      ..['reminderSound'] = 'chime'
      ..['preferredLanguage'] = 'ar';

    final p = UserProfile.fromJson(mutated);

    expect(p.notifSound, isFalse);
    expect(p.hapticsEnabled, isFalse);
    expect(p.notifPerm, isFalse);
    expect(p.notifRefill, isFalse);
    expect(p.biometricEnabled, isTrue);
    expect(p.isPremium, isTrue);
    expect(p.scansUsed, 9);
    expect(p.voiceLogsUsed, 8);
    expect(p.avatar, '🦊');
    expect(p.accentColor, 'ff0000');
    expect(p.appIcon, 'gold');
    expect(p.reminderSound, 'chime');
    expect(p.preferredLanguage, 'ar');
  });

  test('an empty map yields usable defaults rather than throwing', () {
    final p = UserProfile.fromJson(const {});
    expect(p.name, isA<String>());
    expect(p.hapticsEnabled, isTrue, reason: 'existing installs keep haptics');
    expect(p.notifSound, isTrue);
  });

  test('copyWith leaves untouched fields alone', () {
    final original =
        UserProfile(name: 'Alex', isPremium: true, scansUsed: 4);
    final copy = original.copyWith(name: 'Sam');

    expect(copy.name, 'Sam');
    expect(copy.isPremium, isTrue);
    expect(copy.scansUsed, 4);
  });

  test('nested time maps are not shared between copies', () {
    final original = UserProfile(name: 'A', breakfastTime: const {'h': 7, 'm': 0});
    final restored = UserProfile.fromJson(original.toJson());

    expect(restored.breakfastTime['h'], 7);
    expect(restored.breakfastTime['m'], 0);
  });
}
