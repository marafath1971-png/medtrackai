import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/utils/logger.dart';

class PurchasesService {
  static String get _appleApiKey =>
      dotenv.env['RC_APPLE_KEY'] ?? 're_your_real_apple_key_here';
  static String get _googleApiKey =>
      dotenv.env['RC_GOOGLE_KEY'] ?? 're_your_real_google_key_here';


  static Future<void> init() async {
    await Purchases.setLogLevel(LogLevel.info);

    PurchasesConfiguration? configuration;
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(_googleApiKey);
    } else if (Platform.isIOS) {
      configuration = PurchasesConfiguration(_appleApiKey);
    }

    if (configuration != null) {
      await Purchases.configure(configuration);
    }
  }

  static Future<bool> isPremium() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all['premium']?.isActive ?? false;
    } catch (e) {
      appLogger.e('💰 RevenueCat Error', error: e);
      return false;
    }
  }
  static Future<List<Package>> getAvailablePackages() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.availablePackages ?? [];
    } catch (e) {
      appLogger.e('💰 RevenueCat Error fetching offerings', error: e);
      return [];
    }
  }

  static Future<bool> purchasePackage(String packageId) async {
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
