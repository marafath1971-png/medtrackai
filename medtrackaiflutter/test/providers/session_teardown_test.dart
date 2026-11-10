import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:medai/providers/app_state.dart';
import 'package:medai/domain/repositories/medication_repository.dart';
import 'package:medai/domain/repositories/user_repository.dart';
import 'package:medai/domain/repositories/symptom_repository.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medai/services/link_service.dart';
import 'package:medai/services/purchases_service.dart';
import 'package:flutter/services.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
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

  final List<MethodCall> channelCalls = [];

  setUp(() {
    channelCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.medtrackai.widget'),
      (MethodCall methodCall) async {
        channelCalls.add(methodCall);
        return null;
      },
    );

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

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.medtrackai.widget'),
      null,
    );
  });

  group('Session Teardown & Key Canonicalization', () {
    test('DoseItem.buildKey generates canonical medId-label key format', () {
      final key = DoseItem.buildKey(42, 'Morning');
      expect(key, equals('42-Morning'));
    });

    test('MedicationController.clear resets all in-memory medicines and caches',
        () {
      final testMed = Medicine(
        id: 10,
        name: 'Aspirin',
        dose: '81mg',
        courseStartDate: '2026-01-01',
        schedule: [
          ScheduleEntry(id: 's1', h: 8, m: 0, label: 'Morning', days: [1]),
        ],
      );

      appState.med.setStateForTest(meds: [testMed]);
      expect(appState.med.meds, isNotEmpty);

      appState.med.clear();
      expect(appState.med.meds, isEmpty);
      expect(appState.med.history, isEmpty);
      expect(appState.med.takenToday, isEmpty);
    });

    test('SocialController.clear resets caregivers and monitored patient lists',
        () {
      appState.social.clear();
      expect(appState.social.caregivers, isEmpty);
      expect(appState.social.monitoredPatients, isEmpty);
      expect(appState.social.missedAlerts, isEmpty);
    });

    test('WellnessController.clear resets symptoms and insights lists', () {
      appState.wellness.clear();
      expect(appState.wellness.symptoms, isEmpty);
      expect(appState.wellness.healthInsights, isEmpty);
      expect(appState.wellness.predictions, isEmpty);
    });

    test(
        'PurchasesService.manageSubscriptions runs without unhandled exception',
        () async {
      final res = await PurchasesService.manageSubscriptions();
      expect(res, isA<bool>());
    });
  });
}
