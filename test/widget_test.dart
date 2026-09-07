import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outside/data/models/lesson.dart';
import 'package:outside/data/models/user_activity.dart';
import 'package:outside/data/models/user_streak.dart';
import 'package:outside/logic/lesson/lesson_event.dart';
import 'package:outside/logic/lesson/lesson_state.dart';
import 'package:outside/logic/subscription/subscription_state.dart';
import 'package:outside/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:outside/presentation/screens/splash/splash_screen.dart';
import 'package:outside/presentation/widgets/account_action_dialog.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

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
    final now = DateTime(2026, 8, 11, 12, 0);

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
      final lastCompleted = DateTime(2026, 8, 11, 8, 0);
      final result = UserStreak.calculateNextStreak(
        currentStreak: 3,
        longestStreak: 5,
        lastCompletedDate: lastCompleted,
        now: now,
      );

      expect(result.currentStreak, 3);
      expect(result.longestStreak, 5);
      expect(result.lastCompletedDate, lastCompleted);
    });

    test('Scenario C: Consecutive day completion (lastCompletedDate is yesterday)', () {
      final lastCompleted = DateTime(2026, 8, 10, 15, 30);
      final result = UserStreak.calculateNextStreak(
        currentStreak: 2,
        longestStreak: 2,
        lastCompletedDate: lastCompleted,
        now: now,
      );

      expect(result.currentStreak, 3);
      expect(result.longestStreak, 3);
      expect(result.lastCompletedDate, now);
    });

    test('Scenario D: Broken streak completion (lastCompletedDate is 2+ days ago)', () {
      final lastCompleted = DateTime(2026, 8, 9, 10, 0);
      final result = UserStreak.calculateNextStreak(
        currentStreak: 4,
        longestStreak: 10,
        lastCompletedDate: lastCompleted,
        now: now,
      );

      expect(result.currentStreak, 1);
      expect(result.longestStreak, 10);
      expect(result.lastCompletedDate, now);
    });

    test('daysBetween correctly calculates days difference', () {
      expect(UserStreak.daysBetween(DateTime(2026, 8, 10), DateTime(2026, 8, 11)), 1);
      expect(UserStreak.daysBetween(DateTime(2026, 8, 11), DateTime(2026, 8, 11)), 0);
      expect(UserStreak.daysBetween(DateTime(2026, 8, 9), DateTime(2026, 8, 11)), 2);
      expect(UserStreak.daysBetween(DateTime(2026, 8, 31), DateTime(2026, 9, 1)), 1);
    });
  });

  group('LessonState Tests', () {
    test('DailyLessonEmpty should hold targetDate and equate correctly', () {
      const state1 = DailyLessonEmpty(targetDate: '2026-09-02');
      const state2 = DailyLessonEmpty(targetDate: '2026-09-02');
      const state3 = DailyLessonEmpty(targetDate: '2026-09-03');

      expect(state1, equals(state2));
      expect(state1 == state3, isFalse);
      expect(state1.targetDate, '2026-09-02');
    });

    test('DailyLessonLoaded should hold pool and equate correctly', () {
      final lesson1 = Lesson.fromJson(const {
        'id': 'l1',
        'publishDate': '2026-09-04',
        'category': 'Gaming & Play',
        'hook': 'Hook 1',
        'idea': 'Idea 1',
        'whyItMatters': 'Why 1',
        'everydayExample': 'Ex 1',
        'reflectionPrompt': 'Ref 1',
        'exploreMore': <String>[],
        'readTimeMinutes': 3,
      });

      final lesson2 = Lesson.fromJson(const {
        'id': 'l2',
        'publishDate': '2026-09-04',
        'category': 'Arts & Craft',
        'hook': 'Hook 2',
        'idea': 'Idea 2',
        'whyItMatters': 'Why 2',
        'everydayExample': 'Ex 2',
        'reflectionPrompt': 'Ref 2',
        'exploreMore': <String>[],
        'readTimeMinutes': 3,
      });

      final state1 = DailyLessonLoaded(lesson: lesson1, pool: [lesson1, lesson2], defaultLessonId: lesson1.id);
      final state2 = DailyLessonLoaded(lesson: lesson1, pool: [lesson1, lesson2], defaultLessonId: lesson1.id);
      final stateAlternative = DailyLessonLoaded(lesson: lesson2, pool: [lesson1, lesson2], defaultLessonId: lesson1.id);

      expect(state1, equals(state2));
      expect(state1.pool.length, 2);
      expect(state1.defaultLessonId, 'l1');
      expect(state1.lesson.id == state1.defaultLessonId, isTrue);
      expect(stateAlternative.lesson.id != stateAlternative.defaultLessonId, isTrue);

      final event = SwitchPerspective(lesson2);
      expect(event.lesson, equals(lesson2));
      expect(event.props, [lesson2]);
    });
  });

  group('Multi-Perspective User Randomization Tests', () {
    test('same user on same day consistently receives identical selection', () {
      const userId = 'user_alex_123';
      const targetDateStr = '2026-09-04';
      final pool = ['gaming', 'arts', 'social'];

      final seed1 = (userId.hashCode ^ targetDateStr.hashCode).abs();
      final selected1 = pool[seed1 % pool.length];

      final seed2 = (userId.hashCode ^ targetDateStr.hashCode).abs();
      final selected2 = pool[seed2 % pool.length];

      expect(selected1, equals(selected2));
    });

    test('different users receive distributed perspectives across pool', () {
      const targetDateStr = '2026-09-04';
      final pool = ['gaming', 'arts', 'social'];
      final userIds = [
        'user_alpha',
        'user_beta',
        'user_gamma',
        'user_delta',
        'user_epsilon',
        'user_zeta',
      ];

      final selections = userIds.map((uid) {
        final seed = (uid.hashCode ^ targetDateStr.hashCode).abs();
        return pool[seed % pool.length];
      }).toSet();

      expect(selections.length, greaterThan(1));
    });
  });

  group('RevenueCat Subscription Tier Tests', () {
    test('SubscriptionStatus correctly stores and compares packages', () {
      final samplePackage = Package(
        'yearly_annual',
        PackageType.annual,
        StoreProduct(
          'outside_yearly_annual_999',
          'Outside Pro (Pay Annually)',
          'Full access billed annually at \$9.99/year (\$0.83/mo). Save 58%.',
          9.99,
          '\$9.99',
          'USD',
        ),
        const PresentedOfferingContext('default_offering', null, null),
      );

      final status = SubscriptionStatus(isPremium: true, packages: [samplePackage]);
      expect(status.isPremium, isTrue);
      expect(status.packages.length, 1);
      expect(status.packages.first.storeProduct.price, 9.99);
      expect(status.packages.first.storeProduct.priceString, '\$9.99');
    });
  });

  group('Onboarding Screen Tests', () {
    testWidgets('renders first slide and navigates forward on Continue', (tester) async {
      bool started = false;
      bool signedIn = false;

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            onGetStarted: () => started = true,
            onSignIn: () => signedIn = true,
          ),
        ),
      );

      expect(find.text('OUTSIDE.'), findsOneWidget);
      expect(find.text('Step Outside Your Echo Chamber'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      final headerLogo = tester.widget<Image>(find.byType(Image).first);
      expect((headerLogo.image as AssetImage).assetName, 'images/OUTSIDE.png');
      final firstImg = tester.widget<Image>(find.byType(Image).last);
      expect((firstImg.image as AssetImage).assetName, 'images/outside3.jpg');

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('See Every Idea From Every Angle'), findsOneWidget);
      final secondImg = tester.widget<Image>(find.byType(Image).last);
      expect((secondImg.image as AssetImage).assetName, 'images/outside2.jpg');

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Reflect, Journal & Grow'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      final thirdImg = tester.widget<Image>(find.byType(Image).last);
      expect((thirdImg.image as AssetImage).assetName, 'images/outside6.jpg');

      await tester.tap(find.text('Get Started'));
      expect(started, isTrue);

      await tester.tap(find.byType(TextButton).last);
      expect(signedIn, isTrue);
    });

    testWidgets('Skip button navigates directly to get started callback', (tester) async {
      bool started = false;

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            onGetStarted: () => started = true,
            onSignIn: () {},
          ),
        ),
      );

      expect(find.text('Skip'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      expect(started, isTrue);
    });
  });

  group('Account Action Dialog Tests', () {
    testWidgets('renders Logout dialog and triggers callback', (tester) async {
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  AccountActionDialog.showLogout(
                    context: context,
                    onConfirm: () => confirmed = true,
                  );
                },
                child: const Text('Open Logout'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Logout'));
      await tester.pumpAndSettle();

      expect(find.text('Sign Out of Outside?'), findsOneWidget);
      expect(find.text('Stay Signed In'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);

      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      expect(confirmed, isTrue);
      expect(find.text('Sign Out of Outside?'), findsNothing);
    });

    testWidgets('renders Delete Account dialog and triggers callback', (tester) async {
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  AccountActionDialog.showDeleteAccount(
                    context: context,
                    onConfirm: () => confirmed = true,
                  );
                },
                child: const Text('Open Delete'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Your Account?'), findsOneWidget);
      expect(find.text('Keep My Account'), findsOneWidget);
      expect(find.text('Delete Permanently'), findsOneWidget);
      expect(find.text('Streak History'), findsOneWidget);
      expect(find.text('Saved Journals'), findsOneWidget);
      expect(find.text('Pro Membership'), findsOneWidget);

      await tester.tap(find.text('Delete Permanently'));
      await tester.pumpAndSettle();

      expect(confirmed, isTrue);
      expect(find.text('Delete Your Account?'), findsNothing);
    });
  });

  group('Splash Screen Tests', () {
    testWidgets('renders animated splash screen and displays logo and title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('OUTSIDE'), findsOneWidget);
      expect(find.text('Step outside your echo chamber.'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('triggers onFinish callback after animation duration', (tester) async {
      bool finished = false;
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            onFinish: () => finished = true,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 700));
      expect(finished, isFalse);

      await tester.pump(const Duration(milliseconds: 900));
      expect(finished, isTrue);
    });
  });
}

