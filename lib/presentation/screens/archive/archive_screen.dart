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

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => ArchiveScreenState();
}

class ArchiveScreenState extends State<ArchiveScreen> {
  String? _userId;
  int _selectedTab = 0;

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
      context.read<LessonBloc>().add(LoadArchive(_userId!));
    }
  }

  Future<void> refresh() async {
    context.read<SubscriptionBloc>().add(CheckSubscriptionStatus());
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _userId = authState.user.uid;
      context.read<LessonBloc>().add(LoadArchive(_userId!));
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
        if (authState is Authenticated && _userId == null) {
          _userId = authState.user.uid;
          context.read<LessonBloc>().add(LoadArchive(_userId!));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'ARCHIVE',
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
              builder: (context, lessonState) {
                if (lessonState is LessonInitial || lessonState is LessonLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (lessonState is LessonError) {
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
                                Text('Error: ${lessonState.message}'),
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
                } else if (lessonState is ArchiveLoaded) {
                  final allLessons = lessonState.lessons;
                  final activities = lessonState.activities;
                  final todayStr = LessonRepository.formatDate(DateTime.now());

                  final completedLessons = allLessons.where((l) {
                    final act = activities[l.id];
                    return act?.isRead == true;
                  }).toList();

                  final displayLessons = _selectedTab == 0 ? allLessons : completedLessons;

                  final Map<String, int> pastIndices = {};
                  int pCounter = 0;
                  for (var l in allLessons) {
                    if (l.publishDate != todayStr) {
                      pastIndices[l.id] = pCounter++;
                    }
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedTab = 0),
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: _selectedTab == 0
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.05),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'All Editions (${allLessons.length})',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: _selectedTab == 0 ? FontWeight.w700 : FontWeight.w500,
                                          color: _selectedTab == 0 ? AppColors.secondary : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedTab = 1),
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: _selectedTab == 1
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.05),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Completed (${completedLessons.length})',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: _selectedTab == 1 ? FontWeight.w700 : FontWeight.w500,
                                          color: _selectedTab == 1 ? AppColors.secondary : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: displayLessons.isEmpty
                            ? RefreshIndicator(
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
                                              Icon(
                                                _selectedTab == 0
                                                    ? Icons.history_edu_rounded
                                                    : Icons.edit_note_rounded,
                                                size: 52,
                                                color: AppColors.textMuted,
                                              ),
                                              const SizedBox(height: 18),
                                              Text(
                                                _selectedTab == 0
                                                    ? 'The Archive is Empty'
                                                    : 'No Completed Journals Yet',
                                                style: AppTypography.uiSemiBold.copyWith(
                                                  fontSize: 16,
                                                  color: AppColors.secondary,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                _selectedTab == 0
                                                    ? 'Daily lessons will appear here as they are published.'
                                                    : 'Complete your daily journal reflection on the home screen to build your personal reflection journal.',
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
                              )
                            : RefreshIndicator(
                                onRefresh: refresh,
                                child: ListView.separated(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                                  itemCount: displayLessons.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                                  itemBuilder: (context, index) {
                                    final lesson = displayLessons[index];
                                    final activity = activities[lesson.id];
                                    final isRead = activity?.isRead ?? false;
                                    final isSaved = activity?.isSaved ?? false;
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
                                                      color: isToday ? AppColors.accent : AppColors.textSecondary,
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
                                                      if (isSaved)
                                                        const Padding(
                                                          padding: EdgeInsets.only(right: 8.0),
                                                          child: Icon(Icons.bookmark,
                                                              size: 16, color: AppColors.primary),
                                                        ),
                                                      if (isRead)
                                                        const Padding(
                                                          padding: EdgeInsets.only(right: 8.0),
                                                          child: Icon(Icons.check_circle,
                                                              size: 16, color: AppColors.success),
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
                                              if (_selectedTab == 1 &&
                                                  activity != null &&
                                                  activity.reflectionNote != null &&
                                                  activity.reflectionNote!.isNotEmpty) ...[
                                                const SizedBox(height: 14),
                                                Container(
                                                  width: double.infinity,
                                                  padding: const EdgeInsets.all(14),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF8FAFC),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: AppColors.border),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          const Icon(Icons.edit_note_rounded,
                                                              size: 16, color: AppColors.primary),
                                                          const SizedBox(width: 6),
                                                          Text(
                                                            'YOUR REFLECTION',
                                                            style: AppTypography.caption.copyWith(
                                                              color: AppColors.primary,
                                                              fontWeight: FontWeight.bold,
                                                              letterSpacing: 1.2,
                                                              fontSize: 10,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        activity.reflectionNote ?? '',
                                                        style: AppTypography.body.copyWith(
                                                          fontSize: 13,
                                                          fontStyle: FontStyle.italic,
                                                          color: AppColors.textPrimary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(height: 14),
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
                              ),
                      ),
                    ],
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
