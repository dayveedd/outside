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

  static int daysBetween(DateTime from, DateTime to) {
    final fromUtc = DateTime.utc(from.year, from.month, from.day);
    final toUtc = DateTime.utc(to.year, to.month, to.day);
    return toUtc.difference(fromUtc).inDays;
  }

  static UserStreak calculateNextStreak({
    required int currentStreak,
    required int longestStreak,
    required DateTime? lastCompletedDate,
    required DateTime now,
  }) {
    if (lastCompletedDate == null) {
      final newStreak = 1;
      final newLongest = newStreak > longestStreak ? newStreak : longestStreak;
      return UserStreak(
        currentStreak: newStreak,
        longestStreak: newLongest,
        lastCompletedDate: now,
      );
    }

    final diff = daysBetween(lastCompletedDate, now);

    if (diff <= 0) {
      final safeCurrent = currentStreak > 0 ? currentStreak : 1;
      final safeLongest = safeCurrent > longestStreak ? safeCurrent : longestStreak;
      return UserStreak(
        currentStreak: safeCurrent,
        longestStreak: safeLongest,
        lastCompletedDate: lastCompletedDate,
      );
    } else if (diff == 1) {
      final newStreak = currentStreak + 1;
      final newLongest = newStreak > longestStreak ? newStreak : longestStreak;
      return UserStreak(
        currentStreak: newStreak,
        longestStreak: newLongest,
        lastCompletedDate: now,
      );
    } else {
      final newStreak = 1;
      final newLongest = newStreak > longestStreak ? newStreak : longestStreak;
      return UserStreak(
        currentStreak: newStreak,
        longestStreak: newLongest,
        lastCompletedDate: now,
      );
    }
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
