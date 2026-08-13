import 'package:flutter_test/flutter_test.dart';
import 'package:outside/data/models/lesson.dart';
import 'package:outside/data/models/user_activity.dart';
import 'package:outside/data/models/user_streak.dart';

void main() {
  group('Lesson Model Tests', () {
    test('should parse Lesson from JSON correctly', () {
      final json = {
        'id': 'test_lesson',
        'publishDate': '2026-08-11',
        'category': 'Philosophy',
        'hook': 'Is this real?',
        'idea': 'Simulated reality concept.',
        'whyItMatters': 'Changes how we perceive existence.',
        'everydayExample': 'VR gaming.',
        'reflectionPrompt': 'Are you awake?',
        'exploreMore': ['Link 1', 'Link 2'],
        'readTimeMinutes': 5,
      };

      final lesson = Lesson.fromJson(json);

      expect(lesson.id, 'test_lesson');
      expect(lesson.publishDate, '2026-08-11');
      expect(lesson.category, 'Philosophy');
      expect(lesson.hook, 'Is this real?');
      expect(lesson.idea, 'Simulated reality concept.');
      expect(lesson.whyItMatters, 'Changes how we perceive existence.');
      expect(lesson.everydayExample, 'VR gaming.');
      expect(lesson.reflectionPrompt, 'Are you awake?');
      expect(lesson.exploreMore, ['Link 1', 'Link 2']);
      expect(lesson.readTimeMinutes, 5);
      expect(lesson.publishDateTime, DateTime(2026, 8, 11));
    });
  });

  group('UserActivity Model Tests', () {
    test('should parse UserActivity from JSON correctly', () {
      final json = {
        'userId': 'user_123',
        'lessonId': 'lesson_abc',
        'isRead': true,
        'isSaved': false,
        'reflectionNote': 'Very interesting!',
        'completedAt': null,
      };

      final activity = UserActivity.fromJson(json, userId: 'user_123', lessonId: 'lesson_abc');

      expect(activity.userId, 'user_123');
      expect(activity.lessonId, 'lesson_abc');
      expect(activity.isRead, true);
      expect(activity.isSaved, false);
      expect(activity.reflectionNote, 'Very interesting!');
      expect(activity.completedAt, isNull);
    });

    test('copyWith should update fields correctly', () {
      final activity = UserActivity(userId: 'user_1', lessonId: 'lesson_1');
      final updated = activity.copyWith(isSaved: true, reflectionNote: 'Noted');

      expect(updated.userId, 'user_1');
      expect(updated.lessonId, 'lesson_1');
      expect(updated.isRead, false);
      expect(updated.isSaved, true);
      expect(updated.reflectionNote, 'Noted');
    });
  });

  group('UserStreak Calculation Logic Tests', () {
    final now = DateTime(2026, 8, 11, 12, 0); // 2026-08-11 noon

    test('Scenario A: First completion ever (lastCompletedDate is null)', () {
      final result = UserStreak.calculateNextStreak(
        currentStreak: 0,
        longestStreak: 0,
        lastCompletedDate: null,
        now: now,
      );

      expect(result.currentStreak, 1);
      expect(result.longestStreak, 1);
      expect(result.lastCompletedDate, now);
    });

    test('Scenario B: Same day completion (lastCompletedDate is today)', () {
      final lastCompleted = DateTime(2026, 8, 11, 8, 0); // Completed earlier today
      final result = UserStreak.calculateNextStreak(
        currentStreak: 3,
        longestStreak: 5,
        lastCompletedDate: lastCompleted,
        now: now,
      );

      // Streak details must remain unchanged
      expect(result.currentStreak, 3);
      expect(result.longestStreak, 5);
      expect(result.lastCompletedDate, lastCompleted);
    });

    test('Scenario C: Consecutive day completion (lastCompletedDate is yesterday)', () {
      final lastCompleted = DateTime(2026, 8, 10, 15, 30); // Completed yesterday
      final result = UserStreak.calculateNextStreak(
        currentStreak: 2,
        longestStreak: 2,
        lastCompletedDate: lastCompleted,
        now: now,
      );

      // Current streak increments, longest streak increments since new current > old longest
      expect(result.currentStreak, 3);
      expect(result.longestStreak, 3);
      expect(result.lastCompletedDate, now);
    });

    test('Scenario D: Broken streak completion (lastCompletedDate is 2+ days ago)', () {
      final lastCompleted = DateTime(2026, 8, 9, 10, 0); // Completed 2 days ago (missed yesterday)
      final result = UserStreak.calculateNextStreak(
        currentStreak: 4,
        longestStreak: 10,
        lastCompletedDate: lastCompleted,
        now: now,
      );

      // Current streak resets to 1, longest streak stays at peak (10)
      expect(result.currentStreak, 1);
      expect(result.longestStreak, 10);
      expect(result.lastCompletedDate, now);
    });
  });
}
