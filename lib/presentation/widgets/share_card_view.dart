import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/lesson.dart';

class ShareCardView extends StatelessWidget {
  final Lesson lesson;

  const ShareCardView({super.key, required this.lesson});

  void _shareContent(BuildContext context) {
    final String shareText = 
      'Outside Daily Lesson • ${lesson.category}\n\n'
      '"${lesson.hook}"\n\n'
      'Read the full concept inside Outside. Step outside your echo chamber.';
    
    Share.share(shareText, subject: 'Outside: ${lesson.hook}');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppShapes.bottomSheetRadius),
          topRight: Radius.circular(AppShapes.bottomSheetRadius),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          Text(
            'Share Daily Spark',
            style: AppTypography.h3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Send this provocative prompt to a friend to spark a conversation.',
            style: AppTypography.subtitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // The Social Media Card Preview
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.secondary, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppShapes.cardRadius),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'OUTSIDE.',
                      style: AppTypography.uiSemiBold.copyWith(
                        color: Colors.white,
                        letterSpacing: 2,
                        fontSize: 12,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        lesson.category.toUpperCase(),
                        style: AppTypography.uiSemiBold.copyWith(
                          color: Colors.white,
                          fontSize: 9,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  '"${lesson.hook}"',
                  style: AppTypography.h2.copyWith(
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    const Icon(
                      Icons.blur_on_rounded,
                      color: AppColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'One daily lesson to step outside your bubble.',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Action buttons
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _shareContent(context);
            },
            icon: const Icon(Icons.share_rounded),
            label: const Text('Share Prompt'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
