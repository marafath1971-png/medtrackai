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

    // Default mock behavior
    when(() => mockUserRepo.getCaregiversStream())
        .thenAnswer((_) => Stream.value([]));
    when(() => mockUserRepo.getMonitoringPatientsStream())
        .thenAnswer((_) => Stream.value([]));
    when(() => mockUserRepo.getProfileStream())
        .thenAnswer((_) => Stream.value(null));
    when(() => mockUserRepo.getCaregivers())
        .thenAnswer((_) => Future.value([]));
    when(() => mockUserRepo.getDarkMode())
        .thenAnswer((_) => Future.value(false));

    when(() => mockMedRepo.getMedicines()).thenAnswer((_) => Future.value([]));
    when(() => mockMedRepo.getHistory()).thenAnswer((_) => Future.value({}));
    when(() => mockMedRepo.getTakenToday()).thenAnswer((_) => Future.value({}));
    when(() => mockMedRepo.getPrefs())
        .thenAnswer((_) => Future.value(mockPrefs));

    when(() => mockSymptomRepo.getSymptoms())
        .thenAnswer((_) => Future.value([]));

    when(() => mockPrefs.getBool(any())).thenReturn(false);
    when(() => mockPrefs.getInt(any())).thenReturn(0);
    when(() => mockPrefs.getString(any())).thenReturn(null);

    mockLinkService = MockLinkService();

    when(() => mockLinkService.init()).thenAnswer((_) async {});
    // Field assignment instead of 'when' for non-method fields
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

  group('AppState Analytics Logic', () {
    test('getStreak returns 0 with no history', () {
      expect(appState.med.getStreak(), 0);
    });

    test('getAdherenceScore returns 0.0 with no meds and no history', () {
      // Brand-new users score 0, not a misleading 100% "Excellent".
      expect(appState.med.getAdherenceScore(), 0.0);
    });

    test('getTrendData returns 30 entries', () {
      final trend = appState.med.getTrendData();
      expect(trend.length, 30);
    });

    test('Analytics calculations with mocked data', () async {
      final med = Medicine(
        id: 1,
        name: 'Test Med',
        count: 10,
        totalCount: 30,
        courseStartDate: '2024-01-01',
        schedule: [
          ScheduleEntry(
              id: '1',
              h: 8,
              m: 0,
              label: 'Morning',
              days: [0, 1, 2, 3, 4, 5, 6])
        ],
      );

      // Mock repo returns
      when(() => mockMedRepo.getMedicines())
          .thenAnswer((_) => Future.value([med]));

      await appState.med.loadData();
      // Med scheduled daily but nothing logged yet → 0 taken / N scheduled.
      expect(appState.getAdherenceScore(), 0.0);

      // Mock history for 30 days
      final now = DateTime.now();
      final Map<String, List<DoseEntry>> fullHistory = {};
      for (int i = 1; i <= 3; i++) {
        final d = now.subtract(Duration(days: i));
        final k =
            "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
        fullHistory[k] = [
          DoseEntry(medId: 1, label: 'Morning', time: '08:00', taken: true)
        ];
      }

      when(() => mockMedRepo.getHistory())
          .thenAnswer((_) => Future.value(fullHistory));
      await appState.med.loadData();

      expect(appState.med.getStreak(), 3);
    });
  });

  group('AppState connectivity', () {
    AppState buildWith(Future<bool> Function() probe) => AppState(
          medRepo: mockMedRepo,
          userRepo: mockUserRepo,
          symptomRepo: mockSymptomRepo,
          audioPlayer: mockAudioPlayer,
          prefs: mockPrefs,
          linkService: mockLinkService,
          probeOnline: probe,
        );

    test('checkConnectivity flips isOffline when probe fails', () async {
      final state = buildWith(() async => false);
      expect(state.isOffline, false);

      final online = await state.checkConnectivity();

      expect(online, false);
      expect(state.isOffline, true);
    });

    test('going back online clears a lingering networkErrorMessage', () async {
      var reachable = false;
      final state = buildWith(() async => reachable);

      // Simulate a request-level failure while isOffline stayed false.
      state.setNetworkError('Timed out');
      expect(state.networkErrorMessage, 'Timed out');
      expect(state.isOffline, false);

      var notified = 0;
      state.addListener(() => notified++);

      reachable = true;
      final online = await state.checkConnectivity();

      expect(online, true);
      expect(state.networkErrorMessage, isNull);
      expect(notified, greaterThan(0),
          reason: 'clearing the error should notify listeners');
    });

    test('checkConnectivity does not notify when nothing changed', () async {
      final state = buildWith(() async => true);
      var notified = 0;
      state.addListener(() => notified++);

      await state.checkConnectivity();

      expect(notified, 0);
    });
  });
}
