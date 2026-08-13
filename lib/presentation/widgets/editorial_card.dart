import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/lesson.dart';

class EditorialCard extends StatelessWidget {
  final Lesson lesson;

  const EditorialCard({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: AppDurations.slide,
      curve: Curves.easeOutQuad,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Card(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppShapes.cardBorderRadius,
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      lesson.category.toUpperCase(),
                      style: AppTypography.uiSemiBold.copyWith(
                        color: AppColors.primary,
                        fontSize: 11,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.menu_book_rounded, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${lesson.readTimeMinutes} min read',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Provocative Hook
              Text(
                lesson.hook,
                style: AppTypography.h1.copyWith(
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 32),
              
              const Divider(),
              const SizedBox(height: 24),

              // The Idea Section
              _buildSectionTitle('THE IDEA'),
              const SizedBox(height: 8),
              Text(
                lesson.idea,
                style: AppTypography.bodyLarge,
              ),
              const SizedBox(height: 32),

              // Why It Matters Section (Blockquote style)
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: AppColors.accent, width: 4),
                  ),
                  color: Color(0xFFFEFBF3), // Very soft warm highlight
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                margin: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('WHY IT MATTERS', color: AppColors.accent),
                    const SizedBox(height: 8),
                    Text(
                      lesson.whyItMatters,
                      style: AppTypography.body.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // Everyday Example Section
              _buildSectionTitle('EVERYDAY EXAMPLE'),
              const SizedBox(height: 8),
              Text(
                lesson.everydayExample,
                style: AppTypography.body,
              ),
              const SizedBox(height: 32),

              // Explore More Section
              if (lesson.exploreMore.isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: 24),
                _buildSectionTitle('EXPLORE MORE'),
                const SizedBox(height: 12),
                ...lesson.exploreMore.map((link) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.arrow_right_alt, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          link,
                          style: AppTypography.uiMedium.copyWith(
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Color color = AppColors.textSecondary}) {
    return Text(
      title,
      style: AppTypography.uiSemiBold.copyWith(
        color: color,
        fontSize: 12,
        letterSpacing: 2.0,
      ),
    );
  }
}
