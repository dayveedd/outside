import 'dart:async';
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
      emit(SubscriptionStatus(isPremium: isPremium, packages: packages));
    } catch (e) {
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
      emit(SubscriptionError('Failed to purchase subscription: ${e.toString()}'));
      // Emit status again to return to paywall screen controls
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
      emit(SubscriptionError('Failed to restore purchases: ${e.toString()}'));
      add(CheckSubscriptionStatus());
    }
  }
}
