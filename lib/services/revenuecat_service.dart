import 'dart:io';

import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatResult {
  final bool success;
  final bool isPro;
  final String message;

  const RevenueCatResult({
    required this.success,
    required this.isPro,
    required this.message,
  });
}

class RevenueCatService {
  static const entitlementId = String.fromEnvironment(
    'REVENUECAT_ENTITLEMENT_ID',
    defaultValue: 'pro',
  );
  static const iosApiKey = String.fromEnvironment('REVENUECAT_IOS_API_KEY');
  static const androidApiKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
  );
  static const monthlyProductId = 'bridgecall_pro_monthly';
  static const yearlyProductId = 'bridgecall_pro_yearly';

  static bool _configured = false;
  static String? _lastError;

  static bool get isConfigured => _configured;
  static String? get lastError => _lastError;

  static Future<RevenueCatResult> configure() async {
    if (_configured) {
      return const RevenueCatResult(
        success: true,
        isPro: false,
        message: 'RevenueCat hazır',
      );
    }

    final apiKey = _apiKeyForPlatform();
    if (apiKey.isEmpty) {
      _lastError =
          'RevenueCat API key eksik. --dart-define ile REVENUECAT_IOS_API_KEY / REVENUECAT_ANDROID_API_KEY verilmeli.';
      return RevenueCatResult(
        success: false,
        isPro: false,
        message: _lastError!,
      );
    }

    try {
      await Purchases.setLogLevel(LogLevel.warn);
      await Purchases.configure(PurchasesConfiguration(apiKey));
      _configured = true;
      _lastError = null;
      final customerInfo = await Purchases.getCustomerInfo();
      return RevenueCatResult(
        success: true,
        isPro: _hasEntitlement(customerInfo),
        message: 'RevenueCat bağlandı',
      );
    } catch (e) {
      _lastError = 'RevenueCat başlatılamadı: $e';
      return RevenueCatResult(
        success: false,
        isPro: false,
        message: _lastError!,
      );
    }
  }

  static Future<bool> hasProEntitlement() async {
    final configured = await configure();
    if (!configured.success) return false;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return _hasEntitlement(customerInfo);
    } catch (e) {
      _lastError = 'Abonelik durumu okunamadı: $e';
      return false;
    }
  }

  static Future<List<Package>> availablePackages() async {
    final configured = await configure();
    if (!configured.success) return const <Package>[];
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.availablePackages ?? const <Package>[];
    } catch (e) {
      _lastError = 'Ürünler yüklenemedi: $e';
      return const <Package>[];
    }
  }

  static Future<RevenueCatResult> purchase(Package package) async {
    final configured = await configure();
    if (!configured.success) return configured;
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      final isPro = _hasEntitlement(result.customerInfo);
      return RevenueCatResult(
        success: isPro,
        isPro: isPro,
        message: isPro
            ? 'Pro aktif edildi'
            : 'Satın alma tamamlandı ama Pro yetkisi bulunamadı',
      );
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      final cancelled = errorCode == PurchasesErrorCode.purchaseCancelledError;
      return RevenueCatResult(
        success: false,
        isPro: false,
        message: cancelled
            ? 'Satın alma iptal edildi'
            : 'Satın alma başarısız: ${e.message ?? e.code}',
      );
    } catch (e) {
      return RevenueCatResult(
        success: false,
        isPro: false,
        message: 'Satın alma başarısız: $e',
      );
    }
  }

  static Future<RevenueCatResult> restore() async {
    final configured = await configure();
    if (!configured.success) return configured;
    try {
      final customerInfo = await Purchases.restorePurchases();
      final isPro = _hasEntitlement(customerInfo);
      return RevenueCatResult(
        success: isPro,
        isPro: isPro,
        message: isPro
            ? 'Abonelik geri yüklendi'
            : 'Aktif Pro abonelik bulunamadı',
      );
    } catch (e) {
      return RevenueCatResult(
        success: false,
        isPro: false,
        message: 'Geri yükleme başarısız: $e',
      );
    }
  }

  static Future<RevenueCatResult> subscriptionStatus() async {
    final configured = await configure();
    if (!configured.success) return configured;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final isPro = _hasEntitlement(customerInfo);
      return RevenueCatResult(
        success: true,
        isPro: isPro,
        message: isPro ? 'Pro aktif' : 'Pro aktif değil',
      );
    } catch (e) {
      return RevenueCatResult(
        success: false,
        isPro: false,
        message: 'Abonelik kontrol edilemedi: $e',
      );
    }
  }

  static bool _hasEntitlement(CustomerInfo customerInfo) {
    return customerInfo.entitlements.active.containsKey(entitlementId);
  }

  static String _apiKeyForPlatform() {
    if (Platform.isIOS || Platform.isMacOS) return iosApiKey;
    if (Platform.isAndroid) return androidApiKey;
    return '';
  }
}
