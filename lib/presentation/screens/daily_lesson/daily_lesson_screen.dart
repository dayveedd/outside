import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/constants.dart';
import '../../../core/services/onesignal_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/auth/auth_event.dart';
import '../../../logic/auth/auth_state.dart';
import '../../../logic/lesson/lesson_bloc.dart';
import '../../../logic/lesson/lesson_event.dart';
import '../../../logic/lesson/lesson_state.dart';
import '../../../logic/streak/streak_bloc.dart';
import '../../../logic/streak/streak_event.dart';
import '../../../logic/streak/streak_state.dart';
import '../../widgets/editorial_card.dart';
import '../../widgets/share_card_view.dart';
import '../../widgets/streak_badge.dart';
import '../reflection_modal/reflection_modal.dart';

class DailyLessonScreen extends StatefulWidget {
  const DailyLessonScreen({super.key});

  @override
  State<DailyLessonScreen> createState() => _DailyLessonScreenState();
}

class _DailyLessonScreenState extends State<DailyLessonScreen> {
  StreamSubscription<String>? _deepLinkSubscription;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    // Subscribe to OneSignal deep links
    _deepLinkSubscription = OneSignalService().deepLinkStream.listen((lessonId) {
      if (_currentUserId != null) {
        context.read<LessonBloc>().add(LoadDailyLesson(_currentUserId!, lessonId: lessonId));
      }
    });
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  void _triggerOnboardingLoad(String userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      // Load daily lesson and streak details
      context.read<LessonBloc>().add(LoadDailyLesson(userId));
      context.read<StreakBloc>().add(LoadStreak(userId));
    }
  }

  void _openReflectionModal(BuildContext context, String lessonId, String prompt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<LessonBloc>()),
          BlocProvider.value(value: context.read<StreakBloc>()),
        ],
        child: ReflectionModal(
          userId: _currentUserId!,
          lessonId: lessonId,
          prompt: prompt,
        ),
      ),
    ).then((_) {
      // Reload streak to reflect any increments
      if (_currentUserId != null) {
        context.read<StreakBloc>().add(LoadStreak(_currentUserId!));
      }
    });
  }

  void _openShareModal(BuildContext context, dynamic lesson) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareCardView(lesson: lesson),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, authState) {
        if (authState is Authenticated) {
          _triggerOnboardingLoad(authState.user.uid);
        } else if (authState is Unauthenticated) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'OUTSIDE.',
            style: AppTypography.uiSemiBold.copyWith(
              fontSize: 20,
              letterSpacing: 2.0,
              color: AppColors.secondary,
            ),
          ),
          centerTitle: false,
          actions: [
            // Streak badge
            BlocBuilder<StreakBloc, StreakState>(
              builder: (context, streakState) {
                int count = 0;
                if (streakState is StreakLoaded) {
                  count = streakState.streak.currentStreak;
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: StreakBadge(
                    streakCount: count,
                    onTap: () {
                      if (streakState is StreakLoaded) {
                        final streak = streakState.streak;
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Streak Stats'),
                            content: Text(
                              'Current Streak: ${streak.currentStreak} days\n'
                              'Longest Streak: ${streak.longestStreak} days',
                              style: AppTypography.uiMedium,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Great'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.bookmark_border_rounded),
              onPressed: () {
                if (_currentUserId != null) {
                  Navigator.pushNamed(context, AppConstants.savedRoute);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.history_rounded),
              onPressed: () {
                if (_currentUserId != null) {
                  Navigator.pushNamed(context, AppConstants.archiveRoute);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () {
                context.read<AuthBloc>().add(SignOutRequested());
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            if (authState is AuthInitial || authState is AuthLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (authState is Unauthenticated) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (authState is AuthError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Auth Error: ${authState.message}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<AuthBloc>().add(AuthCheckRequested());
                      },
                      child: const Text('Retry Connection'),
                    ),
                  ],
                ),
              );
            }

            // Auth state is Authenticated, load daily lesson content
            return BlocBuilder<LessonBloc, LessonState>(
              builder: (context, lessonState) {
                if (lessonState is LessonInitial || lessonState is LessonLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Curating today\'s lesson...',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                } else if (lessonState is LessonError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error loading lesson: ${lessonState.message}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            if (_currentUserId != null) {
                              context.read<LessonBloc>().add(LoadDailyLesson(_currentUserId!));
                            }
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                } else if (lessonState is DailyLessonLoaded) {
                  final lesson = lessonState.lesson;
                  final activity = lessonState.activity;
                  final bool isSaved = activity?.isSaved ?? false;
                  final bool isRead = activity?.isRead ?? false;

                  return RefreshIndicator(
                    onRefresh: () async {
                      if (_currentUserId != null) {
                        context.read<LessonBloc>().add(LoadDailyLesson(_currentUserId!));
                      }
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                      child: Column(
                        children: [
                          EditorialCard(lesson: lesson),
                          const SizedBox(height: 24),
                          
                          // Reflection Box
                          if (isRead) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppShapes.cardRadius),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'DAILY CHALLENGE COMPLETED',
                                        style: AppTypography.uiSemiBold.copyWith(
                                          color: AppColors.success,
                                          fontSize: 12,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Your Reflection Journal:',
                                    style: AppTypography.uiMedium.copyWith(color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    activity?.reflectionNote ?? 'Completed without notes.',
                                    style: AppTypography.body.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            ElevatedButton.icon(
                              onPressed: () => _openReflectionModal(context, lesson.id, lesson.reflectionPrompt),
                              icon: const Icon(Icons.edit_note_rounded),
                              label: const Text('Journal Reflection & Complete'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 54),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),

                          // Quick actions (Save / Share)
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    if (_currentUserId != null) {
                                      context.read<LessonBloc>().add(
                                        ToggleSaveLesson(
                                          userId: _currentUserId!,
                                          lessonId: lesson.id,
                                        ),
                                      );
                                    }
                                  },
                                  icon: Icon(
                                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                                    color: isSaved ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                  label: Text(
                                    isSaved ? 'Bookmarked' : 'Save Lesson',
                                    style: TextStyle(
                                      color: isSaved ? AppColors.primary : AppColors.textSecondary,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: isSaved ? AppColors.primary : AppColors.border,
                                    ),
                                    minimumSize: const Size(0, 50),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _openShareModal(context, lesson),
                                  icon: const Icon(Icons.share_rounded, color: AppColors.textSecondary),
                                  label: const Text(
                                    'Share',
                                    style: TextStyle(color: AppColors.textSecondary),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.border),
                                    minimumSize: const Size(0, 50),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const Center(child: Text('Invalid State'));
              },
            );
          },
        ),
      ),
    );
  }
}
