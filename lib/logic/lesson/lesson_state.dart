import 'package:equatable/equatable.dart';
import '../../data/models/lesson.dart';
import '../../data/models/user_activity.dart';

abstract class LessonState extends Equatable {
  const LessonState();

  @override
  List<Object?> get props => [];
}

class LessonInitial extends LessonState {}

class LessonLoading extends LessonState {}

class DailyLessonLoaded extends LessonState {
  final Lesson lesson;
  final UserActivity? activity;

  const DailyLessonLoaded({required this.lesson, this.activity});

  @override
  List<Object?> get props => [lesson, activity];
}

class ArchiveLoaded extends LessonState {
  final List<Lesson> lessons;
  final Map<String, UserActivity> activities;

  const ArchiveLoaded({required this.lessons, required this.activities});

  @override
  List<Object?> get props => [lessons, activities];
}

class SavedLessonsLoaded extends LessonState {
  final List<Lesson> lessons;

  const SavedLessonsLoaded(this.lessons);

  @override
  List<Object?> get props => [lessons];
}

class LessonError extends LessonState {
  final String message;

  const LessonError(this.message);

  @override
  List<Object?> get props => [message];
}
