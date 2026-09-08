import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/lesson.dart';
import '../../../data/repositories/lesson_repository.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/auth/auth_state.dart';
import '../../../logic/lesson/lesson_bloc.dart';
import '../../../logic/lesson/lesson_event.dart';
import '../../../logic/lesson/lesson_state.dart';
import '../../../logic/streak/streak_bloc.dart';
import '../../../logic/subscription/subscription_bloc.dart';
import '../../../logic/subscription/subscription_event.dart';
import '../../../logic/subscription/subscription_state.dart';
import '../../widgets/editorial_card.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => SavedScreenState();
}

class SavedScreenState extends State<SavedScreen> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  void _loadInitial() {
    context.read<SubscriptionBloc>().add(CheckSubscriptionStatus());
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _userId = authState.user.uid;
      context.read<LessonBloc>().add(LoadSavedLessons(_userId!));
    }
  }

  Future<void> refresh() async {
    context.read<SubscriptionBloc>().add(CheckSubscriptionStatus());
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _userId = authState.user.uid;
      context.read<LessonBloc>().add(LoadSavedLessons(_userId!));
    }
  }

  void _onLessonTapped(BuildContext context, Lesson lesson, bool isUnlocked) {
    if (isUnlocked) {
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
                    refresh();
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
      Navigator.pushNamed(context, AppConstants.paywallRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, authState) {
        if (authState is Authenticated) {
          if (_userId != authState.user.uid) {
            _userId = authState.user.uid;
            context.read<LessonBloc>().add(LoadSavedLessons(_userId!));
          }
        } else if (authState is Unauthenticated) {
          _userId = null;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'SAVED LESSONS',
            style: AppTypography.uiSemiBold.copyWith(
              fontSize: 16,
              letterSpacing: 2.0,
              color: AppColors.secondary,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: refresh,
            ),
          ],
        ),
        body: BlocBuilder<SubscriptionBloc, SubscriptionState>(
          builder: (context, subState) {
            final bool isPremium = subState is SubscriptionStatus && subState.isPremium;

            return BlocBuilder<LessonBloc, LessonState>(
              builder: (context, state) {
                if (state is LessonInitial || state is LessonLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is LessonError) {
                  return RefreshIndicator(
                    onRefresh: refresh,
                    child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Error: ${state.message}'),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: refresh,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                } else if (state is SavedLessonsLoaded) {
                  final lessons = state.lessons;
                  final todayStr = LessonRepository.formatDate(DateTime.now());

                  if (lessons.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: refresh,
                      child: LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.bookmark_border_rounded,
                                      size: 52,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Your library is empty.',
                                      style: AppTypography.uiSemiBold.copyWith(
                                        fontSize: 16,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap the bookmark icon on any lesson to save it for future reference.\nPull down to refresh.',
                                      style: AppTypography.body.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  final Map<String, int> pastIndices = {};
                  int pCounter = 0;
                  for (var l in lessons) {
                    if (l.publishDate != todayStr) {
                      pastIndices[l.id] = pCounter++;
                    }
                  }

                  return RefreshIndicator(
                    onRefresh: refresh,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                      itemCount: lessons.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final lesson = lessons[index];
                        final isToday = lesson.publishDate == todayStr;
                        final int pastIndex = pastIndices[lesson.id] ?? 0;
                        final bool isFreePreview = !isToday && pastIndex < 2;
                        final bool isUnlocked = isToday || isPremium || isFreePreview;
                        final bool isLocked = !isUnlocked;

                        return Card(
                          child: InkWell(
                            onTap: () => _onLessonTapped(context, lesson, isUnlocked),
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
                                      Row(
                                        children: [
                                          if (isFreePreview && !isPremium)
                                            Container(
                                              margin: const EdgeInsets.only(right: 8),
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEFF6FF),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: const Color(0xFFBFDBFE)),
                                              ),
                                              child: Text(
                                                'FREE PREVIEW',
                                                style: AppTypography.caption.copyWith(
                                                  color: const Color(0xFF1D4ED8),
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          const Padding(
                                            padding: EdgeInsets.only(right: 8.0),
                                            child: Icon(
                                              Icons.bookmark,
                                              size: 16,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          Icon(
                                            isLocked
                                                ? Icons.lock_rounded
                                                : Icons.arrow_forward_rounded,
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
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: refresh,
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: const Center(child: Text('Invalid State')),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
