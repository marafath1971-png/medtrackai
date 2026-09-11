import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medai/domain/repositories/medication_repository.dart';
import 'package:medai/domain/repositories/symptom_repository.dart';
import 'package:medai/domain/repositories/user_repository.dart';
import 'package:medai/l10n/app_localizations.dart';
import 'package:medai/providers/app_state.dart';
import 'package:medai/screens/app_shell.dart';
import 'package:medai/screens/security/lock_screen.dart';
import 'package:medai/services/link_service.dart';
import 'package:medai/theme/app_theme.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockMedicationRepository extends Mock implements IMedicationRepository {}

class MockUserRepository extends Mock implements IUserRepository {}

class MockSymptomRepository extends Mock implements SymptomRepository {}

class MockAudioPlayer extends Mock implements AudioPlayer {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockLinkService extends Mock implements LinkService {}

/// The shell decides, on every build, whether to show the app or the lock
/// screen. Nothing ever mounted it in a test, so when the flag it reads became
/// disconnected from the flag the setting wrote, the whole suite stayed green
/// while biometric lock silently stopped engaging on a cold start.
///
/// These mount the real AppShell against a real AppState and assert which
/// branch renders. That is the gap that let the bug ship: the unit tests cover
/// the flag, the source-grep tests cover the file's text, and neither builds
/// the widget that actually chooses.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppState appState;

  setUp(() {
    final mockPrefs = MockSharedPreferences();
    final mockLinkService = MockLinkService();
    when(() => mockPrefs.getString(any())).thenReturn(null);
    when(() => mockPrefs.getBool(any())).thenReturn(null);
    when(() => mockLinkService.init()).thenAnswer((_) async {});
    mockLinkService.onJoinCodeDetected = (code) {};

    appState = AppState(
      medRepo: MockMedicationRepository(),
      userRepo: MockUserRepository(),
      symptomRepo: MockSymptomRepository(),
      audioPlayer: MockAudioPlayer(),
      prefs: mockPrefs,
      linkService: mockLinkService,
    );
  });

  /// Mounts the shell exactly as the app does: a real AppState above it, and
  /// the localization + theme the shell reads from.
  Future<void> pumpShell(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          home: const AppShell(child: SizedBox.shrink()),
        ),
      ),
    );
    // A single pump only. LockScreen arms a 400ms timer that calls
    // BiometricService.authenticate(), which returns true under `assert` in a
    // test binding and would unlock the screen out from under the assertion.
    await tester.pump();
  }

  testWidgets('a locked session renders the lock screen, not the app',
      (tester) async {
    appState.auth.isLocked = true;

    await pumpShell(tester);

    expect(find.byType(LockScreen), findsOneWidget,
        reason: 'the shell must gate the app behind the lock screen');

    // Drain the 400ms auth timer with discrete pumps. NOT pumpAndSettle:
    // LockScreen runs a looping flutter_animate effect, so the tree never
    // reaches quiescence and pumpAndSettle can only time out.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('an unlocked session renders the app, not the lock screen',
      (tester) async {
    appState.auth.isLocked = false;

    await pumpShell(tester);

    expect(find.byType(LockScreen), findsNothing,
        reason: 'an unlocked session must not be gated');
  });

  testWidgets('the gate follows the flag the setting actually writes',
      (tester) async {
    // The regression: AuthController held the flag the setting wrote, the
    // shell read a different one, and nothing bridged them. Driving the
    // AuthController flag must move the shell.
    appState.auth.isLocked = false;
    await pumpShell(tester);
    expect(find.byType(LockScreen), findsNothing);

    appState.auth.isLocked = true;
    await tester.pump();

    expect(find.byType(LockScreen), findsOneWidget,
        reason: 'the shell reads AppState.isLocked; it must resolve to the '
            'same flag the biometric setting drives');

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 100));
  });
}
