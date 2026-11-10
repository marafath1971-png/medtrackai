import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:medai/app/app_routes.dart';
import 'package:medai/app/router.dart';
import 'package:medai/providers/app_state.dart';
import 'package:medai/domain/repositories/medication_repository.dart';
import 'package:medai/domain/repositories/user_repository.dart';
import 'package:medai/domain/repositories/symptom_repository.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medai/services/link_service.dart';

class MockMedicationRepository extends Mock implements IMedicationRepository {}

class MockUserRepository extends Mock implements IUserRepository {}

class MockSymptomRepository extends Mock implements SymptomRepository {}

class MockAudioPlayer extends Mock implements AudioPlayer {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockLinkService extends Mock implements LinkService {}

class FakeMedicine extends Fake implements Medicine {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeMedicine());
  });

  late AppState appState;
  late MockMedicationRepository mockMedRepo;
  late MockUserRepository mockUserRepo;
  late MockSymptomRepository mockSymptomRepo;
  late MockAudioPlayer mockAudioPlayer;
  late MockSharedPreferences mockPrefs;
  late MockLinkService mockLinkService;

  setUp(() {
    mockMedRepo = MockMedicationRepository();
    mockUserRepo = MockUserRepository();
    mockSymptomRepo = MockSymptomRepository();
    mockAudioPlayer = MockAudioPlayer();
    mockPrefs = MockSharedPreferences();
    mockLinkService = MockLinkService();

    when(() => mockUserRepo.getCaregiversStream())
        .thenAnswer((_) => Stream.value([]));
    when(() => mockUserRepo.getMonitoringPatientsStream())
        .thenAnswer((_) => Stream.value([]));
    when(() => mockUserRepo.getProfileStream())
        .thenAnswer((_) => Stream.value(null));
    when(() => mockUserRepo.getCaregivers())
        .thenAnswer((_) => Future.value([]));
    when(() => mockUserRepo.getProfile()).thenAnswer((_) => Future.value(null));
    when(() => mockUserRepo.getStreakData())
        .thenAnswer((_) => Future.value(const StreakData()));
    when(() => mockUserRepo.getDarkMode())
        .thenAnswer((_) => Future.value(false));
    when(() => mockUserRepo.getLanguage())
        .thenAnswer((_) => Future.value('en'));

    when(() => mockMedRepo.getMedicines()).thenAnswer((_) => Future.value([]));
    when(() => mockMedRepo.getHistory()).thenAnswer((_) => Future.value({}));
    when(() => mockMedRepo.getTakenToday()).thenAnswer((_) => Future.value({}));
    when(() => mockMedRepo.getPrefs())
        .thenAnswer((_) => Future.value(mockPrefs));
    when(() => mockMedRepo.updateMedicine(any(),
        profileId: any(named: 'profileId'))).thenAnswer((_) => Future.value());

    when(() => mockSymptomRepo.getSymptoms())
        .thenAnswer((_) => Future.value([]));

    when(() => mockPrefs.getBool(any())).thenReturn(false);
    when(() => mockPrefs.getInt(any())).thenReturn(0);
    when(() => mockPrefs.getString(any())).thenReturn(null);
    when(() => mockPrefs.getStringList(any())).thenReturn(null);

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

  group('Scanner Routing & Integration', () {
    test('AppRoutes defines scanSupplement route', () {
      expect(AppRoutes.scanSupplement, equals('/scan/supplement'));
      expect(AppRoutes.scanPill, equals('/scan/pill'));
    });

    test('createRouter registers scanSupplement and scanPill in router table',
        () {
      final router = createRouter(appState);
      final paths = <String>[];

      for (final route in router.configuration.routes) {
        if (route is GoRoute) {
          paths.add(route.path);
        }
      }

      expect(paths.contains(AppRoutes.scanPill), isTrue);
      expect(paths.contains(AppRoutes.scanSupplement), isTrue);
    });
  });
}
