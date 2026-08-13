import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/constants.dart';
import '../models/lesson.dart';
import '../models/user_activity.dart';

class LessonRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Format helper
  static String formatDate(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  // Predefined high-impact editorial lessons
  static List<Lesson> getMockLessons() {
    final now = DateTime.now();
    return [
      Lesson(
        id: 'lesson_explanatory_depth',
        publishDate: formatDate(now),
        category: 'Psychology',
        hook: 'Do you actually know how a toilet works?',
        idea: 'Most people believe they understand everyday mechanisms (like zippers, keys, or toilets) perfectly. However, when asked to explain step-by-step how they function, they realize they have no idea. This is the "Illusion of Explanatory Depth": we mistake our familiarity with an object for an understanding of its inner workings.',
        whyItMatters: 'We live in an age of instant opinions. Understanding this illusion humbles us. It teaches us to distinguish between knowing the name of something and understanding it, prompting us to pause before asserting expertise on complex social, political, or technical systems.',
        everydayExample: 'Think of how easily we debate economic policies, yet struggle to explain how inflation is calculated or how a bank operates. We confuse our ability to use a system with our comprehension of it.',
        reflectionPrompt: 'Choose one topic or system you hold a strong opinion on. If you had to explain its step-by-step mechanics to a child right now, where would your explanation break down?',
        exploreMore: [
          'Read "The Knowledge Illusion" by Steven Sloman and Philip Fernbach',
          'Listen to the "You Are Not So Smart" Podcast Ep: Explanatory Depth'
        ],
        readTimeMinutes: 3,
      ),
      Lesson(
        id: 'lesson_mycorrhizal_networks',
        publishDate: formatDate(now.subtract(const Duration(days: 1))),
        category: 'Biology',
        hook: 'The forest is talking. We are just deaf to it.',
        idea: 'Beneath the forest floor lies a dense network of fungal threads (mycelium) connecting trees. Dubbed the "Wood Wide Web", this mycorrhizal network allows trees to share carbon, nitrogen, and phosphorus. Older "mother trees" use it to feed their shaded seedlings, and dying trees dump their resources back into the network for neighbors to use.',
        whyItMatters: 'It challenges our core Darwinian assumption that nature is strictly competitive. Evolution is as much about cooperation and symbiosis as it is about survival of the fittest. Forests operate as a single super-organism rather than a collection of isolated individuals.',
        everydayExample: 'When a tree is attacked by insects, it sends warning chemical signals through the underground network to neighboring trees, prompting them to produce defensive toxins before the insects arrive.',
        reflectionPrompt: 'If nature values sharing and early warning networks for mutual survival, how can you build similar supportive infrastructures in your community or team?',
        exploreMore: [
          'Watch Suzanne Simard\'s TED Talk: "How trees talk to each other"',
          'Read "Finding the Mother Tree" by Suzanne Simard'
        ],
        readTimeMinutes: 4,
      ),
      Lesson(
        id: 'lesson_hostile_architecture',
        publishDate: formatDate(now.subtract(const Duration(days: 2))),
        category: 'Architecture',
        hook: 'Why do park benches have middle armrests?',
        idea: 'Hostile architecture is an urban design strategy that uses the built environment to restrict or guide human behavior. Benches with middle dividers to prevent sleeping, sloped windowsills, and spikes in alcoves are designed to deter unhoused populations and teenagers from lingering.',
        whyItMatters: 'It shows how design is never neutral. It can be weaponized silently to solve social problems through exclusion rather than empathy. By physically removing visible signs of poverty, society avoids addressing the systemic causes.',
        everydayExample: 'Notice how the ambient music in fast-food restaurants is just loud enough to prevent long conversations, or how airport seating is designed to prevent sleeping, encouraging travelers to spend money in shops instead.',
        reflectionPrompt: 'Look around your neighborhood. What design choices have been implemented to control behavior rather than serve human comfort?',
        exploreMore: [
          'Read "Hostile Architecture: The Design of Exclusion" in the Guardian',
          'Listen to 99% Invisible Episode: "Unpleasant Design"'
        ],
        readTimeMinutes: 3,
      ),
      Lesson(
        id: 'lesson_ship_of_theseus',
        publishDate: formatDate(now.subtract(const Duration(days: 3))),
        category: 'Philosophy',
        hook: 'If you replace every wooden plank on a ship, is it still the same ship?',
        idea: 'The Ship of Theseus is a thought experiment about identity. A legendary ship is preserved in a harbor, but over time, its rotting planks are replaced one by one. Eventually, none of the original components remain. Is it still the same ship? Further: if the old planks were saved and used to build a second ship, which one is the "original"?',
        whyItMatters: 'It forces us to rethink what constitutes identity. Are you the same person you were ten years ago, even though almost all the cells in your body have died and been replaced? Identity might lie in the pattern of organization rather than the physical matter itself.',
        everydayExample: 'Consider a historic band that has changed members gradually over 40 years. If no original members remain, does the band still hold the legacy of the original recordings?',
        reflectionPrompt: 'If your cells, memories, and beliefs change throughout your life, what is the core "plank" that makes you uniquely who you are?',
        exploreMore: [
          'Watch wireless philosophy series on the Ship of Theseus',
          'Read Thomas Hobbes\' addition to the paradox'
        ],
        readTimeMinutes: 4,
      ),
      Lesson(
        id: 'lesson_dunbars_number',
        publishDate: formatDate(now.subtract(const Duration(days: 4))),
        category: 'Sociology',
        hook: 'You only have room for 150 friends.',
        idea: 'Anthropologist Robin Dunbar discovered a correlation between primate brain size and social group size. Applied to humans, this yields "Dunbar\'s Number": a cognitive limit of about 150 individuals with whom we can maintain stable, meaningful relationships—the kind where you know who they are and how they relate to everyone else.',
        whyItMatters: 'Social media tricks us into believing we can maintain thousands of friendships. This overextends our cognitive capacity, leading to shallow connections and digital exhaustion. Recognizing our limits helps us focus our social energy on deep relationships.',
        everydayExample: 'Modern military companies, traditional villages, and successful start-ups often split or restructure once they exceed approximately 150 members to preserve trust and prevent chaotic hierarchy.',
        reflectionPrompt: 'If you audit your close contacts, who are the core 150 people you want to invest in, and how much energy are you spending on the noise outside that circle?',
        exploreMore: [
          'Read "How Many Friends Does a Person Need?" by Robin Dunbar',
          'Listen to Freakonomics Radio: Dunbar\'s Number'
        ],
        readTimeMinutes: 3,
      ),
    ];
  }

  // Ensures that lessons are seeded into Firestore if it is empty
  Future<void> seedDatabaseIfEmpty() async {
    try {
      final snap = await _firestore.collection(AppConstants.lessonsCollection).limit(1).get();
      if (snap.docs.isEmpty) {
        print('Firestore Lessons collection is empty. Seeding mock lessons...');
        final mockLessons = getMockLessons();
        for (var lesson in mockLessons) {
          await _firestore
              .collection(AppConstants.lessonsCollection)
              .doc(lesson.id)
              .set(lesson.toJson());
        }
        print('Lessons seeded successfully!');
      }
    } catch (e) {
      print('Failed to seed database: $e');
    }
  }

  // Fetch a lesson by ID (useful for push notification deep links)
  Future<Lesson> getLessonById(String lessonId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.lessonsCollection)
          .doc(lessonId)
          .get();

      if (doc.exists) {
        return Lesson.fromFirestore(doc);
      }
    } catch (e) {
      print('Firestore getLessonById failed ($e). Falling back to mock search.');
    }

    final localMocks = getMockLessons();
    return localMocks.firstWhere(
      (l) => l.id == lessonId,
      orElse: () => localMocks.first,
    );
  }

  // Fetch today's lesson (or fallback)
  Future<Lesson> getDailyLesson({DateTime? date}) async {
    final targetDateStr = formatDate(date ?? DateTime.now());
    
    try {
      final snap = await _firestore
          .collection(AppConstants.lessonsCollection)
          .where('publishDate', isEqualTo: targetDateStr)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        return Lesson.fromFirestore(snap.docs.first);
      }
    } catch (e) {
      print('Firestore getDailyLesson failed ($e). Falling back to mock.');
    }

    // Fallback: match in local mock data or return explanatory depth
    final localMocks = getMockLessons();
    return localMocks.firstWhere(
      (l) => l.publishDate == targetDateStr,
      orElse: () => localMocks.first,
    );
  }

  // Get historical lessons (Archive)
  Future<List<Lesson>> getArchive() async {
    final todayStr = formatDate(DateTime.now());
    
    try {
      final snap = await _firestore
          .collection(AppConstants.lessonsCollection)
          .where('publishDate', isLessThanOrEqualTo: todayStr)
          .get();
      
      if (snap.docs.isNotEmpty) {
        final lessons = snap.docs.map((doc) => Lesson.fromFirestore(doc)).toList();
        lessons.sort((a, b) => b.publishDate.compareTo(a.publishDate));
        return lessons;
      }
    } catch (e) {
      print('Firestore getArchive failed ($e). Returning local mocks.');
    }

    final localMocks = getMockLessons()
        .where((l) => l.publishDate.compareTo(todayStr) <= 0)
        .toList();
    localMocks.sort((a, b) => b.publishDate.compareTo(a.publishDate));
    return localMocks;
  }

  // Local in-memory cache for user activity
  final Map<String, UserActivity> _localActivities = {};

  // Fetch UserActivity for a specific lesson
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
      print('Error getting user activity from Firestore: $e. Returning cached local activity.');
      return _localActivities[lessonId];
    }
  }

  // Fetch all activities for a user (to map onto archive or feed)
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
      print('Error getting user activities from Firestore: $e. Returning cached local activities.');
      return Map<String, UserActivity>.from(_localActivities);
    }
  }

  // Save/Update UserActivity (Save, Complete, Reflection Note)
  Future<void> saveUserActivity(UserActivity activity) async {
    // Optimistically update local memory cache first
    _localActivities[activity.lessonId] = activity;
    
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(activity.userId)
          .collection(AppConstants.activitiesCollection)
          .doc(activity.lessonId)
          .set(activity.toJson());
    } catch (e) {
      print('Error saving user activity to Firestore: $e. Saved in local memory only.');
    }
  }

  // Get user's saved lessons
  Future<List<Lesson>> getSavedLessons(String userId) async {
    try {
      final snap = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.activitiesCollection)
          .where('isSaved', isEqualTo: true)
          .get();

      if (snap.docs.isEmpty) return [];

      final lessonIds = snap.docs.map((doc) => doc.id).toList();
      final List<Lesson> saved = [];

      for (var id in lessonIds) {
        final lessonDoc = await _firestore.collection(AppConstants.lessonsCollection).doc(id).get();
        if (lessonDoc.exists) {
          saved.add(Lesson.fromFirestore(lessonDoc));
        } else {
          // Fallback to mock search
          final localMocks = getMockLessons();
          final found = localMocks.where((l) => l.id == id);
          if (found.isNotEmpty) saved.add(found.first);
        }
      }
      return saved;
    } catch (e) {
      print('Error fetching saved lessons from Firestore: $e. Returning locally saved bookmarks.');
      final savedIds = _localActivities.entries
          .where((entry) => entry.value.isSaved)
          .map((entry) => entry.key)
          .toSet();
      
      final localMocks = getMockLessons();
      return localMocks.where((l) => savedIds.contains(l.id)).toList();
    }
  }
}
