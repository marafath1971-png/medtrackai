import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/domain/repositories/medication_repository.dart';
import 'package:medai/domain/repositories/symptom_repository.dart';
import 'package:medai/domain/repositories/user_repository.dart';
import 'package:medai/providers/app_state.dart';
import 'package:medai/services/link_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockMedicationRepository extends Mock implements IMedicationRepository {}

class MockUserRepository extends Mock implements IUserRepository {}

class MockSymptomRepository extends Mock implements SymptomRepository {}

class MockAudioPlayer extends Mock implements AudioPlayer {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockLinkService extends Mock implements LinkService {}

/// Biometric lock never engaged on a cold start.
///
/// There were two lock flags. AuthController._isLocked was seeded from
/// profile.biometricEnabled on login and on profile load — correctly. But the
/// shell rendered from a *second*, plain `AppState.isLocked = false` that
/// nothing bridged to it, so a cold start always came up unlocked no matter
/// what the user had chosen. The setting was written and then never read.
///
/// The shipped test for this area asserted only that certain strings appear in
/// the source file, so it passed throughout. These assert behaviour instead.
void main() {
  // AppState's constructor registers a lifecycle observer, which touches
  // WidgetsBinding.instance.
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppState appState;
  late MockUserRepository mockUserRepo;

  setUp(() {
    final mockMedRepo = MockMedicationRepository();
    mockUserRepo = MockUserRepository();
    final mockSymptomRepo = MockSymptomRepository();
    final mockAudioPlayer = MockAudioPlayer();
    final mockPrefs = MockSharedPreferences();
    final mockLinkService = MockLinkService();

    when(() => mockPrefs.getString(any())).thenReturn(null);
    when(() => mockLinkService.init()).thenAnswer((_) async {});
    mockLinkService.onJoinCodeDetected = (code) {};

    appState = AppState(
      medRepo: mockMedRepo,
      userRepo: mockUserRepo,
      symptomRepo: mockSymptomRepo,
      audioPlayer: mockAudioPlayer,
      prefs: mockPrefs,
      linkService: mockLinkService,
    );
  });

  UserProfile profileWith({required bool biometric}) => UserProfile(
        name: 'Alex',
        biometricEnabled: biometric,
      );

  group('the lock state has a single source of truth', () {
    test('AppState.isLocked reflects the AuthController flag, not a copy', () {
      appState.auth.profile = profileWith(biometric: true);
      appState.auth.isLocked = true;

      expect(appState.isLocked, isTrue,
          reason: 'the shell reads AppState.isLocked; it must not be a '
              'separate field that nothing writes');

      appState.auth.isLocked = false;
      expect(appState.isLocked, isFalse);
    });

    test('writing through AppState reaches the same flag', () {
      appState.auth.profile = profileWith(biometric: true);

      appState.isLocked = true;
      expect(appState.auth.isLocked, isTrue);
    });
  });

  group('lockApp honours the user setting', () {
    test('backgrounding locks when biometric lock is on', () {
      appState.auth.profile = profileWith(biometric: true);
      appState.auth.isLocked = false;

      appState.lockApp();

      expect(appState.isLocked, isTrue);
    });

    test('backgrounding does NOT lock when the user never enabled it', () {
      // This locked every user out on every backgrounding, enabled or not.
      appState.auth.profile = profileWith(biometric: false);
      appState.auth.isLocked = false;

      appState.lockApp();

      expect(appState.isLocked, isFalse,
          reason: 'a user who never turned on biometric lock must not be '
              'locked out when the app backgrounds');
    });

    test('unlocking always works, whatever the setting', () {
      appState.auth.profile = profileWith(biometric: true);
      appState.auth.isLocked = true;

      appState.unlockApp();

      expect(appState.isLocked, isFalse);
    });
  });
}
