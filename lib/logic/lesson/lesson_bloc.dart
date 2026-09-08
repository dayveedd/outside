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
    on<SwitchPerspective>(_onSwitchPerspective);
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
      final pool = await _lessonRepository.getDailyLessonPool(date: event.date);
      final lesson = event.lessonId != null
          ? await _lessonRepository.getLessonById(event.lessonId!)
          : await _lessonRepository.getDailyLesson(userId: event.userId, date: event.date);

      if (lesson == null) {
        final targetDateStr = LessonRepository.formatDate(event.date ?? DateTime.now());
        emit(DailyLessonEmpty(targetDate: targetDateStr));
        return;
      }

      for (final p in pool) {
        await _lessonRepository.getUserActivity(event.userId, p.id);
      }
      final activity = _lessonRepository.getCachedUserActivity(lesson.id, userId: event.userId);
      emit(DailyLessonLoaded(
        lesson: lesson,
        activity: activity,
        pool: pool,
        defaultLessonId: lesson.id,
      ));
    } catch (e) {
      emit(LessonError(e.toString()));
    }
  }

  void _onSwitchPerspective(
    SwitchPerspective event,
    Emitter<LessonState> emit,
  ) {
    final currentState = state;
    if (currentState is DailyLessonLoaded) {
      final activity = _lessonRepository.getCachedUserActivity(event.lesson.id);
      emit(DailyLessonLoaded(
        lesson: event.lesson,
        activity: activity,
        pool: currentState.pool,
        defaultLessonId: currentState.defaultLessonId ?? currentState.lesson.id,
      ));
    }
  }

  Future<void> _onLoadArchive(
    LoadArchive event,
    Emitter<LessonState> emit,
  ) async {
    if (!_lessonRepository.hasCachedArchive(event.userId) && state is! ArchiveLoaded) {
      emit(LessonLoading());
    }
    try {
      final lessons = await _lessonRepository.getArchive(userId: event.userId);
      final activities = await _lessonRepository.getUserActivities(event.userId);
      emit(ArchiveLoaded(lessons: lessons, activities: activities));
    } catch (e) {
      if (state is! ArchiveLoaded) {
        emit(LessonError(e.toString()));
      }
    }
  }

  Future<void> _onLoadSavedLessons(
    LoadSavedLessons event,
    Emitter<LessonState> emit,
  ) async {
    if (!_lessonRepository.hasCachedSaved(event.userId) && state is! SavedLessonsLoaded) {
      emit(LessonLoading());
    }
    try {
      final lessons = await _lessonRepository.getSavedLessons(event.userId);
      emit(SavedLessonsLoaded(lessons));
    } catch (e) {
      if (state is! SavedLessonsLoaded) {
        emit(LessonError(e.toString()));
      }
    }
  }

  Future<void> _onCompleteLesson(
    CompleteLesson event,
    Emitter<LessonState> emit,
  ) async {
    try {
      final existingActivity = await _lessonRepository.getUserActivity(event.userId, event.lessonId);
      final updatedActivity = (existingActivity ?? UserActivity(userId: event.userId, lessonId: event.lessonId)).copyWith(
        isRead: true,
        reflectionNote: event.reflectionNote,
        completedAt: DateTime.now(),
      );

      await _lessonRepository.saveUserActivity(updatedActivity);
      await _userRepository.updateStreakAfterCompletion(event.userId);

      final currentState = state;
      if (currentState is DailyLessonLoaded && currentState.lesson.id == event.lessonId) {
        emit(DailyLessonLoaded(
          lesson: currentState.lesson,
          activity: updatedActivity,
          pool: currentState.pool,
          defaultLessonId: currentState.defaultLessonId,
        ));
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
      final existingActivity = await _lessonRepository.getUserActivity(event.userId, event.lessonId);
      final newSaveState = existingActivity != null ? !existingActivity.isSaved : true;
      final updatedActivity = (existingActivity ?? UserActivity(userId: event.userId, lessonId: event.lessonId)).copyWith(
        isSaved: newSaveState,
      );

      await _lessonRepository.saveUserActivity(updatedActivity);

      final currentState = state;
      if (currentState is DailyLessonLoaded && currentState.lesson.id == event.lessonId) {
        emit(DailyLessonLoaded(
          lesson: currentState.lesson,
          activity: updatedActivity,
          pool: currentState.pool,
          defaultLessonId: currentState.defaultLessonId,
        ));
      } else if (currentState is ArchiveLoaded) {
        final updatedActivities = Map<String, UserActivity>.from(currentState.activities);
        updatedActivities[event.lessonId] = updatedActivity;
        emit(ArchiveLoaded(lessons: currentState.lessons, activities: updatedActivities));
      } else if (currentState is SavedLessonsLoaded) {
        final lessons = await _lessonRepository.getSavedLessons(event.userId, forceRefresh: true);
        emit(SavedLessonsLoaded(lessons));
      }
    } catch (e) {
      emit(LessonError('Failed to toggle bookmark: ${e.toString()}'));
    }
  }
}
