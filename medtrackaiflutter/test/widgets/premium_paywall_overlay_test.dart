// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:firebase_analytics_platform_interface/firebase_analytics_platform_interface.dart';

import 'package:medai/l10n/app_localizations.dart';
import 'package:medai/theme/app_theme.dart';
import 'package:medai/providers/app_state.dart';
import 'package:medai/domain/repositories/medication_repository.dart';
import 'package:medai/domain/repositories/user_repository.dart';
import 'package:medai/domain/repositories/symptom_repository.dart';
import 'package:medai/services/link_service.dart';
import 'package:medai/services/purchases_service.dart';
import 'package:medai/widgets/common/animated_pressable.dart';
import 'package:medai/screens/paywall/premium_paywall_overlay.dart';

class MockMedicationRepository extends Mock implements IMedicationRepository {}
class MockUserRepository extends Mock implements IUserRepository {}
class MockSymptomRepository extends Mock implements SymptomRepository {}
class MockAudioPlayer extends Mock implements AudioPlayer {}
class MockSharedPreferences extends Mock implements SharedPreferences {}
class MockLinkService extends Mock implements LinkService {}

class FakeMedicine extends Fake implements Medicine {}
class FakeUserProfile extends Fake implements UserProfile {}
class FakeStreakData extends Fake implements StreakData {}

class FakeAnalyticsPlatform extends FirebaseAnalyticsPlatform {
  FakeAnalyticsPlatform() : super();

  @override
  FirebaseAnalyticsPlatform delegateFor({
    required FirebaseApp app,
    Map<String, dynamic>? webOptions,
  }) {
    return this;
  }

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object?>? parameters,
    AnalyticsCallOptions? callOptions,
  }) async {}

  @override
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('purchases_flutter');

  final mockWeekly = {
    'identifier': r'$rc_weekly',
    'packageType': 'WEEKLY',
    'product': {
      'identifier': 'medai_pro_subscription:weekly',
      'description': 'Med AI Pro Weekly',
      'title': 'Weekly',
      'price': 4.99,
      'priceString': '\$4.99',
      'currencyCode': 'USD',
      'subscriptionPeriod': 'P1W',
    },
    'presentedOfferingContext': {
      'offeringIdentifier': 'default',
    }
  };

  final mockAnnual = {
    'identifier': r'$rc_annual',
    'packageType': 'ANNUAL',
    'product': {
      'identifier': 'medai_pro_subscription:yearly',
      'description': 'Med AI Pro Yearly',
      'title': 'Yearly',
      'price': 36.99,
      'priceString': '\$36.99',
      'currencyCode': 'USD',
      'subscriptionPeriod': 'P1Y',
      'introPrice': {
        'price': 0.0,
        'priceString': '\$0.00',
        'period': 'P2D',
        'cycles': 1,
        'periodUnit': 'DAY',
        'periodNumberOfUnits': 2,
      }
    },
    'presentedOfferingContext': {
      'offeringIdentifier': 'default',
    }
  };

  final mockMonthly = {
    'identifier': r'$rc_monthly',
    'packageType': 'MONTHLY',
    'product': {
      'identifier': 'medai_pro_subscription:monthly',
      'description': 'Med AI Pro Monthly',
      'title': 'Monthly',
      'price': 7.99,
      'priceString': '\$7.99',
      'currencyCode': 'USD',
      'subscriptionPeriod': 'P1M',
    },
    'presentedOfferingContext': {
      'offeringIdentifier': 'default',
    }
  };

  final mockLifetime = {
    'identifier': r'$rc_lifetime',
    'packageType': 'LIFETIME',
    'product': {
      'identifier': 'medai_pro_lifetime',
      'description': 'Med AI Pro Lifetime',
      'title': 'Lifetime',
      'price': 49.99,
      'priceString': '\$49.99',
      'currencyCode': 'USD',
    },
    'presentedOfferingContext': {
      'offeringIdentifier': 'default',
    }
  };

  final mockOfferingsData = {
    'all': {
      'default': {
        'identifier': 'default',
        'serverDescription': 'Standard offering',
        'metadata': {},
        'availablePackages': [mockAnnual, mockWeekly, mockMonthly, mockLifetime],
        'annual': mockAnnual,
        'weekly': mockWeekly,
        'monthly': mockMonthly,
        'lifetime': mockLifetime,
      }
    },
    'current': {
      'identifier': 'default',
      'serverDescription': 'Standard offering',
      'metadata': {},
      'availablePackages': [mockAnnual, mockWeekly, mockMonthly, mockLifetime],
      'annual': mockAnnual,
      'weekly': mockWeekly,
      'monthly': mockMonthly,
      'lifetime': mockLifetime,
    }
  };

  final mockEntitlement = {
    'identifier': 'premium',
    'isActive': true,
    'willRenew': true,
    'periodType': 'NORMAL',
    'latestPurchaseDate': '2026-11-10T00:00:00.000Z',
    'originalPurchaseDate': '2026-11-10T00:00:00.000Z',
    'expirationDate': '2026-11-17T00:00:00.000Z',
    'store': 'PLAY_STORE',
    'productIdentifier': 'medai_pro_subscription:weekly',
    'isSandbox': true,
    'unsubscribeDetectedAt': null,
    'billingIssueDetectedAt': null,
  };

  final mockCustomerInfo = {
    'originalAppUserId': 'test-user',
    'entitlements': {
      'all': {
        'premium': mockEntitlement,
      },
      'active': {
        'premium': mockEntitlement,
      },
      'verification': 'NOT_REQUESTED',
    },
    'activeSubscriptions': ['medai_pro_subscription:weekly'],
    'allPurchasedProductIdentifiers': ['medai_pro_subscription:weekly'],
    'firstSeen': '2026-11-10T00:00:00.000Z',
    'requestDate': '2026-11-10T00:00:00.000Z',
    'allPurchaseDates': {},
    'allExpirationDates': {},
    'nonSubscriptionTransactions': [],
  };

  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
    FirebaseAnalyticsPlatform.instance = FakeAnalyticsPlatform();
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

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockMedRepo = MockMedicationRepository();
    mockUserRepo = MockUserRepository();
    mockSymptomRepo = MockSymptomRepository();
    mockAudioPlayer = MockAudioPlayer();
    mockPrefs = MockSharedPreferences();
    mockLinkService = MockLinkService();

    when(() => mockUserRepo.getProfile()).thenAnswer((_) async => null);
    when(() => mockUserRepo.getLanguage()).thenAnswer((_) async => 'en');
    when(() => mockUserRepo.saveProfile(any())).thenAnswer((_) async {});
    when(() => mockUserRepo.saveLanguage(any())).thenAnswer((_) async {});

    when(() => mockPrefs.getInt(any())).thenReturn(null);
    when(() => mockPrefs.getString(any())).thenReturn(null);
    when(() => mockPrefs.getBool(any())).thenReturn(null);
    when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);

    when(() => mockLinkService.init()).thenAnswer((_) async {});
    mockLinkService.onJoinCodeDetected = (code) {};

    // Initialize dotenv with valid test RevenueCat key
    await dotenv.load(
      isOptional: true,
      mergeWith: {
        'RC_GOOGLE_KEY': 'goog_gmbIsfKRzXmFmftiNpfmhHyoarT',
        'RC_APPLE_KEY': 'appl_testKey1234567890abcdef',
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MethodChannelFirebaseAnalytics.channel, (call) async => true);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'setupPurchases':
          return null;
        case 'setLogLevel':
          return null;
        case 'getOfferings':
          return mockOfferingsData;
        case 'getCustomerInfo':
          return mockCustomerInfo;
        case 'purchasePackage':
          return {
            'customerInfo': mockCustomerInfo,
            'transaction': {
              'transactionIdentifier': 'mock_transaction_123',
              'productIdentifier': call.arguments['packageIdentifier'],
              'purchaseDate': '2026-11-10T00:00:00.000Z',
            },
          };
        default:
          return null;
      }
    });

    await PurchasesService.init();

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
        .setMockMethodCallHandler(channel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/firebase_analytics'), null);
  });

  Widget buildTestableWidget({VoidCallback? onSuccess, VoidCallback? onDismiss}) {
    return ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(),
        home: Scaffold(
          body: PremiumPaywallOverlay(
            onSuccess: onSuccess,
            onDismiss: onDismiss,
          ),
        ),
      ),
    );
  }

  group('PremiumPaywallOverlay live functioning', () {
    testWidgets('renders all 4 psychological pricing plans with anchors', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget());
      for (int i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Check psychological plan labels render
      expect(find.text('Yearly'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Lifetime'), findsOneWidget);

      // Check prices render
      expect(find.text(r'$36.99'), findsOneWidget);
      expect(find.text(r'$4.99'), findsOneWidget);
      expect(find.text(r'$7.99'), findsOneWidget);
      expect(find.text(r'$49.99'), findsOneWidget);

      // Check psychological anchor text
      // Weekly anchor: $4.99 * 52 = $259.48 strikethrough on Annual
      expect(find.text('USD 259.48/yr'), findsOneWidget);
      // Weekly breakdown: $36.99 / 52 = $0.71/wk
      expect(find.text('≈ USD 0.71/wk'), findsOneWidget);
      // Weekly tile equivalent text: $4.99*52/12 = $21.62/mo ($259/yr)
      expect(find.text('≈ USD 21.62/mo (USD 259/yr)'), findsOneWidget);
      // Monthly equivalent subtext: vs $21.62/mo wkly
      expect(find.text('vs USD 21.62/mo wkly'), findsOneWidget);
      // Lifetime equivalent subtext
      expect(find.text('Never pay again'), findsOneWidget);

      // Check badges
      expect(find.text('Flexible'), findsOneWidget);
      expect(find.text('Pay once'), findsOneWidget);
    });

    testWidgets('switching plans updates selection and CTA button', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget());
      for (int i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Pre-selected is Annual with 2-day trial
      expect(find.text('Start 2-Day Free Trial'), findsOneWidget);

      // Tap Weekly plan
      await tester.tap(find.text('Weekly'));
      await tester.pump(const Duration(milliseconds: 350));

      // CTA updates to Weekly rate
      expect(find.text(r'Start Weekly · $4.99'), findsOneWidget);
      expect(find.text('Cancel anytime in store settings'), findsOneWidget);

      // Tap Monthly plan
      await tester.tap(find.text('Monthly'));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text(r'Start Monthly · $7.99'), findsOneWidget);

      // Tap Lifetime plan
      await tester.tap(find.text('Lifetime'));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text(r'Start Lifetime · $49.99'), findsOneWidget);
    });

    testWidgets('CTA button triggers successful purchase flow and callback', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool successCalled = false;
      await tester.pumpWidget(buildTestableWidget(
        onSuccess: () => successCalled = true,
      ));
      for (int i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Tap Weekly plan
      await tester.tap(find.text('Weekly'));
      await tester.pump(const Duration(milliseconds: 400));

      // Tap CTA to buy
      final ctaFinder = find.ancestor(
        of: find.text(r'Start Weekly · $4.99'),
        matching: find.byType(AnimatedPressable),
      );
      expect(ctaFinder, findsOneWidget);
      tester.widget<AnimatedPressable>(ctaFinder).onTap?.call();
      for (int i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Success callback must be invoked
      expect(successCalled, isTrue);

      // Settle any pending toast timers
      await tester.pump(const Duration(seconds: 4));
    });
  });
}
