import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medai/main.dart' show kDevPreview, kDevRoute;
import 'package:medai/app/app_routes.dart';
import 'package:medai/screens/app_shell.dart';
import 'package:medai/screens/home/home_tab.dart';
import 'package:medai/screens/dashboard/dashboard_tab.dart';
import 'package:medai/screens/alarms/alarms_tab.dart';
import 'package:medai/screens/family/family_tab.dart';
import 'package:medai/screens/scan/scanner_hub_screen.dart';
import 'package:medai/screens/scan/pill_identifier_screen.dart';
import 'package:medai/screens/scan/scan_history_screen.dart';
import 'package:medai/screens/scan/scanner_help_screen.dart';
import 'package:medai/screens/scan/ai_accuracy_settings_screen.dart';
import 'package:medai/screens/onboarding/onboarding_flow.dart';
import 'package:medai/screens/auth/auth_screen.dart';
import 'package:medai/screens/loading/loading_screen.dart';
import 'package:medai/screens/stats/analytics_dashboard_screen.dart';
import 'package:medai/screens/stats/inventory_visualizer_screen.dart';
import 'package:medai/screens/stats/trophy_case_screen.dart';
import 'package:medai/screens/stats/monthly_wrapped_screen.dart';
import 'package:medai/screens/social/med_buddies_screen.dart';
import 'package:medai/screens/settings/global_settings_screen.dart';
import 'package:medai/screens/settings/privacy_policy_screen.dart';
import 'package:medai/screens/settings/terms_of_service_screen.dart';
import 'package:medai/screens/focus/focus_mode_screen.dart';
import 'package:medai/screens/visualizer/impact_visualizer_screen.dart';
import 'package:medai/screens/family/add_dependent_screen.dart';
import 'package:medai/screens/family/add_family_member_screen.dart';
import 'package:medai/screens/family/edit_family_member_screen.dart';
import 'package:medai/screens/family/profile_pin_screen.dart';
import 'package:medai/screens/auth/pin_verification_screen.dart';
import 'package:medai/screens/analysis/product_chat_screen.dart';
import 'package:medai/screens/medicine/medicine_detail_screen.dart';
import 'package:medai/screens/settings/theme_customization_screen.dart';
import 'package:medai/screens/social/med_wrapped_screen.dart';
import 'package:medai/screens/admin/growth_dashboard_screen.dart';
import 'package:medai/screens/analysis/product_analysis_screen.dart';
import 'package:medai/providers/app_state.dart';
import 'package:medai/theme/app_theme.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

CustomTransitionPage<void> _fadeTabPage({required Widget child}) {
  return CustomTransitionPage<void>(
    child: child,
    transitionDuration: AppDurations.tab,
    reverseTransitionDuration: AppDurations.exit,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppCurves.emilOut,
        reverseCurve: AppCurves.emilOut,
      );
      return FadeTransition(opacity: curved, child: child);
    },
  );
}

CustomTransitionPage<void> _springPage({required Widget child}) {
  return CustomTransitionPage<void>(
    child: child,
    transitionDuration: AppDurations.hero,
    reverseTransitionDuration: AppDurations.exit,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slide = Tween<Offset>(
        begin: const Offset(0, 0.06),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: AppCurves.smooth));
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}

CustomTransitionPage<void> _slidePage({required Widget child}) {
  return CustomTransitionPage<void>(
    child: child,
    transitionDuration: AppDurations.hero,
    reverseTransitionDuration: AppDurations.exit,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slide = Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: AppCurves.smooth));
      return SlideTransition(position: slide, child: FadeTransition(opacity: animation, child: child));
    },
  );
}

List<RouteBase> _rootOverlayRoutes() => [
  GoRoute(
    path: AppRoutes.scan,
    parentNavigatorKey: rootNavigatorKey,
    pageBuilder: (context, state) {
      final mode = state.uri.queryParameters['mode'];
      ScanMode? initialMode;
      switch (mode) {
        case 'barcode':
          initialMode = ScanMode.barcode;
          break;
        case 'search':
          initialMode = ScanMode.search;
          break;
        case 'voice':
          initialMode = ScanMode.voice;
          break;
        default:
          initialMode = ScanMode.camera;
      }
      return CustomTransitionPage<void>(
        child: ScannerHubScreen(
          onClose: () => context.pop(),
          initialMode: initialMode,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: AppCurves.liquid),
              ),
              child: child,
            ),
          );
        },
      );
    },
  ),
  GoRoute(
    path: AppRoutes.scanPill,
    parentNavigatorKey: rootNavigatorKey,
    pageBuilder: (context, state) =>
        _slidePage(child: const PillIdentifierScanner()),
  ),
  GoRoute(
    path: AppRoutes.scanHistory,
    parentNavigatorKey: rootNavigatorKey,
    pageBuilder: (context, state) =>
        _slidePage(child: const ScanHistoryScreen()),
  ),
  GoRoute(
    path: AppRoutes.scanHelp,
    parentNavigatorKey: rootNavigatorKey,
    pageBuilder: (context, state) =>
        _slidePage(child: const ScannerHelpScreen()),
  ),
  GoRoute(
    path: AppRoutes.scanAccuracy,
    parentNavigatorKey: rootNavigatorKey,
    pageBuilder: (context, state) =>
        _slidePage(child: const AiAccuracySettingsScreen()),
  ),
  GoRoute(
    path: AppRoutes.statsAnalytics,
    parentNavigatorKey: rootNavigatorKey,
    pageBuilder: (context, state) =>
        _slidePage(child: const AnalyticsDashboardScreen()),
  ),
  GoRoute(
    path: AppRoutes.statsInventory,
    parentNavigatorKey: rootNavigatorKey,
    pageBuilder: (context, state) =>
        _slidePage(child: const InventoryVisualizerScreen()),
  ),
  GoRoute(
    path: AppRoutes.statsTrophy,
    parentNavigatorKey: rootNavigatorKey,
    pageBuilder: (context, state) =>
        _slidePage(child: const TrophyCaseScreen()),
  ),
  GoRoute(
    path: AppRoutes.statsWrapped,
    parentNavigatorKey: rootNavigatorKey,
    pageBuilder: (context, state) => CustomTransitionPage<void>(
      fullscreenDialog: true,
      child: const MonthlyWrappedScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  ),
  GoRoute(
    path: AppRoutes.statsBuddies,
    parentNavigatorKey: rootNavigatorKey,
    pageBuilder: (context, state) =>
        _slidePage(child: const MedBuddiesScreen()),
  ),
  GoRoute(
    path: AppRoutes.settingsGlobal,
    parentNavigatorKey: rootNavigatorKey,
    pageBuilder: (context, state) =>
        _slidePage(child: const GlobalSettingsScreen()),
  ),
  GoRoute(
    path: AppRoutes.settingsPrivacy,
    parentNavigatorKey: rootNavigatorKey,
    pageBuilder: (context, state) =>
        _slidePage(child: const PrivacyPolicyScreen()),
  ),
  GoRoute(
    path: AppRoutes.settingsTerms,
    parentNavigatorKey: rootNavigatorKey,
    pageBuilder: (context, state) =>
        _slidePage(child: const TermsOfServiceScreen()),
  ),
  GoRoute(
    path: AppRoutes.focusMode,
    parentNavigatorKey: rootNavigatorKey,
    pageBuilder: (context, state) =>
        _slidePage(child: const FocusModeScreen()),
  ),
  GoRoute(
    path: AppRoutes.impactVisualizer,
    parentNavigatorKey: rootNavigatorKey,
    pageBuilder: (context, state) =>
        _slidePage(child: const ImpactVisualizerScreen()),
  ),
  GoRoute(
    path: AppRoutes.familyAddDependent,
    parentNavigatorKey: rootNavigatorKey,
    pageBuilder: (context, state) =>
        _slidePage(child: const AddDependentScreen()),
  ),
  GoRoute(
    path: AppRoutes.familyAddMember,
    parentNavigatorKey: rootNavigatorKey,
    pageBuilder: (context, state) {
      final dialog = state.uri.queryParameters['dialog'] == 'true';
      if (dialog) {
        return CustomTransitionPage<void>(
          fullscreenDialog: true,
          child: const AddFamilyMemberScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      }
      return _slidePage(child: const AddFamilyMemberScreen());
    },
  ),
  GoRoute(
    path: AppRoutes.familyPin,
    parentNavigatorKey: rootNavigatorKey,
    pageBuilder: (context, state) {
      final extra = state.extra;
      if (extra is! ProfilePinRouteArgs) {
        return _slidePage(child: const SizedBox.shrink());
      }
      return _slidePage(
        child: ProfilePinScreen(profile: extra.profile),
      );
    },
  ),
  GoRoute(
    path: AppRoutes.familyEditMember,
    parentNavigatorKey: rootNavigatorKey,
    pageBuilder: (context, state) {
      final extra = state.extra;
      if (extra is! EditFamilyMemberRouteArgs) {
        return _slidePage(child: const SizedBox.shrink());
      }
      return _slidePage(
        child: EditFamilyMemberScreen(member: extra.member),
      );
    },
  ),
  GoRoute(
    path: AppRoutes.authPinVerify,
    parentNavigatorKey: rootNavigatorKey,
    pageBuilder: (context, state) {
      final extra = state.extra;
      if (extra is! PinVerificationRouteArgs) {
        return _slidePage(child: const SizedBox.shrink());
      }
      return _slidePage(
        child: PinVerificationScreen(
          correctPin: extra.correctPin,
          profileName: extra.profileName,
        ),
      );
    },
  ),
  GoRoute(
    path: AppRoutes.analysisChat,
    parentNavigatorKey: rootNavigatorKey,
    pageBuilder: (context, state) {
      final extra = state.extra;
      if (extra is! ProductChatRouteArgs) {
        return _slidePage(child: const SizedBox.shrink());
      }
      return _slidePage(
        child: ProductChatScreen(product: extra.product),
      );
    },
  ),
  GoRoute(
    path: AppRoutes.settingsTheme,
    parentNavigatorKey: rootNavigatorKey,
    pageBuilder: (context, state) =>
        _slidePage(child: const ThemeCustomizationScreen()),
  ),
  GoRoute(
    path: AppRoutes.statsMedWrapped,
    parentNavigatorKey: rootNavigatorKey,
    pageBuilder: (context, state) => CustomTransitionPage<void>(
      fullscreenDialog: true,
      child: const MedWrappedScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  ),
  GoRoute(
    path: AppRoutes.adminGrowth,
    parentNavigatorKey: rootNavigatorKey,
    // Internal growth dashboard — must never reach real users. Hard-gated to
    // debug/profile builds: release always redirects home regardless of any
    // dev flag, so it can't ship even if kDevPreview is accidentally left on.
    redirect: (context, state) => kReleaseMode ? AppRoutes.home : null,
    pageBuilder: (context, state) =>
        _slidePage(child: const GrowthDashboardScreen()),
  ),
  GoRoute(
    path: AppRoutes.medicineDetail,
    parentNavigatorKey: rootNavigatorKey,
    pageBuilder: (context, state) {
      final medIdStr = state.pathParameters['medId'];
      final medId = int.tryParse(medIdStr ?? '');
      if (medId == null) {
        return _slidePage(child: const SizedBox.shrink());
      }
      final edit = state.uri.queryParameters['edit'] == 'true';
      return _slidePage(
        child: MedicineDetailScreen(
          medId: medId,
          initialEditMode: edit,
          onBack: () => context.pop(),
        ),
      );
    },
  ),
  GoRoute(
    path: AppRoutes.analysisProduct,
    parentNavigatorKey: rootNavigatorKey,
    pageBuilder: (context, state) {
      final extra = state.extra;
      if (extra is! ProductAnalysisRouteArgs) {
        return _slidePage(child: const SizedBox.shrink());
      }
      return _slidePage(
        child: ProductAnalysisScreen(
          product: extra.product,
          imageFile: extra.imageFile,
        ),
      );
    },
  ),
];

GoRouter createRouter(AppState appState) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.home,
    observers: [FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)],
    refreshListenable: appState,
    redirect: (context, state) {
      final phase = appState.phase;
      final currentPath = state.uri.path;

      if (phase == AppPhase.loading) {
        return currentPath == AppRoutes.loading ? null : AppRoutes.loading;
      }
      if (phase == AppPhase.onboarding) {
        return currentPath == AppRoutes.onboarding ? null : AppRoutes.onboarding;
      }
      if (phase == AppPhase.auth) {
        return currentPath == AppRoutes.auth ? null : AppRoutes.auth;
      }

      if (phase == AppPhase.app &&
          (currentPath == AppRoutes.loading ||
              currentPath == AppRoutes.onboarding ||
              currentPath == AppRoutes.auth)) {
        return kDevPreview ? kDevRoute : AppRoutes.home;
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.loading,
        pageBuilder: (context, state) => _springPage(child: const LoadingScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) => _springPage(child: const OnboardingFlow()),
      ),
      GoRoute(
        path: AppRoutes.auth,
        pageBuilder: (context, state) => _springPage(child: const AuthScreen()),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return AppShell(child: child);
        },
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => _fadeTabPage(
              child: HomeTab(
                onScan: () => context.push(AppRoutes.scan),
                onSwitchTab: (i) {
                  if (i == 0) {
                    context.go(AppRoutes.home);
                  } else if (i == 1) {
                    context.go(AppRoutes.analytics);
                  } else if (i == 2) {
                    context.go(AppRoutes.alarms);
                  } else if (i == 3) {
                    context.go(AppRoutes.circle);
                  }
                },
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.analytics,
            pageBuilder: (context, state) => _fadeTabPage(
              child: DashboardTab(onScan: () => context.push(AppRoutes.scan)),
            ),
          ),
          GoRoute(
            path: AppRoutes.alarms,
            pageBuilder: (context, state) => _fadeTabPage(
              child: AlarmsTab(),
            ),
          ),
          GoRoute(
            path: AppRoutes.circle,
            pageBuilder: (context, state) => _fadeTabPage(
              child: FamilyTab(),
            ),
          ),
        ],
      ),
      ..._rootOverlayRoutes(),
    ],
  );
}
