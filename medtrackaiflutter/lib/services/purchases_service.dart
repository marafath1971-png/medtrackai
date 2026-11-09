import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/utils/logger.dart';

class PurchasesService {
  static bool _configured = false;

  /// Compile-time keys, supplied by CI as
  /// `--dart-define=RC_GOOGLE_KEY=goog_...`.
  ///
  /// These win over .env because .env is gitignored and therefore absent on a
  /// build machine; a release built from a clean checkout would otherwise pick
  /// up no key at all and ship with billing silently off.
  static const String _defineApple = String.fromEnvironment('RC_APPLE_KEY');
  static const String _defineGoogle = String.fromEnvironment('RC_GOOGLE_KEY');

  static String get _appleApiKey {
    if (_defineApple.isNotEmpty) return _defineApple.trim();
    if (!dotenv.isInitialized) return '';
    return (dotenv.env['RC_APPLE_KEY'] ?? dotenv.env['PURCHASES_API_KEY'] ?? '')
        .trim();
  }

  static String get _googleApiKey {
    if (_defineGoogle.isNotEmpty) return _defineGoogle.trim();
    if (!dotenv.isInitialized) return '';
    return (dotenv.env['RC_GOOGLE_KEY'] ??
            dotenv.env['PURCHASES_API_KEY'] ??
            '')
        .trim();
  }

  /// Whether this binary can actually sell anything.
  ///
  /// Separate from [isMisconfigured], which is only meaningful after [init]
  /// has run. This is answerable before startup and is what the release guard
  /// asserts on.
  static bool get hasSellableKey =>
      _isValidKey(Platform.isAndroid ? _googleApiKey : _appleApiKey);

  static bool _isValidKey(String key) {
    final cleaned = key.trim();
    if (cleaned.isEmpty) return false;

    final lower = cleaned.toLowerCase();
    // Check for common placeholders
    if (lower.contains('placeholder') ||
        lower.contains('your_real') ||
        lower.contains('your_key') ||
        lower.contains('dummy') ||
        lower.contains('demo') ||
        lower == 'goog_' ||
        lower == 'appl_' ||
        lower == 'public_') {
      return false;
    }

    // RevenueCat public API keys typically start with goog_, appl_, or public_ and are at least 25 characters long.
    if (cleaned.startsWith('goog_') ||
        cleaned.startsWith('appl_') ||
        cleaned.startsWith('public_')) {
      return cleaned.length > 25;
    }

    return false;
  }

  /// True when billing is unusable because no real key was supplied.
  ///
  /// Distinct from a transient offerings failure: no amount of retrying fixes
  /// a placeholder key, and the paywall should not tell the user to try again
  /// when the build itself cannot sell anything.
  static bool get isMisconfigured => _misconfigured;
  static bool _misconfigured = false;

  static Future<void> init() async {
    final key = Platform.isAndroid ? _googleApiKey : _appleApiKey;
    // Never log the key itself — it is a secret once a real one is in place,
    // and logcat is readable by anyone with the device plugged in.
    appLogger.i('💰 RevenueCat: API key ${key.isEmpty ? "absent" : "present"} '
        '(${key.length} chars)');

    if (!_isValidKey(key)) {
      // Deliberately does not echo the configured value. Naming the known
      // placeholder here was fine while that is what ships, but the same line
      // would print a hint about a real key once one is set.
      appLogger.w('💰 RevenueCat: no valid API key — billing disabled. '
          'Set PURCHASES_API_KEY (or RC_GOOGLE_KEY/RC_APPLE_KEY) in .env to a '
          'real goog_/appl_ key from the RevenueCat dashboard; until then '
          'nothing can be sold.');
      _configured = false;
      _misconfigured = true;
      return;
    }
    _misconfigured = false;

    try {
      appLogger.i(
          '💰 RevenueCat: Valid API key detected. Configuring Purchases SDK...');
      await Purchases.setLogLevel(LogLevel.info);
      final configuration = PurchasesConfiguration(key);
      await Purchases.configure(configuration);
      _configured = true;
      appLogger.i('💰 RevenueCat: Purchases SDK configured successfully.');
    } catch (e) {
      appLogger.e('💰 RevenueCat Configuration Error', error: e);
      _configured = false;
    }
  }

  /// Checks whether any premium entitlement is active (supports 'premium',
  /// 'MedAI Pro', 'medai_pro', and 'pro' identifiers configured in RevenueCat).
  static bool _hasPremiumEntitlement(CustomerInfo customerInfo) {
    final all = customerInfo.entitlements.all;
    return (all['premium']?.isActive ?? false) ||
        (all['MedAI Pro']?.isActive ?? false) ||
        (all['medai_pro']?.isActive ?? false) ||
        (all['pro']?.isActive ?? false);
  }

  static Future<bool> isPremium() async {
    if (!_configured) return false;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return _hasPremiumEntitlement(customerInfo);
    } catch (e) {
      appLogger.e('💰 RevenueCat Error', error: e);
      return false;
    }
  }

  /// Whether the Family plan is active. In RevenueCat the Family product
  /// grants both `premium` and `family`, so everything gated on [isPremium]
  /// keeps working and this only adds the circle-wide benefit.
  static Future<bool> hasFamilyPlan() async {
    if (!_configured) return false;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all['family']?.isActive ?? false;
    } catch (e) {
      appLogger.e('💰 RevenueCat Error', error: e);
      return false;
    }
  }

  static Future<List<Package>> getAvailablePackages() async {
    if (!_configured) return [];
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.availablePackages ?? [];
    } catch (e) {
      appLogger.e('💰 RevenueCat Error fetching offerings', error: e);
      return [];
    }
  }

  /// Direct purchase using an already resolved [Package].
  ///
  /// Skips re-fetching offerings over the network, avoiding extra latency and
  /// network-drop risks right when the user taps to buy.
  static Future<bool> purchase(Package package) async {
    if (!_configured) {
      appLogger.w('💰 RevenueCat: Cannot purchase. Billing is not configured.');
      return false;
    }
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      return _hasPremiumEntitlement(result.customerInfo);
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        appLogger.e('💰 RevenueCat Purchase Error', error: e);
      }
      return false;
    }
  }

  /// Purchase by package identifier or shorthand ('annual', 'monthly', etc.).
  static Future<bool> purchasePackage(String packageId) async {
    if (!_configured) {
      appLogger.w('💰 RevenueCat: Cannot purchase. Billing is not configured.');
      return false;
    }
    try {
      final offerings = await Purchases.getOfferings();
      final currentOffering = offerings.current;
      if (currentOffering == null) {
        appLogger.w('💰 RevenueCat: No current offering available.');
        return false;
      }

      // Try exact package identifier match first
      Package? package = currentOffering.getPackage(packageId);

      // Fallback: match by common shorthand or standard package type
      if (package == null) {
        final lower = packageId.toLowerCase().trim();
        if (lower == 'annual' || lower == r'$rc_annual') {
          package = currentOffering.annual;
        } else if (lower == 'monthly' || lower == r'$rc_monthly') {
          package = currentOffering.monthly;
        } else if (lower == 'weekly' || lower == r'$rc_weekly') {
          package = currentOffering.weekly;
        } else if (lower == 'lifetime' || lower == r'$rc_lifetime') {
          package = currentOffering.lifetime;
        } else if (lower.contains('family')) {
          package = currentOffering.availablePackages.cast<Package?>().firstWhere(
                (p) => p != null && p.identifier.toLowerCase().contains('family'),
                orElse: () => null,
              );
        }
      }

      if (package != null) {
        return await purchase(package);
      }
      appLogger.w('💰 RevenueCat: Package "$packageId" not found in current offering.');
      return false;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        appLogger.e('💰 RevenueCat Purchase Error', error: e);
      }
      return false;
    }
  }

  /// Syncs the user identifier with RevenueCat upon sign in.
  static Future<void> logIn(String appUserId) async {
    if (!_configured || appUserId.trim().isEmpty) return;
    try {
      await Purchases.logIn(appUserId);
      appLogger.i('💰 RevenueCat: User successfully identified.');
    } catch (e) {
      appLogger.e('💰 RevenueCat LogIn Error', error: e);
    }
  }

  /// Resets back to an anonymous RevenueCat user upon sign out.
  static Future<void> logOut() async {
    if (!_configured) return;
    try {
      await Purchases.logOut();
      appLogger.i('💰 RevenueCat: Reset to anonymous user.');
    } catch (e) {
      appLogger.e('💰 RevenueCat LogOut Error', error: e);
    }
  }

  /// Listens to real-time subscription status changes (renewals, cancellations, upgrades).
  static void addCustomerInfoUpdateListener(
      void Function(CustomerInfo customerInfo) listener) {
    if (!_configured) return;
    Purchases.addCustomerInfoUpdateListener(listener);
  }

  static Future<bool> restorePurchases() async {
    if (!_configured) return false;
    try {
      final customerInfo = await Purchases.restorePurchases();
      return _hasPremiumEntitlement(customerInfo);
    } catch (e) {
      appLogger.e('💰 RevenueCat Restore Error', error: e);
      return false;
    }
  }

  static Future<bool> manageSubscriptions() async {
    try {
      final String urlString;
      if (Platform.isIOS || Platform.isMacOS) {
        urlString = 'https://apps.apple.com/account/subscriptions';
      } else {
        urlString = 'https://play.google.com/store/account/subscriptions';
      }

      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      appLogger.e('💰 Error opening store subscription management: $e');
      return false;
    }
  }
}
