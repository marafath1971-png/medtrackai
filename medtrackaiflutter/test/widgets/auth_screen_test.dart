import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:medai/domain/repositories/medication_repository.dart';
import 'package:medai/domain/repositories/symptom_repository.dart';
import 'package:medai/domain/repositories/user_repository.dart';
import 'package:medai/providers/app_state.dart';
import 'package:medai/screens/auth/auth_screen.dart';
import 'package:medai/services/link_service.dart';
import 'package:medai/theme/med_ai_ui.dart';
import 'package:medai/widgets/common/solid_surface.dart';

/// The sign-in screen, rendered whole.
///
/// The shipped bug: "Continue with Apple" used a MedAiGlass surface tinted
/// L.text with white content. Light mode discards that tint and paints L.card,
/// so the button rendered as an empty white pill. Sign-in is mandatory, so this
/// blocked Apple sign-in for every iOS user in light mode.
///
/// Only `context.watch<AppState>().onboardingPrefs` is read during build — the
/// Firebase calls all sit in tap handlers — so a provided AppState with mocked
/// repositories is enough to render it. No Firebase initialisation required.
class MockMedicationRepository extends Mock implements IMedicationRepository {}

class MockUserRepository extends Mock implements IUserRepository {}

class MockSymptomRepository extends Mock implements SymptomRepository {}

class MockAudioPlayer extends Mock implements AudioPlayer {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockLinkService extends Mock implements LinkService {}

double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  late AppState appState;

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

  Future<AppThemeColors> pumpAuth(WidgetTester tester,
      {TargetPlatform platform = TargetPlatform.iOS}) async {
    late AppThemeColors colors;

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: MaterialApp(
          theme: AppTheme.light().copyWith(platform: platform),
          home: Builder(builder: (context) {
            colors = context.L;
            return const AuthScreen();
          }),
        ),
      ),
    );
    // The screen staggers entrance animations; settle them so no timer is
    // pending at teardown.
    await tester.pump(const Duration(milliseconds: 700));
    return colors;
  }

  testWidgets('the screen renders its sign-in options', (tester) async {
    await pumpAuth(tester);

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Email'), findsOneWidget);
  });

  testWidgets('the Apple button appears on iOS', (tester) async {
    await pumpAuth(tester, platform: TargetPlatform.iOS);
    expect(find.text('Continue with Apple'), findsOneWidget);
  });

  testWidgets('the Apple button is absent on Android', (tester) async {
    await pumpAuth(tester, platform: TargetPlatform.android);
    expect(find.text('Continue with Apple'), findsNothing,
        reason: 'Apple sign-in is an iOS affordance');
  });

  testWidgets('every sign-in button uses SolidSurface', (tester) async {
    await pumpAuth(tester);

    // Apple, Google and Email — the regression was one of them reverting to a
    // glass surface whose tint light mode throws away.
    expect(tester.widgetList<SolidSurface>(find.byType(SolidSurface)).length,
        greaterThanOrEqualTo(3));
  });

  testWidgets('the Apple button is filled; the others are not', (tester) async {
    await pumpAuth(tester);

    final surfaces =
        tester.widgetList<SolidSurface>(find.byType(SolidSurface)).toList();
    final filled = surfaces.where((s) => s.filled).toList();
    final unfilled = surfaces.where((s) => !s.filled).toList();

    expect(filled, hasLength(1),
        reason: 'only the Apple button uses the dark variant');
    expect(unfilled, isNotEmpty,
        reason: 'Google and Email stay light');
  });

  testWidgets('the Apple button paints a dark fill, not a white pill',
      (tester) async {
    await pumpAuth(tester);

    // Find the DecoratedBox belonging to the one filled surface.
    final filledFinder = find.byWidgetPredicate(
        (w) => w is SolidSurface && w.filled);
    expect(filledFinder, findsOneWidget);

    final box = tester.widget<DecoratedBox>(
      find
          .descendant(of: filledFinder, matching: find.byType(DecoratedBox))
          .first,
    );
    final fill = (box.decoration as BoxDecoration).color!;

    expect(_contrast(fill, Colors.white), greaterThan(4.5),
        reason: 'the button label is white — this is the exact assertion that '
            'would have caught the empty-pill bug');
  });

  testWidgets('the Apple button label is actually rendered', (tester) async {
    await pumpAuth(tester);

    final label = tester.widget<Text>(find.text('Continue with Apple'));
    expect(label.style?.color, Colors.white,
        reason: 'white text is only legible because the fill is dark');
  });

  testWidgets('tapping Email opens the sheet without touching Firebase',
      (tester) async {
    await pumpAuth(tester);

    await tester.tap(find.text('Continue with Email'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // The sheet has its own email field; the screen behind it does not.
    expect(find.byType(TextField), findsWidgets);
  });
}
