import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/services/revenuecat_service.dart';
import 'subscription_event.dart';
import 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final RevenueCatService _revenueCatService;

  SubscriptionBloc({required RevenueCatService revenueCatService})
      : _revenueCatService = revenueCatService,
        super(SubscriptionInitial()) {
    on<CheckSubscriptionStatus>(_onCheckSubscriptionStatus);
    on<PurchasePackageEvent>(_onPurchasePackage);
    on<RestorePurchasesEvent>(_onRestorePurchases);
  }

  Future<void> _onCheckSubscriptionStatus(
    CheckSubscriptionStatus event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    try {
      final isPremium = await _revenueCatService.checkEntitlementActive();
      final packages = await _revenueCatService.getAvailablePackages();
      debugPrint('[SubscriptionBloc] Status checked: isPremium=$isPremium, packagesCount=${packages.length}');
      emit(SubscriptionStatus(isPremium: isPremium, packages: packages));
    } catch (e) {
      debugPrint('[SubscriptionBloc] Error checking subscription status: $e');
      emit(SubscriptionError('Failed to load subscription status: ${e.toString()}'));
    }
  }

  Future<void> _onPurchasePackage(
    PurchasePackageEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    try {
      final isPremium = await _revenueCatService.purchasePackage(event.package);
      final packages = await _revenueCatService.getAvailablePackages();
      emit(SubscriptionStatus(isPremium: isPremium, packages: packages));
    } catch (e) {
      debugPrint('[SubscriptionBloc] Error purchasing package: $e');
      emit(SubscriptionError('Failed to purchase subscription: ${e.toString()}'));
      add(CheckSubscriptionStatus());
    }
  }

  Future<void> _onRestorePurchases(
    RestorePurchasesEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    try {
      final isPremium = await _revenueCatService.restorePurchases();
      final packages = await _revenueCatService.getAvailablePackages();
      emit(SubscriptionStatus(isPremium: isPremium, packages: packages));
    } catch (e) {
      debugPrint('[SubscriptionBloc] Error restoring purchases: $e');
      emit(SubscriptionError('Failed to restore purchases: ${e.toString()}'));
      add(CheckSubscriptionStatus());
    }
  }
}
