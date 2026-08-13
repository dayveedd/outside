import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/auth/auth_state.dart';
import '../../../logic/lesson/lesson_bloc.dart';
import '../../../logic/lesson/lesson_event.dart';
import '../../../logic/lesson/lesson_state.dart';
import '../../../data/models/lesson.dart';
import '../../../logic/streak/streak_bloc.dart';
import '../../widgets/editorial_card.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _userId = authState.user.uid;
      context.read<LessonBloc>().add(LoadSavedLessons(_userId!));
    }
  }

  void _onLessonTapped(BuildContext context, Lesson lesson) {
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
                  // Refresh saved list when returning
                  if (_userId != null) {
                    context.read<LessonBloc>().add(LoadSavedLessons(_userId!));
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SAVED LESSONS',
          style: AppTypography.uiSemiBold.copyWith(
            fontSize: 16,
            letterSpacing: 2.0,
            color: AppColors.secondary,
          ),
        ),
      ),
      body: BlocBuilder<LessonBloc, LessonState>(
        builder: (context, state) {
          if (state is LessonInitial || state is LessonLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is LessonError) {
            return Center(
              child: Text('Error loading saved lessons: ${state.message}'),
            );
          } else if (state is SavedLessonsLoaded) {
            final lessons = state.lessons;

            if (lessons.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.bookmark_border_rounded,
                      size: 48,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your library is empty.',
                      style: AppTypography.uiMedium.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Save lessons from the daily feed to read them here.',
                      style: AppTypography.caption,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: lessons.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final lesson = lessons[index];

                return Card(
                  child: InkWell(
                    onTap: () => _onLessonTapped(context, lesson),
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
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const Icon(
                                Icons.bookmark,
                                size: 16,
                                color: AppColors.primary,
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
      ),
    );
  }
}
