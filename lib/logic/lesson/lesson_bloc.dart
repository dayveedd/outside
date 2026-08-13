import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/user_activity.dart';
import '../../data/repositories/lesson_repository.dart';
import '../../data/repositories/user_repository.dart';
import 'lesson_event.dart';
import 'lesson_state.dart';

class LessonBloc extends Bloc<LessonEvent, LessonState> {
  final LessonRepository _lessonRepository;
  final UserRepository _userRepository;

  LessonBloc({
    required LessonRepository lessonRepository,
    required UserRepository userRepository,
  })  : _lessonRepository = lessonRepository,
        _userRepository = userRepository,
        super(LessonInitial()) {
    on<LoadDailyLesson>(_onLoadDailyLesson);
    on<LoadArchive>(_onLoadArchive);
    on<LoadSavedLessons>(_onLoadSavedLessons);
    on<CompleteLesson>(_onCompleteLesson);
    on<ToggleSaveLesson>(_onToggleSaveLesson);
  }

  Future<void> _onLoadDailyLesson(
    LoadDailyLesson event,
    Emitter<LessonState> emit,
  ) async {
    emit(LessonLoading());
    try {
      final lesson = event.lessonId != null
          ? await _lessonRepository.getLessonById(event.lessonId!)
          : await _lessonRepository.getDailyLesson(date: event.date);
      final activity = await _lessonRepository.getUserActivity(event.userId, lesson.id);
      emit(DailyLessonLoaded(lesson: lesson, activity: activity));
    } catch (e) {
      emit(LessonError(e.toString()));
    }
  }

  Future<void> _onLoadArchive(
    LoadArchive event,
    Emitter<LessonState> emit,
  ) async {
    emit(LessonLoading());
    try {
      final lessons = await _lessonRepository.getArchive();
      final activities = await _lessonRepository.getUserActivities(event.userId);
      emit(ArchiveLoaded(lessons: lessons, activities: activities));
    } catch (e) {
      emit(LessonError(e.toString()));
    }
  }

  Future<void> _onLoadSavedLessons(
    LoadSavedLessons event,
    Emitter<LessonState> emit,
  ) async {
    emit(LessonLoading());
    try {
      final lessons = await _lessonRepository.getSavedLessons(event.userId);
      emit(SavedLessonsLoaded(lessons));
    } catch (e) {
      emit(LessonError(e.toString()));
    }
  }

  Future<void> _onCompleteLesson(
    CompleteLesson event,
    Emitter<LessonState> emit,
  ) async {
    try {
      // 1. Get or create current activity
      final existingActivity = await _lessonRepository.getUserActivity(event.userId, event.lessonId);
      final updatedActivity = (existingActivity ?? UserActivity(userId: event.userId, lessonId: event.lessonId)).copyWith(
        isRead: true,
        reflectionNote: event.reflectionNote,
        completedAt: DateTime.now(),
      );

      // 2. Save user activity to Firestore
      await _lessonRepository.saveUserActivity(updatedActivity);

      // 3. Update the streak in Firestore
      await _userRepository.updateStreakAfterCompletion(event.userId);

      // 4. Update local BLoC state based on the current state type
      final currentState = state;
      if (currentState is DailyLessonLoaded && currentState.lesson.id == event.lessonId) {
        emit(DailyLessonLoaded(lesson: currentState.lesson, activity: updatedActivity));
      } else if (currentState is ArchiveLoaded) {
        final updatedActivities = Map<String, UserActivity>.from(currentState.activities);
        updatedActivities[event.lessonId] = updatedActivity;
        emit(ArchiveLoaded(lessons: currentState.lessons, activities: updatedActivities));
      }
    } catch (e) {
      emit(LessonError('Failed to complete lesson: ${e.toString()}'));
    }
  }

  Future<void> _onToggleSaveLesson(
    ToggleSaveLesson event,
    Emitter<LessonState> emit,
  ) async {
    try {
      // 1. Get or create current activity
      final existingActivity = await _lessonRepository.getUserActivity(event.userId, event.lessonId);
      final newSaveState = existingActivity != null ? !existingActivity.isSaved : true;
      final updatedActivity = (existingActivity ?? UserActivity(userId: event.userId, lessonId: event.lessonId)).copyWith(
        isSaved: newSaveState,
      );

      // 2. Save to Firestore
      await _lessonRepository.saveUserActivity(updatedActivity);

      // 3. Update local state
      final currentState = state;
      if (currentState is DailyLessonLoaded && currentState.lesson.id == event.lessonId) {
        emit(DailyLessonLoaded(lesson: currentState.lesson, activity: updatedActivity));
      } else if (currentState is ArchiveLoaded) {
        final updatedActivities = Map<String, UserActivity>.from(currentState.activities);
        updatedActivities[event.lessonId] = updatedActivity;
        emit(ArchiveLoaded(lessons: currentState.lessons, activities: updatedActivities));
      } else if (currentState is SavedLessonsLoaded) {
        // Refresh saved lessons list
        final lessons = await _lessonRepository.getSavedLessons(event.userId);
        emit(SavedLessonsLoaded(lessons));
      }
    } catch (e) {
      emit(LessonError('Failed to toggle bookmark: ${e.toString()}'));
    }
  }
}
