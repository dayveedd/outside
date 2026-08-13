import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/auth/auth_state.dart';
import '../../../logic/lesson/lesson_bloc.dart';
import '../../../logic/lesson/lesson_event.dart';
import '../../../logic/lesson/lesson_state.dart';
import '../../../logic/subscription/subscription_bloc.dart';
import '../../../logic/subscription/subscription_event.dart';
import '../../../logic/subscription/subscription_state.dart';
import '../../../data/models/lesson.dart';
import '../../../data/repositories/lesson_repository.dart';
import '../../../logic/streak/streak_bloc.dart';
import '../../widgets/editorial_card.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    // Refresh subscription status when visiting archive
    context.read<SubscriptionBloc>().add(CheckSubscriptionStatus());
    
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _userId = authState.user.uid;
      context.read<LessonBloc>().add(LoadArchive(_userId!));
    }
  }

  void _onLessonTapped(BuildContext context, Lesson lesson, bool isPremium) {
    // Check if the lesson is today's lesson (which is free!)
    final todayStr = LessonRepository.formatDate(DateTime.now());
    final bool isToday = lesson.publishDate == todayStr;

    if (isToday || isPremium) {
      // Allow viewing: Navigate to DailyLessonScreen with the lessonId argument
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (routeContext) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: context.read<AuthBloc>()),
              BlocProvider.value(value: context.read<StreakBloc>()),
              BlocProvider.value(value: context.read<LessonBloc>()),
            ],
            child: Scaffold(
              appBar: AppBar(
                title: Text(lesson.category),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(routeContext);
                    // Reload archive when returning
                    if (_userId != null) {
                      context.read<LessonBloc>().add(LoadArchive(_userId!));
                    }
                  },
                ),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    EditorialCard(lesson: lesson),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // Trigger paywall
      Navigator.pushNamed(context, AppConstants.paywallRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ARCHIVE',
          style: AppTypography.uiSemiBold.copyWith(
            fontSize: 16,
            letterSpacing: 2.0,
            color: AppColors.secondary,
          ),
        ),
      ),
      body: BlocBuilder<SubscriptionBloc, SubscriptionState>(
        builder: (context, subState) {
          final bool isPremium = subState is SubscriptionStatus && subState.isPremium;

          return BlocBuilder<LessonBloc, LessonState>(
            builder: (context, lessonState) {
              if (lessonState is LessonInitial || lessonState is LessonLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (lessonState is LessonError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${lessonState.message}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (_userId != null) {
                            context.read<LessonBloc>().add(LoadArchive(_userId!));
                          }
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              } else if (lessonState is ArchiveLoaded) {
                final lessons = lessonState.lessons;
                final activities = lessonState.activities;
                
                // Exclude today's lesson from being gated in the listing UI
                final todayStr = LessonRepository.formatDate(DateTime.now());

                if (lessons.isEmpty) {
                  return const Center(
                    child: Text('No historical lessons found.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: lessons.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final lesson = lessons[index];
                    final activity = activities[lesson.id];
                    final isRead = activity?.isRead ?? false;
                    final isSaved = activity?.isSaved ?? false;
                    final isToday = lesson.publishDate == todayStr;
                    
                    // Locked if it's not today's and user is not premium
                    final bool isLocked = !isToday && !isPremium;

                    return Card(
                      child: InkWell(
                        onTap: () => _onLessonTapped(context, lesson, isPremium),
                        borderRadius: AppShapes.cardBorderRadius,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    lesson.category.toUpperCase(),
                                    style: AppTypography.uiSemiBold.copyWith(
                                      color: isToday ? AppColors.accent : AppColors.textSecondary,
                                      fontSize: 11,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      if (isSaved)
                                        const Padding(
                                          padding: EdgeInsets.only(right: 8.0),
                                          child: Icon(Icons.bookmark, size: 16, color: AppColors.primary),
                                        ),
                                      if (isRead)
                                        const Padding(
                                          padding: EdgeInsets.only(right: 8.0),
                                          child: Icon(Icons.check_circle, size: 16, color: AppColors.success),
                                        ),
                                      Icon(
                                        isLocked ? Icons.lock_rounded : Icons.arrow_forward_rounded,
                                        size: 16,
                                        color: isLocked ? AppColors.accent : AppColors.textMuted,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                lesson.hook,
                                style: AppTypography.uiSemiBold.copyWith(
                                  fontSize: 18,
                                  color: AppColors.secondary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    lesson.publishDate,
                                    style: AppTypography.caption,
                                  ),
                                  Text(
                                    '${lesson.readTimeMinutes} min read',
                                    style: AppTypography.caption,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
              return const Center(child: Text('Invalid State'));
            },
          );
        },
      ),
    );
  }
}
