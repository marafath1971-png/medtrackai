import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:medai/providers/app_state.dart';
import 'package:medai/screens/medicine/add_medication_screen.dart';
import 'package:medai/domain/repositories/medication_repository.dart';
import 'package:medai/domain/repositories/user_repository.dart';
import 'package:medai/domain/repositories/symptom_repository.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medai/services/link_service.dart';
import 'package:medai/l10n/app_localizations.dart';

class MockMedicationRepository extends Mock implements IMedicationRepository {}

class MockUserRepository extends Mock implements IUserRepository {}

class MockSymptomRepository extends Mock implements SymptomRepository {}

class MockAudioPlayer extends Mock implements AudioPlayer {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockLinkService extends Mock implements LinkService {}

class FakeMedicine extends Fake implements Medicine {}

class FakeUserProfile extends Fake implements UserProfile {}

class FakeStreakData extends Fake implements StreakData {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeMedicine());
    registerFallbackValue(FakeUserProfile());
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
    when(() =>
            mockMedRepo.addMedicine(any(), profileId: any(named: 'profileId')))
        .thenAnswer((_) => Future.value());

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

  Widget buildSubject() {
    return ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AddMedicationScreen(),
      ),
    );
  }

  testWidgets(
      'AddMedicationScreen saves new medicine into AppState on submission',
      (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    final nameField = find.byType(TextField);
    expect(nameField, findsOneWidget);

    await tester.enterText(nameField, 'Atorvastatin');
    await tester.pumpAndSettle();

    final submitBtn = find.text('Add medication');
    expect(submitBtn, findsOneWidget);

    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    verify(() => mockMedRepo.addMedicine(
          any(
              that: isA<Medicine>()
                  .having((m) => m.name, 'name', 'Atorvastatin')),
          profileId: any(named: 'profileId'),
        )).called(1);

    await tester.pump(const Duration(milliseconds: 400));
  });
}
