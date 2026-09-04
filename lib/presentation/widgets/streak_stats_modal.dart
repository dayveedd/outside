import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_streak.dart';

class StreakStatsModal extends StatefulWidget {
  final UserStreak streak;

  const StreakStatsModal({super.key, required this.streak});

  static void show(BuildContext context, UserStreak streak) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StreakStatsModal(streak: streak),
    );
  }

  @override
  State<StreakStatsModal> createState() => _StreakStatsModalState();
}

class _StreakStatsModalState extends State<StreakStatsModal> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSharing = false;

  void _shareTextOnly() {
    final String streakText =
        '🔥 I am on a ${widget.streak.currentStreak}-day learning streak on Outside! '
        'Expanding my perspectives one idea at a time. Step outside your bubble.';
    Share.share(streakText, subject: 'My Outside Streak');
  }

  Future<void> _shareStreakCardImage() async {
    setState(() => _isSharing = true);
    try {
      final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/outside_streak_${widget.streak.currentStreak}d.png');
          await file.writeAsBytes(byteData.buffer.asUint8List());

          await Share.shareXFiles(
            [XFile(file.path)],
            text: '🔥 I am on a ${widget.streak.currentStreak}-day learning streak on Outside! Step outside your bubble.',
            subject: 'My Outside Streak',
          );
          return;
        }
      }
      _shareTextOnly();
    } catch (_) {
      _shareTextOnly();
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int current = widget.streak.currentStreak;
    final int longest = widget.streak.longestStreak;
    final todayWeekday = DateTime.now().weekday;
    final List<String> dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppShapes.bottomSheetRadius),
            topRight: Radius.circular(AppShapes.bottomSheetRadius),
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: 20),
              RepaintBoundary(
                key: _cardKey,
                child: Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.secondary, Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppShapes.cardRadius),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
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
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'DAILY STREAK',
                              style: AppTypography.uiSemiBold.copyWith(
                                color: AppColors.accent,
                                fontSize: 9,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        current == 1 ? '1 DAY STREAK' : '$current DAYS STREAK',
                        style: AppTypography.display.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        current >= 3
                            ? 'Incredible momentum! You are expanding your horizons day after day.'
                            : 'Stepping outside the algorithmic echo chamber, one daily spark at a time.',
                        style: AppTypography.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'CURRENT',
                                    style: AppTypography.caption.copyWith(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 10,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$current ${current == 1 ? 'Day' : 'Days'}',
                                    style: AppTypography.uiSemiBold.copyWith(
                                      color: AppColors.accent,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'BEST RECORD',
                                    style: AppTypography.caption.copyWith(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 10,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$longest ${longest == 1 ? 'Day' : 'Days'}',
                                    style: AppTypography.uiSemiBold.copyWith(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.blur_on_rounded, color: AppColors.accent, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'One idea a day • outside',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WEEKLY RHYTHM',
                      style: AppTypography.caption.copyWith(
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (i) {
                        final dayIndex = i + 1;
                        final isToday = dayIndex == todayWeekday;
                        final isCompleted = current > 0 && dayIndex <= todayWeekday && (todayWeekday - dayIndex) < current;

                        return Column(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCompleted
                                    ? const Color(0xFFF59E0B)
                                    : isToday
                                        ? const Color(0xFFFEF3C7)
                                        : Colors.white,
                                border: Border.all(
                                  color: isCompleted
                                      ? const Color(0xFFF59E0B)
                                      : isToday
                                          ? const Color(0xFFF59E0B)
                                          : AppColors.border,
                                  width: isToday ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: isCompleted
                                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                                    : Text(
                                        dayLabels[i],
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                                          color: isToday ? const Color(0xFFB45309) : AppColors.textMuted,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dayLabels[i],
                              style: AppTypography.caption.copyWith(
                                fontSize: 10,
                                fontWeight: isToday ? FontWeight.w800 : FontWeight.w400,
                                color: isToday ? AppColors.textPrimary : AppColors.textMuted,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isSharing ? null : _shareStreakCardImage,
                icon: _isSharing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.photo_library_rounded),
                label: Text(_isSharing ? 'Generating Card...' : 'Share Streak Card'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _shareTextOnly();
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text('Share Text Only'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}
