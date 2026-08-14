import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:medai/core/utils/haptic_engine.dart';
import 'package:medai/domain/entities/entities.dart';
import 'package:medai/domain/repositories/user_repository.dart';
import 'package:medai/providers/controllers/auth_controller.dart';

class MockUserRepository extends Mock implements IUserRepository {}

class FakeUserProfile extends Fake implements UserProfile {}

/// The "Haptics" settings toggle only works if the stored preference reaches
/// [HapticEngine.isEnabled] — every in-app haptic routes through that flag.
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(FakeUserProfile());
  });

  late MockUserRepository userRepo;
  late AuthController auth;

  setUp(() {
    userRepo = MockUserRepository();
    auth = AuthController(userRepo: userRepo);
    when(() => userRepo.saveProfile(any())).thenAnswer((_) async {});
    when(() => userRepo.saveLanguage(any())).thenAnswer((_) async {});
    HapticEngine.isEnabled = true;
  });

  group('UserProfile.hapticsEnabled', () {
    test('defaults to on', () {
      expect(UserProfile(name: 'A').hapticsEnabled, isTrue);
    });

    test('survives a JSON round trip', () {
      final off = UserProfile(name: 'A').copyWith(hapticsEnabled: false);
      expect(UserProfile.fromJson(off.toJson()).hapticsEnabled, isFalse);
    });

    test('defaults to on when the key is absent (existing installs)', () {
      final json = UserProfile(name: 'A').toJson()
        ..remove('hapticsEnabled');
      expect(UserProfile.fromJson(json).hapticsEnabled, isTrue);
    });

    test('is independent of notifSound', () {
      final p = UserProfile(name: 'A').copyWith(hapticsEnabled: false);
      expect(p.notifSound, isTrue);
      expect(p.hapticsEnabled, isFalse);
    });
  });

  group('AuthController syncs the HapticEngine kill switch', () {
    test('saveProfile applies the stored preference', () async {
      await auth.saveProfile(
          UserProfile(name: 'A').copyWith(hapticsEnabled: false));
      expect(HapticEngine.isEnabled, isFalse);

      await auth.saveProfile(
          UserProfile(name: 'A').copyWith(hapticsEnabled: true));
      expect(HapticEngine.isEnabled, isTrue);
    });

    test('loadProfile applies the preference on cold start', () async {
      when(() => userRepo.getProfile()).thenAnswer((_) async =>
          UserProfile(name: 'A').copyWith(hapticsEnabled: false));
      when(() => userRepo.getLanguage()).thenAnswer((_) async => 'en');

      await auth.loadProfile();
      expect(HapticEngine.isEnabled, isFalse);
    });

    test('a null profile restores the default-on behaviour', () async {
      await auth.saveProfile(
          UserProfile(name: 'A').copyWith(hapticsEnabled: false));
      expect(HapticEngine.isEnabled, isFalse);

      auth.profile = null;
      expect(HapticEngine.isEnabled, isTrue);
    });
  });

  group('HapticEngine.isEnabled gates playback', () {
    test('disabled suppresses haptic calls', () async {
      HapticEngine.isEnabled = false;
      // Must not throw and must not reach the platform channel (no binary
      // messenger handler is registered for it in tests).
      await HapticEngine.doseTaken();
      expect(HapticEngine.isEnabled, isFalse);
    });
  });
}
