import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/user_repository.dart';
import 'streak_event.dart';
import 'streak_state.dart';

class StreakBloc extends Bloc<StreakEvent, StreakState> {
  final UserRepository _userRepository;

  StreakBloc({required UserRepository userRepository})
      : _userRepository = userRepository,
        super(StreakInitial()) {
    on<LoadStreak>(_onLoadStreak);
    on<StreakUpdated>(_onStreakUpdated);
  }

  Future<void> _onLoadStreak(
    LoadStreak event,
    Emitter<StreakState> emit,
  ) async {
    if (state is! StreakLoaded) {
      emit(StreakLoading());
    }
    try {
      final streak = await _userRepository.getUserStreak(event.userId);
      emit(StreakLoaded(streak));
    } catch (e) {
      emit(StreakError('Failed to load streak: ${e.toString()}'));
    }
  }

  void _onStreakUpdated(
    StreakUpdated event,
    Emitter<StreakState> emit,
  ) {
    emit(StreakLoaded(event.streak));
  }
}
