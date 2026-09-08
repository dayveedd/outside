import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/constants.dart';
import '../models/lesson.dart';
import '../models/user_activity.dart';

class LessonRepository {
  final FirebaseFirestore? _firestoreInstance;
  final FirebaseAuth? _authInstance;

  LessonRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestoreInstance = firestore,
        _authInstance = auth;

  FirebaseFirestore get _firestore => _firestoreInstance ?? FirebaseFirestore.instance;
  FirebaseAuth get _auth => _authInstance ?? FirebaseAuth.instance;

  static String formatDate(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  static List<Lesson> filterArchiveForUser(
    List<Lesson> lessons, {
    required DateTime userCreatedAt,
    DateTime? now,
  }) {
    final todayStr = formatDate(now ?? DateTime.now());
    final userJoinDateStr = formatDate(userCreatedAt.toLocal());
    final effectiveJoinDateStr = userJoinDateStr.compareTo(todayStr) > 0 ? todayStr : userJoinDateStr;
    final filtered = lessons.where((l) {
      return l.publishDate.compareTo(effectiveJoinDateStr) >= 0 &&
          l.publishDate.compareTo(todayStr) <= 0;
    }).toList();
    filtered.sort((a, b) => b.publishDate.compareTo(a.publishDate));
    return filtered;
  }

  final Map<String, List<Lesson>> _userArchive = {};
  final Map<String, List<Lesson>> _userSavedLessons = {};
  final Map<String, Map<String, UserActivity>> _userActivities = {};

  bool hasCachedArchive(String userId) => _userArchive.containsKey(userId);
  bool hasCachedSaved(String userId) => _userSavedLessons.containsKey(userId);

  void clearCache({String? userId}) {
    if (userId != null) {
      _userArchive.remove(userId);
      _userSavedLessons.remove(userId);
      _userActivities.remove(userId);
    } else {
      _userArchive.clear();
      _userSavedLessons.clear();
      _userActivities.clear();
    }
  }

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

  Future<List<Lesson>> getArchive({
    required String userId,
    DateTime? userCreatedAt,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _userArchive.containsKey(userId)) {
      return _userArchive[userId]!;
    }

    DateTime? createdAt = userCreatedAt;
    if (createdAt == null) {
      final currentAuthUser = _auth.currentUser;
      if (currentAuthUser != null && currentAuthUser.uid == userId) {
        createdAt = currentAuthUser.metadata.creationTime;
      }
    }
    if (createdAt == null) {
      try {
        final userDoc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .get();
        if (userDoc.exists) {
          final data = userDoc.data();
          final dynamic rawCreated = data?['createdAt'];
          if (rawCreated is Timestamp) {
            createdAt = rawCreated.toDate();
          } else if (rawCreated is String) {
            createdAt = DateTime.tryParse(rawCreated);
          }
        }
      } catch (_) {}
    }
    createdAt ??= DateTime.now();

    final todayStr = formatDate(DateTime.now());

    final snap = await _firestore
        .collection(AppConstants.lessonsCollection)
        .where('publishDate', isLessThanOrEqualTo: todayStr)
        .get();

    if (snap.docs.isNotEmpty) {
      final lessons = snap.docs.map((doc) => Lesson.fromFirestore(doc)).toList();
      final filtered = filterArchiveForUser(lessons, userCreatedAt: createdAt);
      _userArchive[userId] = filtered;
      return filtered;
    }
    _userArchive[userId] = [];
    return [];
  }

  UserActivity? getCachedUserActivity(String lessonId, {String? userId}) {
    if (userId != null) {
      return _userActivities[userId]?[lessonId];
    }
    for (final map in _userActivities.values) {
      if (map.containsKey(lessonId)) {
        return map[lessonId];
      }
    }
    return null;
  }

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
        _userActivities.putIfAbsent(userId, () => {})[lessonId] = act;
        return act;
      }
      return _userActivities[userId]?[lessonId];
    } catch (_) {
      return _userActivities[userId]?[lessonId];
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
      }
      _userActivities[userId] = activities;
      return activities;
    } catch (_) {
      return Map<String, UserActivity>.from(_userActivities[userId] ?? {});
    }
  }

  Future<void> saveUserActivity(UserActivity activity) async {
    _userActivities.putIfAbsent(activity.userId, () => {})[activity.lessonId] = activity;
    final userSaved = _userSavedLessons[activity.userId];
    if (!activity.isSaved && userSaved != null) {
      userSaved.removeWhere((l) => l.id == activity.lessonId);
    } else if (activity.isSaved) {
      _userSavedLessons.remove(activity.userId);
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
    if (!forceRefresh && _userSavedLessons.containsKey(userId)) {
      return _userSavedLessons[userId]!;
    }

    final Set<String> savedLessonIds = {};
    final userActivities = _userActivities[userId];
    if (userActivities != null) {
      for (var entry in userActivities.entries) {
        if (entry.value.isSaved) {
          savedLessonIds.add(entry.key);
        }
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
        _userActivities.putIfAbsent(userId, () => {})[doc.id] =
            UserActivity.fromFirestore(doc, userId: userId);
      }
    } catch (_) {}

    if (savedLessonIds.isEmpty) {
      _userSavedLessons[userId] = [];
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
    _userSavedLessons[userId] = saved;
    return saved;
  }
}
