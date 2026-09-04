import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/lesson_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../logic/lesson/lesson_bloc.dart';
import '../archive/archive_screen.dart';
import '../daily_lesson/daily_lesson_screen.dart';
import '../saved/saved_screen.dart';
import '../settings/settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final GlobalKey<ArchiveScreenState> _archiveKey = GlobalKey<ArchiveScreenState>();
  final GlobalKey<SavedScreenState> _savedKey = GlobalKey<SavedScreenState>();

  Widget _buildTabItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.secondary.withValues(alpha: 0.45),
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontSize: 10,
                letterSpacing: 0.3,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.secondary.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  BlocProvider<LessonBloc>(
                    create: (context) => LessonBloc(
                      lessonRepository: context.read<LessonRepository>(),
                      userRepository: context.read<UserRepository>(),
                    ),
                    child: const DailyLessonScreen(),
                  ),
                  BlocProvider<LessonBloc>(
                    create: (context) => LessonBloc(
                      lessonRepository: context.read<LessonRepository>(),
                      userRepository: context.read<UserRepository>(),
                    ),
                    child: ArchiveScreen(key: _archiveKey),
                  ),
                  BlocProvider<LessonBloc>(
                    create: (context) => LessonBloc(
                      lessonRepository: context.read<LessonRepository>(),
                      userRepository: context.read<UserRepository>(),
                    ),
                    child: SavedScreen(key: _savedKey),
                  ),
                  const SettingsScreen(),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTabItem(0, Icons.lightbulb_outline_rounded, 'Today'),
                      _buildTabItem(1, Icons.history_rounded, 'Archive'),
                      _buildTabItem(2, Icons.bookmark_outline_rounded, 'Saved'),
                      _buildTabItem(3, Icons.settings_rounded, 'Settings'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
