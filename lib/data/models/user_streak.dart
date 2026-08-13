import 'package:cloud_firestore/cloud_firestore.dart';

class UserStreak {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCompletedDate;

  UserStreak({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCompletedDate,
  });

  factory UserStreak.fromJson(Map<String, dynamic> json) {
    return UserStreak(
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      lastCompletedDate: json['lastCompletedDate'] != null
          ? (json['lastCompletedDate'] as Timestamp).toDate()
          : null,
    );
  }

  factory UserStreak.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists || doc.data() == null) {
      return UserStreak();
    }
    final data = doc.data() as Map<String, dynamic>;
    return UserStreak.fromJson(data);
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastCompletedDate': lastCompletedDate != null
          ? Timestamp.fromDate(lastCompletedDate!)
          : null,
    };
  }

  static UserStreak calculateNextStreak({
    required int currentStreak,
    required int longestStreak,
    required DateTime? lastCompletedDate,
    required DateTime now,
  }) {
    final todayDate = DateTime(now.year, now.month, now.day);
    int newCurrentStreak = currentStreak;
    int newLongestStreak = longestStreak;

    if (lastCompletedDate == null) {
      newCurrentStreak = 1;
      newLongestStreak = newCurrentStreak > longestStreak ? newCurrentStreak : longestStreak;
    } else {
      final lastCompleted = DateTime(
        lastCompletedDate.year,
        lastCompletedDate.month,
        lastCompletedDate.day,
      );
      final difference = todayDate.difference(lastCompleted).inDays;

      if (difference == 0) {
        return UserStreak(
          currentStreak: currentStreak,
          longestStreak: longestStreak,
          lastCompletedDate: lastCompletedDate,
        );
      } else if (difference == 1) {
        newCurrentStreak = currentStreak + 1;
        newLongestStreak = newCurrentStreak > longestStreak ? newCurrentStreak : longestStreak;
      } else {
        newCurrentStreak = 1;
        newLongestStreak = newCurrentStreak > longestStreak ? newCurrentStreak : longestStreak;
      }
    }

    return UserStreak(
      currentStreak: newCurrentStreak,
      longestStreak: newLongestStreak,
      lastCompletedDate: now,
    );
  }

  UserStreak copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastCompletedDate,
  }) {
    return UserStreak(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
    );
  }
}
