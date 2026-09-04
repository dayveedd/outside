import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  Future<void> initialize() async {}

  Future<bool> checkEntitlementActive() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        return data?['isPremium'] == true;
      }
    } catch (e) {
      // Handled silently
    }
    return false;
  }

  Future<bool> purchasePackage(Package package) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isPremium': true,
      });
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> restorePurchases() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isPremium': true,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Package>> getAvailablePackages() async {
    return [
      Package(
        'lifetime_premium',
        PackageType.lifetime,
        StoreProduct(
          'outside_lifetime_premium',
          'Outside Premium - Lifetime Pass',
          'Access all historical lessons & daily deep dives.',
          1.99,
          '\$1.99',
          'USD',
        ),
        const PresentedOfferingContext('default_offering', null, null),
      ),
    ];
  }
}
