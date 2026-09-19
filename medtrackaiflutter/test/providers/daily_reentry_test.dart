import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:medai/domain/repositories/medication_repository.dart';
import 'package:medai/domain/repositories/symptom_repository.dart';
import 'package:medai/domain/repositories/user_repository.dart';
import 'package:medai/providers/app_state.dart';
import 'package:medai/services/link_service.dart';

class MockMedicationRepository extends Mock implements IMedicationRepository {}

class MockUserRepository extends Mock implements IUserRepository {}

class MockSymptomRepository extends Mock implements SymptomRepository {}

class MockAudioPlayer extends Mock implements AudioPlayer {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockLinkService extends Mock implements LinkService {}

/// checkDailyReentry decides the number ReentryScreen shows on the first open
/// of a new day. Anything non-zero flips that screen from "Streak maintained!"
/// to "Streak lost..." plus a paywall, so an inflated count takes a streak
/// away from someone who did nothing wrong.
///
/// History is keyed by `toIso8601String().substring(0, 10)`, so tests build
/// keys the same way.
String _key(DateTime d) => d.toIso8601String().substring(0, 10);

/// A medicine whose slots are due only on [days] (0 = Sunday, matching
/// `weekday % 7` as getDoses does).
Medicine _med({
  required int id,
  required List<String> slots,
  required List<int> days,
}) {
  return Medicine(
    id: id,
    name: 'Med$id',
    courseStartDate: DateTime.now().toIso8601String(),
    schedule: [
      for (final s in slots)
        ScheduleEntry(id: '$id-$s', h: 8, m: 0, label: s, days: days),
    ],
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  late AppState appState;
  late MockMedicationRepository mockMedRepo;
  late MockUserRepository mockUserRepo;
  late MockSymptomRepository mockSymptomRepo;
  late MockSharedPreferences mockPrefs;
  late MockLinkService mockLinkService;

  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  final yesterdayDow = yesterday.weekday % 7;
  final everyDay = [0, 1, 2, 3, 4, 5, 6];
  // A weekday yesterday is definitely not, so "nothing due" is unambiguous.
  final notYesterday = [(yesterdayDow + 3) % 7];

  setUp(() {
    mockMedRepo = MockMedicationRepository();
    mockUserRepo = MockUserRepository();
    mockSymptomRepo = MockSymptomRepository();
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
    when(() => mockUserRepo.getDarkMode()).thenAnswer((_) => Future.value(false));

    when(() => mockMedRepo.getMedicines()).thenAnswer((_) => Future.value([]));
    when(() => mockMedRepo.getHistory()).thenAnswer((_) => Future.value({}));
    when(() => mockMedRepo.getTakenToday()).thenAnswer((_) => Future.value({}));
    when(() => mockMedRepo.getPrefs()).thenAnswer((_) => Future.value(mockPrefs));

    when(() => mockSymptomRepo.getSymptoms()).thenAnswer((_) => Future.value([]));

    when(() => mockPrefs.getBool(any())).thenReturn(false);
    when(() => mockPrefs.getInt(any())).thenReturn(0);
    when(() => mockPrefs.getString(any())).thenReturn(null);

    when(() => mockLinkService.init()).thenAnswer((_) async {});
    mockLinkService.onJoinCodeDetected = (code) {};

    // checkDailyReentry reads the real SharedPreferences instance rather than
    // the injected one, so lastOpenedDate is seeded here.
    SharedPreferences.setMockInitialValues({
      'lastOpenedDate': _key(yesterday),
    });

    appState = AppState(
      medRepo: mockMedRepo,
      userRepo: mockUserRepo,
      symptomRepo: mockSymptomRepo,
      audioPlayer: MockAudioPlayer(),
      prefs: mockPrefs,
      linkService: mockLinkService,
    );
  });

  test('a day with nothing scheduled costs nothing', () async {
    appState.med.setStateForTest(
      meds: [_med(id: 1, slots: ['Morning'], days: notYesterday)],
      history: {},
    );

    expect(await appState.checkDailyReentry(), 0,
        reason: 'no doses were due yesterday, so none could be missed');
  });

  test('an unlogged day counts the slots due, not the medicines', () async {
    // Two medicines, three slots between them, all due yesterday.
    appState.med.setStateForTest(
      meds: [
        _med(id: 1, slots: ['Morning', 'Evening'], days: everyDay),
        _med(id: 2, slots: ['Morning'], days: everyDay),
      ],
      history: {},
    );

    expect(await appState.checkDailyReentry(), 3,
        reason: 'counting medicines instead of slots under-reported 3 as 2');
  });

  test('a medicine due only on other days is excluded from the count',
      () async {
    appState.med.setStateForTest(
      meds: [
        _med(id: 1, slots: ['Morning'], days: everyDay),
        _med(id: 2, slots: ['Morning'], days: notYesterday),
      ],
      history: {},
    );

    expect(await appState.checkDailyReentry(), 1,
        reason: 'only the medicine actually due yesterday can be missed');
  });

  test('a logged day counts the doses left untaken', () async {
    appState.med.setStateForTest(
      meds: [_med(id: 1, slots: ['Morning', 'Evening'], days: everyDay)],
      history: {
        _key(yesterday): [
          DoseEntry(medId: 1, label: 'Morning', time: '8:00 AM', taken: true),
          DoseEntry(medId: 1, label: 'Evening', time: '8:00 PM', taken: false),
        ],
      },
    );

    expect(await appState.checkDailyReentry(), 1);
  });

  test('a fully logged day costs nothing', () async {
    appState.med.setStateForTest(
      meds: [_med(id: 1, slots: ['Morning'], days: everyDay)],
      history: {
        _key(yesterday): [
          DoseEntry(medId: 1, label: 'Morning', time: '8:00 AM', taken: true),
        ],
      },
    );

    expect(await appState.checkDailyReentry(), 0);
  });

  test('opening twice in one day only prompts once', () async {
    appState.med.setStateForTest(
      meds: [_med(id: 1, slots: ['Morning'], days: everyDay)],
      history: {},
    );

    expect(await appState.checkDailyReentry(), 1);
    expect(await appState.checkDailyReentry(), null,
        reason: 'the second open of the same day must not re-prompt');
  });

  test('the very first open ever costs nothing', () async {
    SharedPreferences.setMockInitialValues({});
    appState.med.setStateForTest(
      meds: [_med(id: 1, slots: ['Morning'], days: everyDay)],
      history: {},
    );

    expect(await appState.checkDailyReentry(), 0,
        reason: 'a brand-new user has no yesterday to have missed');
  });
}
