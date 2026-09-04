import 'package:equatable/equatable.dart';
import '../../data/models/lesson.dart';

abstract class LessonEvent extends Equatable {
  const LessonEvent();

  @override
  List<Object?> get props => [];
}

class LoadDailyLesson extends LessonEvent {
  final String userId;
  final DateTime? date;
  final String? lessonId;

  const LoadDailyLesson(this.userId, {this.date, this.lessonId});

  @override
  List<Object?> get props => [userId, date, lessonId];
}

class LoadArchive extends LessonEvent {
  final String userId;

  const LoadArchive(this.userId);

  @override
  List<Object?> get props => [userId];
}

class LoadSavedLessons extends LessonEvent {
  final String userId;

  const LoadSavedLessons(this.userId);

  @override
  List<Object?> get props => [userId];
}

class CompleteLesson extends LessonEvent {
  final String userId;
  final String lessonId;
  final String reflectionNote;

  const CompleteLesson({
    required this.userId,
    required this.lessonId,
    required this.reflectionNote,
  });

  @override
  List<Object?> get props => [userId, lessonId, reflectionNote];
}

class ToggleSaveLesson extends LessonEvent {
  final String userId;
  final String lessonId;

  const ToggleSaveLesson({
    required this.userId,
    required this.lessonId,
  });

  @override
  List<Object?> get props => [userId, lessonId];
}

class SwitchPerspective extends LessonEvent {
  final Lesson lesson;

  const SwitchPerspective(this.lesson);

  @override
  List<Object?> get props => [lesson];
}
