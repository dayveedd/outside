import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/onesignal_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/lesson.dart';
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
import '../../widgets/streak_stats_modal.dart';
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
    _deepLinkSubscription = OneSignalService().deepLinkStream.listen((lessonId) {
      if (_currentUserId != null && mounted) {
        context.read<LessonBloc>().add(LoadDailyLesson(_currentUserId!, lessonId: lessonId));
      }
    });
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _triggerOnboardingLoad(authState.user.uid);
    }
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  void _triggerOnboardingLoad(String userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      context.read<LessonBloc>().add(LoadDailyLesson(userId));
      context.read<StreakBloc>().add(LoadStreak(userId));
    }
  }

  void _openReflectionModal(BuildContext context, String lessonId, String prompt) {
    final streakBloc = context.read<StreakBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<LessonBloc>()),
          BlocProvider.value(value: streakBloc),
        ],
        child: ReflectionModal(
          userId: _currentUserId!,
          lessonId: lessonId,
          prompt: prompt,
        ),
      ),
    ).then((_) {
      if (_currentUserId != null && mounted) {
        streakBloc.add(LoadStreak(_currentUserId!));
      }
    });
  }

  void _openShareModal(BuildContext context, dynamic lesson) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareCardView(lesson: lesson),
    );
  }

  Widget _buildWelcomeInstance(BuildContext context) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: AppColors.surface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: AppShapes.cardBorderRadius,
                side: const BorderSide(color: AppColors.border, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'WELCOME TO OUTSIDE',
                        style: AppTypography.uiSemiBold.copyWith(
                          color: AppColors.primary,
                          fontSize: 11,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Step outside your echo chamber.',
                      style: AppTypography.h1.copyWith(
                        color: AppColors.secondary,
                        fontSize: 28,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Outside curates exactly one mind-expanding, cross-disciplinary perspective every single day at 00:00 UTC. Rather than endless doomscrolling, we offer a single idea designed to spark genuine curiosity.',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(color: AppColors.accent, width: 4),
                        ),
                        color: Color(0xFFFEFBF3),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TODAY\'S LESSON IS IN PREPARATION',
                            style: AppTypography.uiSemiBold.copyWith(
                              color: AppColors.accent,
                              fontSize: 11,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Your next curated edition will arrive shortly. Enable notifications below so you never miss a daily drop.',
                            style: AppTypography.body.copyWith(
                              fontStyle: FontStyle.italic,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'THE OUTSIDE DISCIPLINE',
                      style: AppTypography.uiSemiBold.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildPillarRow(Icons.lightbulb_outline_rounded, 'One Idea a Day', 'No algorithmic feeds. Exactly one perspective to chew on.'),
                    const SizedBox(height: 12),
                    _buildPillarRow(Icons.explore_outlined, 'Cross-Disciplinary', 'Ideas bridging philosophy, cognitive science, architecture, and biology.'),
                    const SizedBox(height: 12),
                    _buildPillarRow(Icons.edit_note_rounded, 'Daily Reflection', 'A short journaling challenge to apply the insight to your life.'),
                    const SizedBox(height: 32),
                    ValueListenableBuilder<bool>(
                      valueListenable: OneSignalService().permissionNotifier,
                      builder: (context, hasPermission, _) {
                        if (hasPermission) {
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Daily drop notifications are active',
                                    style: AppTypography.uiSemiBold.copyWith(
                                      fontSize: 13,
                                      color: const Color(0xFF166534),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final granted = await OneSignalService().promptNotificationPermission();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          granted ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                                          color: granted ? AppColors.success : AppColors.accent,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            granted
                                                ? 'Daily drop notifications enabled.'
                                                : 'Notification preferences updated.',
                                            style: AppTypography.uiMedium.copyWith(
                                              color: AppColors.textPrimary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: AppColors.surface,
                                    behavior: SnackBarBehavior.floating,
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: const BorderSide(color: AppColors.border),
                                    ),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.notifications_active_rounded),
                            label: const Text('Enable Daily Drop Notifications'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 52),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        if (_currentUserId != null) {
                          context.read<LessonBloc>().add(LoadDailyLesson(_currentUserId!));
                        }
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Check for Lesson Now'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillarRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.secondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.uiSemiBold.copyWith(fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTypography.caption),
            ],
          ),
        ),
      ],
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
            BlocBuilder<StreakBloc, StreakState>(
              builder: (context, streakState) {
                int count = 0;
                if (streakState is StreakLoaded) {
                  count = streakState.streak.currentStreak;
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: StreakBadge(
                    streakCount: count,
                    onTap: () {
                      if (streakState is StreakLoaded) {
                        StreakStatsModal.show(context, streakState.streak);
                      }
                    },
                  ),
                );
              },
            ),
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
                } else if (lessonState is DailyLessonEmpty) {
                  return _buildWelcomeInstance(context);
                } else if (lessonState is LessonError) {
                  if (lessonState.message.toLowerCase().contains('not found') ||
                      lessonState.message.toLowerCase().contains('no lesson') ||
                      lessonState.message.toLowerCase().contains('empty')) {
                    return _buildWelcomeInstance(context);
                  }
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
                  final String? defaultId = lessonState.defaultLessonId ?? (lessonState.pool.isNotEmpty ? lessonState.pool.first.id : null);
                  final bool isAlternative = defaultId != null && lesson.id != defaultId;
                  final Lesson? defaultLesson = defaultId != null && lessonState.pool.isNotEmpty
                      ? lessonState.pool.firstWhere((l) => l.id == defaultId, orElse: () => lessonState.pool.first)
                      : null;

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
                          if (lessonState.pool.length > 1) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'TODAY\'S PERSPECTIVES',
                                          style: AppTypography.caption.copyWith(
                                            letterSpacing: 1.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textMuted,
                                            fontSize: 10,
                                          ),
                                        ),
                                        Text(
                                          '${lessonState.pool.length} Topics',
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    child: Row(
                                      children: lessonState.pool.map((pLesson) {
                                        final isSelected = pLesson.id == lesson.id;
                                        final isPrimaryLesson = pLesson.id == defaultId;
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: ChoiceChip(
                                            selected: isSelected,
                                            avatar: isPrimaryLesson
                                                ? Icon(
                                                    Icons.auto_awesome,
                                                    size: 14,
                                                    color: isSelected ? Colors.white : AppColors.accent,
                                                  )
                                                : (isSelected
                                                    ? const Icon(
                                                        Icons.check_rounded,
                                                        size: 14,
                                                        color: Colors.white,
                                                      )
                                                    : null),
                                            label: Text(
                                              isPrimaryLesson ? '${pLesson.category} (Daily Pick)' : pLesson.category,
                                              style: TextStyle(
                                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                                fontSize: 12,
                                              ),
                                            ),
                                            backgroundColor: AppColors.surface,
                                            selectedColor: AppColors.primary,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                              side: BorderSide(
                                                color: isSelected ? AppColors.primary : AppColors.border,
                                                width: isSelected ? 1.5 : 1,
                                              ),
                                            ),
                                            onSelected: (_) {
                                              if (!isSelected) {
                                                context.read<LessonBloc>().add(SwitchPerspective(pLesson));
                                              }
                                            },
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            clipBehavior: Clip.hardEdge,
                            child: isAlternative
                                ? Container(
                                    key: const ValueKey('alt_perspective_banner'),
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppColors.primary.withValues(alpha: 0.35),
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.alt_route_rounded,
                                            color: AppColors.primary,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: const Text(
                                                      'ALTERNATIVE PERSPECTIVE',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w700,
                                                        letterSpacing: 0.8,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Flexible(
                                                    child: Text(
                                                      lesson.category,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: AppTypography.uiSemiBold.copyWith(
                                                        color: AppColors.secondary,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                'Exploring an alternative angle from today\'s pool. You can reflect and complete this edition.',
                                                style: AppTypography.caption.copyWith(
                                                  color: AppColors.textSecondary,
                                                  fontSize: 11,
                                                  height: 1.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (defaultLesson != null) ...[
                                          const SizedBox(width: 8),
                                          InkWell(
                                            onTap: () {
                                              context.read<LessonBloc>().add(SwitchPerspective(defaultLesson));
                                            },
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: AppColors.primary.withValues(alpha: 0.3),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.undo_rounded, size: 14, color: AppColors.primary),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Return',
                                                    style: AppTypography.uiSemiBold.copyWith(
                                                      color: AppColors.primary,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  )
                                : const SizedBox(width: double.infinity, height: 0),
                          ),
                          KeyedSubtree(
                            key: ValueKey(lesson.id),
                            child: EditorialCard(
                              lesson: lesson,
                              isAlternative: isAlternative,
                            ),
                          ),
                          const SizedBox(height: 24),
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
                return _buildWelcomeInstance(context);
              },
            );
          },
        ),
      ),
    );
  }
}
