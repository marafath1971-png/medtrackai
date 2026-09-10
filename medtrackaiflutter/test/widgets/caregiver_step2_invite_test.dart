import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:medai/domain/repositories/medication_repository.dart';
import 'package:medai/domain/repositories/symptom_repository.dart';
import 'package:medai/domain/repositories/user_repository.dart';
import 'package:medai/providers/app_state.dart';
import 'package:medai/screens/family/widgets/add_cg_flow.dart';
import 'package:medai/services/link_service.dart';
import 'package:medai/theme/med_ai_ui.dart';
import 'package:medai/widgets/common/animated_pressable.dart';

/// Step 2 of the add-caregiver flow — the screen the whole flow exists to
/// reach. It had no test coverage at all while three separate layout bugs were
/// being fixed one screen upstream.
///
/// The invite code appears three times here: encoded in the QR, written on the
/// card, and put on the clipboard. They must be the same string — a mismatch
/// hands the user a code that does not match the one the caregiver scans, and
/// nothing on screen would reveal it.
class MockMedicationRepository extends Mock implements IMedicationRepository {}

class MockUserRepository extends Mock implements IUserRepository {}

class MockSymptomRepository extends Mock implements SymptomRepository {}

class MockAudioPlayer extends Mock implements AudioPlayer {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockLinkService extends Mock implements LinkService {}

void main() {
  late AppState appState;
  const code = 'H7K2QP';

  setUp(() {
    final prefs = MockSharedPreferences();
    when(() => prefs.getString(any())).thenReturn(null);
    when(() => prefs.getBool(any())).thenReturn(null);
    when(() => prefs.getInt(any())).thenReturn(null);

    final linkService = MockLinkService();
    when(() => linkService.init()).thenAnswer((_) async {});

    appState = AppState(
      medRepo: MockMedicationRepository(),
      userRepo: MockUserRepository(),
      symptomRepo: MockSymptomRepository(),
      audioPlayer: MockAudioPlayer(),
      prefs: prefs,
      linkService: linkService,
    );
  });

  Caregiver cg({String? inviteCode = code}) => Caregiver(
        id: 1,
        name: 'Sarah Johnson',
        relation: 'Spouse',
        inviteCode: inviteCode,
      );

  Future<void> pumpStep2(WidgetTester tester, {required Caregiver caregiver}) {
    return tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => AddCgStep2(
              cg: caregiver,
              inviteCode: code,
              L: context.L,
              onNext: () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('the QR, the printed code and the clipboard all agree',
      (tester) async {
    // Capture the clipboard channel before the tap.
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await pumpStep2(tester, caregiver: cg());
    await tester.pump();

    // QrImageView keeps its payload private, so assert the QR is present and
    // that the two strings the user can actually read/copy match it. The QR is
    // built from the same `inviteCode` argument as the copy button.
    expect(find.byType(QrImageView), findsOneWidget,
        reason: 'the invite QR must render');
    expect(find.text(code), findsOneWidget,
        reason: 'the code on the card must be the live invite code');

    expect(find.text('Copy code'), findsOneWidget);
    await tester.ensureVisible(find.text('Copy code'));
    await tester.pump();
    await tester.tap(
      find.ancestor(
        of: find.text('Copy code'),
        matching: find.byType(AnimatedPressable),
      ),
      warnIfMissed: false,
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(copied, code,
        reason: 'the clipboard must carry the same code the caregiver scans');

    // The tap arms a 300ms debounce in AnimatedPressable and shows a toast,
    // each with its own timer. Pump past both in fixed steps — the "waiting
    // for caregiver" shimmer loops forever, so pumpAndSettle never returns.
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('a caregiver row with no stored code still shows the live one',
      (tester) async {
    // The screen used to print cg.inviteCode while the QR encoded the
    // inviteCode argument. A caregiver persisted before the code was assigned
    // rendered "------" under a QR that scanned fine — the user would read out
    // six dashes.
    await pumpStep2(tester, caregiver: cg(inviteCode: null));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('------'), findsNothing,
        reason: 'the live invite code is known; nothing should show dashes');
    expect(find.text(code), findsOneWidget);
  });

  testWidgets('it waits for the caregiver rather than claiming success',
      (tester) async {
    await pumpStep2(tester, caregiver: cg());
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Waiting for caregiver to scan...'), findsOneWidget);
    expect(find.text('Success! Caregiver added.'), findsNothing,
        reason: 'a pending invite must not report itself as connected');
  });
}
