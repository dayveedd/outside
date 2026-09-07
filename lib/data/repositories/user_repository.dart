import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/constants.dart';
import '../models/user_streak.dart';

class UserRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<String?> get authStateChanges => _auth.authStateChanges().map((user) => user?.uid);

  String? get currentUserId => _auth.currentUser?.uid;

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserStreak> getUserStreak(String userId) async {
    try {
      final doc = await _firestore.collection(AppConstants.usersCollection).doc(userId).get();
      if (doc.exists) {
        final streak = UserStreak.fromFirestore(doc);
        if (streak.lastCompletedDate != null) {
          final diff = UserStreak.daysBetween(streak.lastCompletedDate!, DateTime.now());
          if (diff > 1 && streak.currentStreak != 0) {
            return streak.copyWith(currentStreak: 0);
          }
        }
        return streak;
      }
      return UserStreak();
    } catch (_) {
      return UserStreak();
    }
  }

  Future<UserStreak> updateStreakAfterCompletion(String userId) async {
    try {
      final docRef = _firestore.collection(AppConstants.usersCollection).doc(userId);
      return await _firestore.runTransaction((transaction) async {
        final docSnap = await transaction.get(docRef);
        final data = docSnap.exists ? (docSnap.data() ?? {}) : {};
        final int currentStreak = data['currentStreak'] ?? 0;
        final int longestStreak = data['longestStreak'] ?? 0;
        final Timestamp? lastCompletedTimestamp = data['lastCompletedDate'];

        final now = DateTime.now();
        final lastCompletedDate = lastCompletedTimestamp?.toDate();

        final nextStreak = UserStreak.calculateNextStreak(
          currentStreak: currentStreak,
          longestStreak: longestStreak,
          lastCompletedDate: lastCompletedDate,
          now: now,
        );

        transaction.set(docRef, {
          'currentStreak': nextStreak.currentStreak,
          'longestStreak': nextStreak.longestStreak,
          'lastCompletedDate': nextStreak.lastCompletedDate != null
              ? Timestamp.fromDate(nextStreak.lastCompletedDate!)
              : null,
        }, SetOptions(merge: true));

        return nextStreak;
      });
    } catch (_) {
      return UserStreak();
    }
  }
}
