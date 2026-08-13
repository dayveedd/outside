import 'package:equatable/equatable.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

abstract class SubscriptionState extends Equatable {
  const SubscriptionState();

  @override
  List<Object?> get props => [];
}

class SubscriptionInitial extends SubscriptionState {}

class SubscriptionLoading extends SubscriptionState {}

class SubscriptionStatus extends SubscriptionState {
  final bool isPremium;
  final List<Package> packages;

  const SubscriptionStatus({
    required this.isPremium,
    required this.packages,
  });

  @override
  List<Object?> get props => [isPremium, packages];
}

class SubscriptionError extends SubscriptionState {
  final String message;

  const SubscriptionError(this.message);

  @override
  List<Object?> get props => [message];
}
