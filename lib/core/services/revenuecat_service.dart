import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../constants/constants.dart';

class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  bool _isConfigured = false;

  Future<void> initialize() async {
    if (_isConfigured) return;
    try {
      if (kIsWeb) {
        debugPrint('[RevenueCat] Web platform detected. Skipping RevenueCat native configuration.');
        return;
      }
      if (Platform.isIOS || Platform.isMacOS) {
        debugPrint('[RevenueCat] Initializing RevenueCat with Apple API key: ${AppConstants.rcAppleApiKey}');
        await Purchases.setLogLevel(LogLevel.debug);
        await Purchases.configure(PurchasesConfiguration(AppConstants.rcAppleApiKey));
        _isConfigured = true;
        debugPrint('[RevenueCat] Configured successfully.');
      } else if (Platform.isAndroid) {
        debugPrint('[RevenueCat] Android platform detected. rcAppleApiKey provided. Android requires a Google Play API key from RevenueCat.');
      }
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && uid.isNotEmpty) {
        debugPrint('[RevenueCat] Identifying user: $uid');
        await Purchases.logIn(uid);
      }
    } catch (e, st) {
      debugPrint('[RevenueCat] Initialization ERROR: $e\n$st');
      if (e is PlatformException) {
        debugPrint('[RevenueCat] PlatformException code: ${e.code}, message: ${e.message}, details: ${e.details}');
      }
    }
  }

  Future<bool> checkEntitlementActive() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    try {
      if (!_isConfigured) {
        await initialize();
      }
      final customerInfo = await Purchases.getCustomerInfo();
      debugPrint('[RevenueCat] Active entitlements: ${customerInfo.entitlements.active.keys.toList()}');
      debugPrint('[RevenueCat] Active subscriptions: ${customerInfo.activeSubscriptions}');

      final hasActive = customerInfo.entitlements.active.isNotEmpty ||
          customerInfo.activeSubscriptions.isNotEmpty ||
          (customerInfo.entitlements.all[AppConstants.rcEntitlementId]?.isActive ?? false);
      if (hasActive) {
        if (uid != null) {
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'isPremium': true,
          });
        }
        return true;
      }
    } catch (e) {
      debugPrint('[RevenueCat] checkEntitlementActive error: $e');
    }

    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists) {
          final data = doc.data();
          return data?['isPremium'] == true;
        }
      } catch (e) {
        debugPrint('[RevenueCat] Firestore fallback check error: $e');
        return false;
      }
    }
    return false;
  }

  Future<bool> purchasePackage(Package package) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    try {
      if (!_isConfigured) {
        await initialize();
      }
      if (uid != null) {
        await Purchases.logIn(uid);
      }
      debugPrint('[RevenueCat] Initiating purchase for package: ${package.identifier} (${package.storeProduct.identifier})');
      final purchaseResult = await Purchases.purchase(PurchaseParams.package(package));
      final customerInfo = purchaseResult.customerInfo;
      debugPrint('[RevenueCat] Purchase completed. Active entitlements: ${customerInfo.entitlements.active.keys.toList()}');

      final hasActive = customerInfo.entitlements.active.isNotEmpty ||
          customerInfo.activeSubscriptions.isNotEmpty ||
          (customerInfo.entitlements.all[AppConstants.rcEntitlementId]?.isActive ?? false);
      if (hasActive && uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'isPremium': true,
        });
      }
      return hasActive;
    } catch (e) {
      debugPrint('[RevenueCat] purchasePackage ERROR: $e');
      if (e is PlatformException) {
        debugPrint('[RevenueCat] PlatformException code: ${e.code}, message: ${e.message}, details: ${e.details}');
      }
      rethrow;
    }
  }

  Future<bool> restorePurchases() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    try {
      if (!_isConfigured) {
        await initialize();
      }
      if (uid != null) {
        await Purchases.logIn(uid);
      }
      debugPrint('[RevenueCat] Restoring purchases...');
      final customerInfo = await Purchases.restorePurchases();
      debugPrint('[RevenueCat] Restore completed. Active entitlements: ${customerInfo.entitlements.active.keys.toList()}');

      final hasActive = customerInfo.entitlements.active.isNotEmpty ||
          customerInfo.activeSubscriptions.isNotEmpty ||
          (customerInfo.entitlements.all[AppConstants.rcEntitlementId]?.isActive ?? false);
      if (hasActive && uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'isPremium': true,
        });
        return true;
      }
      return hasActive;
    } catch (e) {
      debugPrint('[RevenueCat] restorePurchases ERROR: $e');
      if (e is PlatformException) {
        debugPrint('[RevenueCat] PlatformException code: ${e.code}, message: ${e.message}, details: ${e.details}');
      }
      return false;
    }
  }

  Future<List<Package>> getAvailablePackages() async {
    try {
      if (!_isConfigured) {
        await initialize();
      }
      debugPrint('[RevenueCat] Fetching offerings from RevenueCat...');
      final offerings = await Purchases.getOfferings();
      debugPrint('[RevenueCat] Offerings retrieved.');
      debugPrint('[RevenueCat] Current offering: ${offerings.current?.identifier}');
      debugPrint('[RevenueCat] All offerings keys: ${offerings.all.keys.toList()}');

      if (offerings.current != null) {
        final currentPackages = offerings.current!.availablePackages;
        debugPrint('[RevenueCat] Current offering "${offerings.current!.identifier}" has ${currentPackages.length} package(s):');
        for (final pkg in currentPackages) {
          debugPrint('[RevenueCat]   - ${pkg.identifier}: ${pkg.storeProduct.identifier} | ${pkg.storeProduct.priceString} | ${pkg.storeProduct.title}');
        }
        if (currentPackages.isNotEmpty) {
          return currentPackages;
        }
      }

      for (final entry in offerings.all.entries) {
        final offering = entry.value;
        debugPrint('[RevenueCat] Checking offering "${offering.identifier}" with ${offering.availablePackages.length} package(s)');
        if (offering.availablePackages.isNotEmpty) {
          for (final pkg in offering.availablePackages) {
            debugPrint('[RevenueCat]   - ${pkg.identifier}: ${pkg.storeProduct.identifier} | ${pkg.storeProduct.priceString} | ${pkg.storeProduct.title}');
          }
          return offering.availablePackages;
        }
      }

      debugPrint('[RevenueCat] WARNING: No available packages found in any offering. Possible reasons:');
      debugPrint('[RevenueCat] 1. Offerings exist in RevenueCat dashboard but none are marked as "Default".');
      debugPrint('[RevenueCat] 2. Packages inside your offering have no StoreKit/App Store Connect product attached.');
      debugPrint('[RevenueCat] 3. StoreKit hasn\'t synced products with App Store Connect yet.');
      debugPrint('[RevenueCat] 4. Paid Applications agreement has not been signed in App Store Connect.');
      return [];
    } catch (e, st) {
      debugPrint('[RevenueCat] getAvailablePackages ERROR: $e\n$st');
      if (e is PlatformException) {
        debugPrint('[RevenueCat] PlatformException code: ${e.code}, message: ${e.message}, details: ${e.details}');
      }
      rethrow;
    }
  }
}
