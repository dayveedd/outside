import 'package:equatable/equatable.dart';

abstract class StreakEvent extends Equatable {
  const StreakEvent();

  @override
  List<Object?> get props => [];
}

class LoadStreak extends StreakEvent {
  final String userId;

  const LoadStreak(this.userId);

  @override
  List<Object?> get props => [userId];
}
