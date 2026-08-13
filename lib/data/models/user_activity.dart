import 'package:cloud_firestore/cloud_firestore.dart';

class UserActivity {
  final String userId;
  final String lessonId;
  final bool isRead;
  final bool isSaved;
  final String? reflectionNote;
  final DateTime? completedAt;

  UserActivity({
    required this.userId,
    required this.lessonId,
    this.isRead = false,
    this.isSaved = false,
    this.reflectionNote,
    this.completedAt,
  });

  factory UserActivity.fromJson(Map<String, dynamic> json, {String? userId, String? lessonId}) {
    return UserActivity(
      userId: userId ?? json['userId'] ?? '',
      lessonId: lessonId ?? json['lessonId'] ?? '',
      isRead: json['isRead'] ?? false,
      isSaved: json['isSaved'] ?? false,
      reflectionNote: json['reflectionNote'],
      completedAt: json['completedAt'] != null
          ? (json['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  factory UserActivity.fromFirestore(DocumentSnapshot doc, {String? userId}) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserActivity.fromJson(data, userId: userId, lessonId: doc.id);
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'lessonId': lessonId,
      'isRead': isRead,
      'isSaved': isSaved,
      'reflectionNote': reflectionNote,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  UserActivity copyWith({
    String? userId,
    String? lessonId,
    bool? isRead,
    bool? isSaved,
    String? reflectionNote,
    DateTime? completedAt,
  }) {
    return UserActivity(
      userId: userId ?? this.userId,
      lessonId: lessonId ?? this.lessonId,
      isRead: isRead ?? this.isRead,
      isSaved: isSaved ?? this.isSaved,
      reflectionNote: reflectionNote ?? this.reflectionNote,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
