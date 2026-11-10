import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:medai/providers/app_state.dart';
import 'package:medai/domain/repositories/medication_repository.dart';
import 'package:medai/domain/repositories/user_repository.dart';
import 'package:medai/domain/repositories/symptom_repository.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medai/services/link_service.dart';
import 'package:medai/services/native_widget_service.dart';
import 'package:medai/services/os_health_service.dart';
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
    NativeWidgetService.enableForTesting = true;
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

  group('Phase 4: Telemetry & Native Integration Hardening', () {
    test('syncNativeWidget syncs "All Doses Taken!" when no medicines exist',
        () {
      appState.syncNativeWidget();

      expect(channelCalls.isNotEmpty, isTrue);
      final lastCall = channelCalls.last;
      expect(lastCall.method, equals('syncData'));
      expect(lastCall.arguments['nextMedName'], equals('All Doses Taken!'));
      expect(lastCall.arguments['nextMedTime'], equals('Complete ✨'));
      expect(lastCall.arguments['mascotMood'], equals('Ecstatic'));
    });

    test(
        'syncNativeWidget computes upcoming dose dynamically when medicines are scheduled',
        () {
      final now = DateTime.now();
      final currentWeekday = now.weekday % 7;

      final testMed = Medicine(
        id: 42,
        name: 'Metformin',
        dose: '500mg',
        courseStartDate: '2026-01-01',
        schedule: [
          ScheduleEntry(
            id: 'm1',
            h: 23,
            m: 59,
            label: 'Night',
            days: [currentWeekday],
          ),
        ],
      );

      appState.med.setStateForTest(meds: [testMed]);
      appState.syncNativeWidget();

      expect(channelCalls.isNotEmpty, isTrue);
      final lastCall = channelCalls.last;
      expect(lastCall.arguments['nextMedName'], equals('Metformin'));
      expect(lastCall.arguments['nextMedTime'], equals('23:59'));
    });

    test('NativeWidgetService handles invocation safely', () async {
      await expectLater(
        NativeWidgetService.syncWidgetData(
          streak: 5,
          nextMedName: 'Lisinopril',
          nextMedTime: '08:00',
          mascotMood: 'Proud',
        ),
        completes,
      );

      final call = channelCalls.last;
      expect(call.arguments['streak'], equals(5));
      expect(call.arguments['nextMedName'], equals('Lisinopril'));
      expect(call.arguments['nextMedTime'], equals('08:00'));
      expect(call.arguments['mascotMood'], equals('Proud'));
    });

    test('OSHealthService hasPermissions gracefully returns without exceptions',
        () async {
      final hasPerm = await OSHealthService.hasPermissions();
      expect(hasPerm, isFalse);

      final logged = await OSHealthService.logDose(
        medName: 'Vitamin C',
        dosageAmount: 1,
        takenAt: DateTime.now(),
      );
      expect(logged, isFalse);
    });
  });
}
