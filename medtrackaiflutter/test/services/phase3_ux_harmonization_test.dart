import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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

class FakeUserProfile extends Fake implements UserProfile {}

class FakeMedicine extends Fake implements Medicine {}

class FakeStreakData extends Fake implements StreakData {}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(FakeUserProfile());
    registerFallbackValue(FakeMedicine());
    registerFallbackValue(FakeStreakData());
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
    when(() => mockPrefs.setStringList(any(), any()))
        .thenAnswer((_) => Future.value(true));
    when(() => mockPrefs.setBool(any(), any()))
        .thenAnswer((_) => Future.value(true));

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

  group('Phase 3 UX Harmonization & Refill Integration', () {
    test('refillMedication adds units to active medicine', () async {
      final med = Medicine(
        id: 101,
        name: 'Metformin',
        dose: '500mg',
        count: 5,
        totalCount: 60,
        refillAt: 10,
        courseStartDate: '2026-01-01',
      );

      // Seed medicine into AppState
      appState.med.meds.add(med);
      expect(appState.meds.first.count, 5);

      await appState.refillMedication(101, amount: 30);

      expect(appState.meds.first.count, 35);
      verify(() => mockMedRepo.updateMedicine(
            any(that: predicate<Medicine>((m) => m.id == 101 && m.count == 35)),
            profileId: any(named: 'profileId'),
          )).called(1);
    });

    test('getRefillForecast filters medicines needing refills', () {
      final lowStockMed = Medicine(
        id: 1,
        name: 'Lisinopril',
        dose: '10mg',
        count: 5,
        totalCount: 30,
        refillAt: 10,
        courseStartDate: '2026-01-01',
      );
      final healthyStockMed = Medicine(
        id: 2,
        name: 'Vitamin D',
        dose: '1000IU',
        count: 25,
        totalCount: 30,
        refillAt: 10,
        courseStartDate: '2026-01-01',
      );

      appState.med.meds.addAll([lowStockMed, healthyStockMed]);

      final forecast = appState.getRefillForecast();

      expect(forecast.length, 1);
      expect(forecast.first.id, 1);
      expect(forecast.first.name, 'Lisinopril');
    });

    test('exportDataPDF returns false when user is not premium', () async {
      final ok = await appState.exportDataPDF();
      expect(ok, isFalse);
    });
  });
}
