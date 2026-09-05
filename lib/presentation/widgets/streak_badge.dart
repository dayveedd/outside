import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class StreakBadge extends StatelessWidget {
  final int streakCount;
  final VoidCallback? onTap;

  const StreakBadge({
    super.key,
    required this.streakCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasStreak = streakCount > 0;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: hasStreak ? AppColors.accent.withValues(alpha: 0.1) : AppColors.border.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasStreak ? AppColors.accent : AppColors.border,
            width: 1,
          ),
        ),
        child: AnimatedSwitcher(
          duration: AppDurations.scale,
          child: Row(
            key: ValueKey<int>(streakCount),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasStreak ? Icons.local_fire_department : Icons.local_fire_department_outlined,
                color: hasStreak ? AppColors.accent : AppColors.textMuted,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                '$streakCount',
                style: AppTypography.uiSemiBold.copyWith(
                  color: hasStreak ? AppColors.accent : AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                'days',
                style: AppTypography.caption.copyWith(
                  color: hasStreak ? AppColors.accent.withValues(alpha: 0.8) : AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
