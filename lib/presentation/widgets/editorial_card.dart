import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/lesson.dart';

class EditorialCard extends StatelessWidget {
  final Lesson lesson;
  final bool isAlternative;

  const EditorialCard({
    super.key,
    required this.lesson,
    this.isAlternative = false,
  });

  Future<void> _launchLink(String link) async {
    final trimmed = link.trim();
    final urlString = trimmed.startsWith('http://') || trimmed.startsWith('https://')
        ? trimmed
        : 'https://$trimmed';
    final uri = Uri.tryParse(urlString);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

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
          side: BorderSide(
            color: isAlternative ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
            width: isAlternative ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
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
                      if (isAlternative) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.alt_route_rounded,
                                size: 11,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'ALT ANGLE',
                                style: AppTypography.uiSemiBold.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 9,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
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
              Text(
                lesson.hook,
                style: AppTypography.h1.copyWith(
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 24),
              _buildSectionTitle('THE IDEA'),
              const SizedBox(height: 8),
              Text(
                lesson.idea,
                style: AppTypography.bodyLarge,
              ),
              const SizedBox(height: 32),
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: AppColors.accent, width: 4),
                  ),
                  color: Color(0xFFFEFBF3),
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
              _buildSectionTitle('EVERYDAY EXAMPLE'),
              const SizedBox(height: 8),
              Text(
                lesson.everydayExample,
                style: AppTypography.body,
              ),
              const SizedBox(height: 32),
              if (lesson.exploreMore.isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: 24),
                _buildSectionTitle('EXPLORE MORE'),
                const SizedBox(height: 12),
                ...lesson.exploreMore.map((link) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () => _launchLink(link),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
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
                    ),
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
