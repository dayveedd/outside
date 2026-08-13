import 'dart:io';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../constants/constants.dart';

class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  bool _isMocked = false;
  bool _mockPremiumActive = false;

  bool get isMocked => _isMocked;

  Future<void> initialize() async {
    final apiKey = Platform.isIOS
        ? AppConstants.rcAppleApiKey
        : AppConstants.rcGoogleApiKey;

    if (apiKey.contains('PLACEHOLDER') || apiKey.isEmpty) {
      _isMocked = true;
      print('RevenueCat Service: API Key is a placeholder. Running in Mock Mode.');
      return;
    }

    try {
      await Purchases.setLogLevel(LogLevel.debug);
      PurchasesConfiguration configuration = PurchasesConfiguration(apiKey);
      await Purchases.configure(configuration);
      _isMocked = false;
    } catch (e) {
      print('RevenueCat Service Initialization Failed: $e. Falling back to Mock Mode.');
      _isMocked = true;
    }
  }

  Future<bool> checkEntitlementActive() async {
    if (_isMocked) {
      return _mockPremiumActive;
    }

    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[AppConstants.rcEntitlementId]?.isActive ?? false;
    } catch (e) {
      print('Error checking entitlement: $e');
      return false;
    }
  }

  Future<bool> purchasePackage(Package package) async {
    if (_isMocked) {
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate network lag
      _mockPremiumActive = true;
      return true;
    }

    try {
      final result = await Purchases.purchasePackage(package);
      final customerInfo = result.customerInfo;
      return customerInfo.entitlements.all[AppConstants.rcEntitlementId]?.isActive ?? false;
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        print('Purchase package error: $e');
      }
      rethrow;
    }
  }

  Future<bool> restorePurchases() async {
    if (_isMocked) {
      await Future.delayed(const Duration(milliseconds: 800));
      _mockPremiumActive = true;
      return true;
    }

    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all[AppConstants.rcEntitlementId]?.isActive ?? false;
    } catch (e) {
      print('Restore purchases error: $e');
      return false;
    }
  }

  // Returns list of mock offerings if in mock mode, otherwise fetches from RevenueCat
  Future<List<Package>> getAvailablePackages() async {
    if (_isMocked) {
      // Create mock packages
      return [
        Package(
          'monthly_premium',
          PackageType.monthly,
          StoreProduct(
            'outside_monthly_premium',
            'Outside Premium - Monthly',
            'Access all historical lessons & daily deep dives.',
            3.99,
            '\$3.99',
            'USD',
          ),
          const PresentedOfferingContext('default_offering', null, null),
        ),
        Package(
          'yearly_premium',
          PackageType.annual,
          StoreProduct(
            'outside_yearly_premium',
            'Outside Premium - Annual',
            'Access all historical lessons & daily deep dives.',
            29.99,
            '\$29.99',
            'USD',
          ),
          const PresentedOfferingContext('default_offering', null, null),
        ),
      ];
    }

    try {
      Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        return offerings.current!.availablePackages;
      }
      return [];
    } catch (e) {
      print('Error getting offerings: $e');
      return [];
    }
  }
}
