class RevenueCatService {
  static const entitlementPro = 'pro';
  static const monthlyProductId = 'bridgecall_pro_monthly';
  static const yearlyProductId = 'bridgecall_pro_yearly';

  static Future<void> configure() async {
    // purchases_flutter is intentionally not initialized until App Store
    // products and RevenueCat public keys are ready.
  }

  static Future<bool> hasProEntitlement() async {
    return false;
  }
}
