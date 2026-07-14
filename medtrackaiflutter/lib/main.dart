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
const bool kDevPreview = false;

/// DEV PREVIEW ONLY — initial route to land on after the dev jump. Change this
/// to screenshot a specific screen. Ignored when [kDevPreview] is false.
const String kDevRoute = '/home';

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

    // Initialize App Check for production security
    await FirebaseAppCheck.instance.activate(
      providerAndroid:
          kDebugMode ? AndroidDebugProvider(debugToken: '631C02B3-4721-4D27-9DC7-8CE8D4B664E0') : AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode ? AppleDebugProvider(debugToken: '631C02B3-4721-4D27-9DC7-8CE8D4B664E0') : AppleAppAttestProvider(),
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

    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

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

class _MedAIAppState extends State<MedAIApp> {
  String? _lastKnownUid;
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
        final phase = context.select<AppState, AppPhase>((state) => state.phase);

        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnap) {
            final currentUid = authSnap.data?.uid;

            if (currentUid != _lastKnownUid) {
              _lastKnownUid = currentUid;
              if (phase == AppPhase.app) {
                final appState = context.read<AppState>();
                Future.microtask(() => appState.loadFromStorage());
              }
            }

            return GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: MediaQuery(
                data: MedAiA11y.clampTextScale(MediaQuery.of(context)),
                child: Semantics(
                  label: 'MedAI',
                  child: Container(
                    color: L.meshBg,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: child ?? const SizedBox.expand(),
                      ),
                    ),
                  ),
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

