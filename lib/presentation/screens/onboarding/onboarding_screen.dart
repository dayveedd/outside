import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;

  const OnboardingScreen({
    super.key,
    required this.onGetStarted,
    required this.onSignIn,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPageData> _pages = const [
    _OnboardingPageData(
      tag: 'One idea a day',
      tagColor: AppColors.primary,
      imagePath: 'images/outside3.jpg',
      canvasColor: Color(0xFFF3F1E2),
      title: 'Step Outside Your Echo Chamber',
      description:
          'Every day at midnight UTC, receive one hand-curated lesson across philosophy, science, history, and human culture.',
    ),
    _OnboardingPageData(
      tag: 'Two perspectives',
      tagColor: AppColors.accent,
      imagePath: 'images/outside2.jpg',
      canvasColor: Color(0xFFF5F5F5),
      title: 'See Every Idea From Every Angle',
      description:
          'Toggle between opposing viewpoints and challenging counter-arguments. Sharpen your mind by questioning conventional consensus.',
    ),
    _OnboardingPageData(
      tag: 'Daily reflection',
      tagColor: Color(0xFF10B981),
      imagePath: 'images/outside6.jpg',
      canvasColor: Color(0xFFFFFFFF),
      title: 'Reflect, Journal & Grow',
      description:
          'Record personal insights after every lesson, build an unbroken daily streak, and unlock a timeless historical archive.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      widget.onGetStarted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'images/OUTSIDE.png',
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'OUTSIDE.',
                        style: AppTypography.uiSemiBold.copyWith(
                          color: AppColors.primary,
                          fontSize: 18,
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: widget.onGetStarted,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: Text(
                      'Skip',
                      style: AppTypography.uiMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final screenHeight = MediaQuery.sizeOf(context).height;
                                final cardSize = (screenHeight * 0.28).clamp(190.0, 250.0);
                                return Container(
                                  width: cardSize,
                                  height: cardSize,
                                  decoration: BoxDecoration(
                                    color: page.canvasColor,
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: page.tagColor.withValues(alpha: 0.08),
                                        blurRadius: 28,
                                        offset: const Offset(0, 10),
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(28),
                                    child: Image.asset(
                                      page.imagePath,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 28),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: page.tagColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    page.tag,
                                    style: AppTypography.caption.copyWith(
                                      color: const Color(0xFF374151),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              page.title,
                              textAlign: TextAlign.center,
                              style: AppTypography.h2.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 26,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              page.description,
                              textAlign: TextAlign.center,
                              style: AppTypography.subtitle.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (index) {
                      final isSelected = _currentPage == index;
                      return GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: isSelected ? 26 : 8,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.secondary : const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentPage == _pages.length - 1 ? 'Get Started' : 'Continue',
                          style: AppTypography.uiSemiBold.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: widget.onSignIn,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: AppTypography.uiMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: 'Sign In',
                            style: AppTypography.uiSemiBold.copyWith(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final String tag;
  final Color tagColor;
  final String imagePath;
  final Color canvasColor;
  final String title;
  final String description;

  const _OnboardingPageData({
    required this.tag,
    required this.tagColor,
    required this.imagePath,
    required this.canvasColor,
    required this.title,
    required this.description,
  });
}
