import 'package:equatable/equatable.dart';
import '../../data/models/user_streak.dart';

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

class StreakUpdated extends StreakEvent {
  final UserStreak streak;

  const StreakUpdated(this.streak);

  @override
  List<Object?> get props => [streak];
}
