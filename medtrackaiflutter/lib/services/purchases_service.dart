import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/utils/logger.dart';

class PurchasesService {
  static bool _configured = false;

  static String get _appleApiKey {
    if (!dotenv.isInitialized) return '';
    return (dotenv.env['RC_APPLE_KEY'] ?? dotenv.env['PURCHASES_API_KEY'] ?? '').trim();
  }

  static String get _googleApiKey {
    if (!dotenv.isInitialized) return '';
    return (dotenv.env['RC_GOOGLE_KEY'] ?? dotenv.env['PURCHASES_API_KEY'] ?? '').trim();
  }

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
    if (cleaned.startsWith('goog_') || cleaned.startsWith('appl_') || cleaned.startsWith('public_')) {
      return cleaned.length > 25;
    }
    
    return false;
  }

  static Future<void> init() async {
    final key = Platform.isAndroid ? _googleApiKey : _appleApiKey;
    appLogger.i('💰 RevenueCat: Resolved API Key is "$key"');
    
    if (!_isValidKey(key)) {
      appLogger.w('💰 RevenueCat: No valid API key configured. Billing features will run in mock/bypass mode.');
      _configured = false;
      return;
    }

    try {
      appLogger.i('💰 RevenueCat: Valid API key detected. Configuring Purchases SDK...');
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

  static Future<bool> isPremium() async {
    if (!_configured) return false;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all['premium']?.isActive ?? false;
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

  static Future<bool> purchasePackage(String packageId) async {
    if (!_configured) {
      appLogger.w('💰 RevenueCat: Cannot purchase. Billing is not configured.');
      return false;
    }
    try {
      final offerings = await Purchases.getOfferings();
      final package = offerings.current?.getPackage(packageId);

      if (package != null) {
        final result = await Purchases.purchase(PurchaseParams.package(package));
        return result.customerInfo.entitlements.all['premium']?.isActive ?? false;
      }
      return false;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        appLogger.e('💰 RevenueCat Purchase Error', error: e);
      }
      return false;
    }
  }

  static Future<bool> restorePurchases() async {
    if (!_configured) return false;
    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all['premium']?.isActive ?? false;
    } catch (e) {
      appLogger.e('💰 RevenueCat Restore Error', error: e);
      return false;
    }
  }

  static Future<void> manageSubscriptions() async {
    appLogger.i(
        '💰 RevenueCat: Please manage subscriptions in App Store / Play Store settings.');
  }
}
