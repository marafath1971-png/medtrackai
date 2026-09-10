import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';

import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/app_state.dart';
import 'theme/med_ai_ui.dart';
import 'theme/spring_scroll_behavior.dart';
import 'app/router.dart';
import 'package:go_router/go_router.dart';
import 'services/notification_service.dart';
import 'services/encryption_service.dart';
import 'services/storage_service.dart';
import 'data/datasources/local_prefs_datasource.dart';
import 'data/datasources/firestore_datasource.dart';
import 'data/repositories/medication_repository_impl.dart';
import 'data/repositories/user_repository_impl.dart';
import 'data/repositories/symptom_repository_impl.dart';
import 'widgets/common/global_error_boundary.dart';
import 'services/purchases_service.dart';
import 'services/remote_config_service.dart';

/// DEV PREVIEW ONLY — when true, seeds demo data and jumps straight into the
/// app (bypassing onboarding/auth) so redesigned screens can be reviewed.
/// MUST be false for release. Keep false so onboarding/auth actually run —
/// flip to true only to preview a specific in-app screen via [kDevRoute].
/// Supplied at build time so it cannot be committed in the "on" state:
///   flutter build apk --dart-define=DEV_PREVIEW=true --dart-define=DEV_ROUTE=/stats
const bool kDevPreview =
    bool.fromEnvironment('DEV_PREVIEW', defaultValue: false);

/// DEV PREVIEW ONLY — initial route to land on after the dev jump. Change this
/// to screenshot a specific screen. Ignored when [kDevPreview] is false.
const String kDevRoute =
    String.fromEnvironment('DEV_ROUTE', defaultValue: '/home');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('No .env file found (expected for production builds).');
  }

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    // Initialize App Check for production security.
    //
    // The debug token was hardcoded here and committed. It only works against
    // debug builds, but anyone with the repo could use it to pass App Check on
    // this project, so it comes from the build now:
    //
    //   flutter run --dart-define=APP_CHECK_DEBUG_TOKEN=<uuid>
    //
    // An unset token in a debug build means App Check has no attestation to
    // offer. With enforcement on, every Firestore read is then denied with
    // PERMISSION_DENIED that looks exactly like a rules bug — so say so loudly
    // rather than letting it be diagnosed as one.
    const debugToken = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN');
    if (kDebugMode && debugToken.isEmpty) {
      debugPrint(
        'APP CHECK: no debug token. If App Check is enforced, every Firestore '
        'request will fail with PERMISSION_DENIED regardless of the security '
        'rules. Pass --dart-define=APP_CHECK_DEBUG_TOKEN=<uuid> and register '
        'that uuid under App Check > Apps > Manage debug tokens.',
      );
    }
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? AndroidDebugProvider(debugToken: debugToken)
          : AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? AppleDebugProvider(debugToken: debugToken)
          : AppleAppAttestProvider(),
    );
  } catch (e) {
    debugPrint('Firebase/AppCheck initialization failure: $e');
  }

  // Remote Config: experiment switchboard (non-blocking — defaults ship in
  // code, so a failed fetch never delays or breaks launch).
  unawaited(RemoteConfigService.init());

  // Initialize Performance Monitoring
  try {
    FirebasePerformance.instance.setPerformanceCollectionEnabled(!kDebugMode);
  } catch (e) {
    debugPrint('FirebasePerformance initialization failure: $e');
  }

  // Set Production Version Metadata in Crashlytics
  try {
    await FirebaseCrashlytics.instance.setCustomKey('app_version', '1.0.0+1');

    // Pass framework errors to Crashlytics without treating every paint glitch
    // as a fatal kill — that previously left users on a blank black screen.
    FlutterError.onError = (details) {
      FirebaseCrashlytics.instance.recordFlutterError(details);
      FlutterError.presentError(details);
    };

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    debugPrint('FirebaseCrashlytics initialization failure: $e');
  }

  // Initialize Peripheral Services in Parallel
  final results = await Future.wait([
    NotificationService.init(),
    EncryptionService.init(),
    SharedPreferences.getInstance(),
    PurchasesService.init(),
  ]);

  // A release build that cannot sell anything is almost always an accident:
  // .env is gitignored, so a clean checkout has no key, and every billing
  // failure downstream is silent by design — the paywall just says "Not
  // available yet" and the user cannot pay. Fail loudly at startup instead of
  // discovering it from the revenue graph.
  //
  // Supply the key at build time:
  //   flutter build appbundle --dart-define=RC_GOOGLE_KEY=goog_xxx
  assert(() {
    if (!PurchasesService.hasSellableKey) {
      debugPrint('BILLING DISABLED: no valid RevenueCat key. '
          'Pass --dart-define=RC_GOOGLE_KEY=goog_... to sell anything.');
    }
    return true;
  }());
  if (kReleaseMode && !PurchasesService.hasSellableKey) {
    FlutterError.reportError(FlutterErrorDetails(
      exception: StateError(
        'Release build has no valid RevenueCat key: billing is disabled and '
        'no user can purchase. Build with '
        '--dart-define=RC_GOOGLE_KEY=goog_... (or RC_APPLE_KEY for iOS).',
      ),
      library: 'purchases',
      context: ErrorDescription('startup billing configuration check'),
    ));
  }

  final prefs = results[2] as SharedPreferences;
  final localDataSource = LocalDataSource(prefs);
  final firestoreDataSource = FirestoreDataSource();
  final storageService = StorageService();

  final medRepo = MedicationRepositoryImpl(
      localDataSource, firestoreDataSource, storageService);
  final userRepo = UserRepositoryImpl(localDataSource, firestoreDataSource);
  final symptomRepo = SymptomRepositoryImpl(localDataSource);

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    GlobalErrorBoundary(
      child: ChangeNotifierProvider(
        create: (_) {
          final s = AppState(
            medRepo: medRepo,
            userRepo: userRepo,
            symptomRepo: symptomRepo,
            prefs: prefs,
          );
          final loaded = s.loadFromStorage();
          // DEV PREVIEW ONLY — remove before release.
          if (kDevPreview) {
            loaded.then((_) => s.devPreviewJump());
          }
          return s;
        },
        builder: (context, child) {
          final state = context.read<AppState>();
          return MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: state.auth),
              ChangeNotifierProvider.value(value: state.med),
              ChangeNotifierProvider.value(value: state.wellness),
              ChangeNotifierProvider.value(value: state.social),
              ChangeNotifierProvider.value(value: state.health),
            ],
            child: const MedAIApp(),
          );
        },
      ),
    ),
  );
}

class MedAIApp extends StatefulWidget {
  const MedAIApp({super.key});

  @override
  State<MedAIApp> createState() => _MedAIAppState();
}

/// Sentinel meaning "no authStateChanges emission seen yet".
///
/// Distinct from `null`, which is a real value the stream emits before Firebase
/// has restored a stored session.
const String kNoUidSeenYet = '\u0000uninitialised';

/// Whether an auth-state emission should trigger a full reload.
///
/// Extracted so the cold-start ordering is testable without Firebase. The bug
/// it encodes: on a cold start `loadProfile()` runs before Firebase restores
/// the session, so the repository sees no auth and returns the LOCAL profile.
/// The app then comes up as a different person than the signed-in account, and
/// anything keyed to the uid — invite codes especially — fails as signed-out.
/// Gaining a uid must always reload, whatever phase we are in.
bool shouldReloadForAuthChange({
  required String? previousUid,
  required String? currentUid,
  required AppPhase phase,
}) {
  if (previousUid == currentUid) return false;
  // A uid appearing (or changing to a different account) always re-resolves.
  if (currentUid != null) return true;
  // Losing a uid only matters once the app is running; the signed-out cold
  // start has already loaded once from bootstrap.
  return previousUid != kNoUidSeenYet && phase == AppPhase.app;
}

class _MedAIAppState extends State<MedAIApp> {
  String? _lastKnownUid = kNoUidSeenYet;
  GoRouter? _router;
  AppState? _lastAppState;

  GoRouter _getRouter(AppState appState) {
    // Only recreate router if AppState instance changed (e.g. full re-login)
    if (_router == null || !identical(_lastAppState, appState)) {
      _router?.dispose();
      _lastAppState = appState;
      _router = createRouter(appState);
    }
    return _router!;
  }

  @override
  void dispose() {
    _router?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentHex = context
        .select<AppState, String?>((state) => state.profile?.accentColor);

    final isDark = context.select<AppState, bool>((state) => state.darkMode);
    final lightTheme = AppTheme.light(accentHex: accentHex);
    final darkTheme = AppTheme.dark(isAmoled: true, accentHex: accentHex);
    final language =
        context.select<AppState, String>((state) => state.language);

    final appState = context.watch<AppState>();
    final router = _getRouter(appState);

    return MaterialApp.router(
      title: 'MedAI',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        final L = context.L;
        final phase =
            context.select<AppState, AppPhase>((state) => state.phase);

        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnap) {
            final currentUid = authSnap.data?.uid;

            if (currentUid != _lastKnownUid) {
              final previous = _lastKnownUid;
              _lastKnownUid = currentUid;

              // Reload whenever a real uid appears, not only while already in
              // AppPhase.app. On a cold start loadProfile() runs before
              // Firebase has restored the session, so the repository sees no
              // auth and falls back to the LOCAL profile; the app comes up as
              // a different person than the account that is signed in, and
              // anything keyed to the uid (invite codes) fails as signed-out.
              //
              // Skip the very first emission when it carries no uid: that is
              // the genuine signed-out start, and loadFromStorage has already
              // run once from bootstrap.
              if (shouldReloadForAuthChange(
                  previousUid: previous,
                  currentUid: currentUid,
                  phase: phase)) {
                final appState = context.read<AppState>();
                Future.microtask(() => appState.loadFromStorage());
              }
            }

            // Phone/tablet shell: size the navigator from MediaQuery, never from
            // loosened Center/LayoutBuilder constraints (those can yield 0×0 and
            // paint only meshBg — the cream blank screen).
            return GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: MediaQuery(
                data: MedAiA11y.clampTextScale(MediaQuery.of(context)),
                child: Builder(
                  builder: (context) {
                    final size = MediaQuery.sizeOf(context);
                    final width = size.width > 430 ? 430.0 : size.width;
                    return Semantics(
                      label: 'MedAI',
                      child: ColoredBox(
                        color: L.meshBg,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            width: width,
                            height: size.height,
                            child: child ?? const SizedBox.expand(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
      scrollBehavior: const SpringScrollBehavior(),
      routerConfig: router,
    );
  }
}
