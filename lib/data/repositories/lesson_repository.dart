import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/constants.dart';
import '../models/lesson.dart';
import '../models/user_activity.dart';

class LessonRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String formatDate(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  List<Lesson>? _cachedArchive;
  List<Lesson>? _cachedSavedLessons;

  bool get hasCachedArchive => _cachedArchive != null;
  bool get hasCachedSaved => _cachedSavedLessons != null;

  Future<Lesson> getLessonById(String lessonId) async {
    final doc = await _firestore
        .collection(AppConstants.lessonsCollection)
        .doc(lessonId)
        .get();

    if (doc.exists) {
      return Lesson.fromFirestore(doc);
    }
    throw Exception("Lesson not found");
  }

  Future<Lesson?> getDailyLesson({String? userId, DateTime? date}) async {
    final targetDateStr = formatDate(date ?? DateTime.now());

    final snap = await _firestore
        .collection(AppConstants.lessonsCollection)
        .where('publishDate', isEqualTo: targetDateStr)
        .get();

    if (snap.docs.isNotEmpty) {
      if (snap.docs.length == 1 || userId == null || userId.isEmpty) {
        return Lesson.fromFirestore(snap.docs.first);
      }
      final int userSeed = (userId.hashCode ^ targetDateStr.hashCode).abs();
      final selectedDoc = snap.docs[userSeed % snap.docs.length];
      return Lesson.fromFirestore(selectedDoc);
    }
    return null;
  }

  Future<List<Lesson>> getDailyLessonPool({DateTime? date}) async {
    final targetDateStr = formatDate(date ?? DateTime.now());
    final snap = await _firestore
        .collection(AppConstants.lessonsCollection)
        .where('publishDate', isEqualTo: targetDateStr)
        .get();

    if (snap.docs.isNotEmpty) {
      return snap.docs.map((doc) => Lesson.fromFirestore(doc)).toList();
    }
    return [];
  }

  Future<List<Lesson>> getArchive({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedArchive != null) {
      return _cachedArchive!;
    }
    final todayStr = formatDate(DateTime.now());
    
    final snap = await _firestore
        .collection(AppConstants.lessonsCollection)
        .where('publishDate', isLessThanOrEqualTo: todayStr)
        .get();
    
    if (snap.docs.isNotEmpty) {
      final lessons = snap.docs.map((doc) => Lesson.fromFirestore(doc)).toList();
      lessons.sort((a, b) => b.publishDate.compareTo(a.publishDate));
      _cachedArchive = lessons;
      return lessons;
    }
    _cachedArchive = [];
    return [];
  }

  final Map<String, UserActivity> _localActivities = {};

  UserActivity? getCachedUserActivity(String lessonId) => _localActivities[lessonId];

  Future<UserActivity?> getUserActivity(String userId, String lessonId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.activitiesCollection)
          .doc(lessonId)
          .get();

      if (doc.exists) {
        final act = UserActivity.fromFirestore(doc, userId: userId);
        _localActivities[lessonId] = act;
        return act;
      }
      return _localActivities[lessonId];
    } catch (e) {
      return _localActivities[lessonId];
    }
  }

  Future<Map<String, UserActivity>> getUserActivities(String userId) async {
    try {
      final snap = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.activitiesCollection)
          .get();

      final Map<String, UserActivity> activities = {};
      for (var doc in snap.docs) {
        final act = UserActivity.fromFirestore(doc, userId: userId);
        activities[act.lessonId] = act;
        _localActivities[act.lessonId] = act;
      }
      return activities;
    } catch (e) {
      return Map<String, UserActivity>.from(_localActivities);
    }
  }

  Future<void> saveUserActivity(UserActivity activity) async {
    _localActivities[activity.lessonId] = activity;
    if (!activity.isSaved && _cachedSavedLessons != null) {
      _cachedSavedLessons!.removeWhere((l) => l.id == activity.lessonId);
    } else if (activity.isSaved) {
      _cachedSavedLessons = null;
    }

    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(activity.userId)
          .collection(AppConstants.activitiesCollection)
          .doc(activity.lessonId)
          .set(activity.toJson(), SetOptions(merge: true));
    } catch (_) {}
  }

  Future<List<Lesson>> getSavedLessons(String userId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedSavedLessons != null) {
      return _cachedSavedLessons!;
    }

    final Set<String> savedLessonIds = {};
    for (var entry in _localActivities.entries) {
      if (entry.value.isSaved) {
        savedLessonIds.add(entry.key);
      }
    }

    try {
      final snap = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.activitiesCollection)
          .where('isSaved', isEqualTo: true)
          .get();

      for (var doc in snap.docs) {
        savedLessonIds.add(doc.id);
        if (!_localActivities.containsKey(doc.id)) {
          _localActivities[doc.id] = UserActivity.fromFirestore(doc, userId: userId);
        }
      }
    } catch (_) {}

    if (savedLessonIds.isEmpty) {
      _cachedSavedLessons = [];
      return [];
    }

    final List<Lesson> saved = [];
    for (var id in savedLessonIds) {
      try {
        final lessonDoc = await _firestore.collection(AppConstants.lessonsCollection).doc(id).get();
        if (lessonDoc.exists) {
          saved.add(Lesson.fromFirestore(lessonDoc));
        }
      } catch (_) {}
    }
    _cachedSavedLessons = saved;
    return saved;
  }
}
