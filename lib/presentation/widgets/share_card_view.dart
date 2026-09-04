import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/lesson.dart';

class ShareCardView extends StatefulWidget {
  final Lesson lesson;

  const ShareCardView({super.key, required this.lesson});

  @override
  State<ShareCardView> createState() => _ShareCardViewState();
}

class _ShareCardViewState extends State<ShareCardView> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSharing = false;

  void _shareTextOnly() {
    final String shareText =
        'Outside Daily Lesson • ${widget.lesson.category}\n\n'
        '"${widget.lesson.hook}"\n\n'
        'Read the full concept inside Outside. Step outside your echo chamber.';

    Share.share(shareText, subject: 'Outside: ${widget.lesson.hook}');
  }

  Future<void> _shareCardImage() async {
    setState(() => _isSharing = true);
    try {
      final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/outside_spark_${widget.lesson.id}.png');
          await file.writeAsBytes(byteData.buffer.asUint8List());

          await Share.shareXFiles(
            [XFile(file.path)],
            text: 'Outside Daily Spark • ${widget.lesson.category}\n\n"${widget.lesson.hook}"\n\nStep outside your bubble.',
            subject: 'Outside: ${widget.lesson.hook}',
          );
          if (mounted) Navigator.pop(context);
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
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        decoration: const BoxDecoration(
          color: AppColors.background,
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
              Text(
                'Share Daily Spark',
                style: AppTypography.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Share this visual card to inspire friends and spark deep conversations.',
                style: AppTypography.subtitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              RepaintBoundary(
                key: _cardKey,
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.secondary, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppShapes.cardRadius),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
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
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              widget.lesson.category.toUpperCase(),
                              style: AppTypography.uiSemiBold.copyWith(
                                color: Colors.white,
                                fontSize: 9,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '"${widget.lesson.hook}"',
                        style: AppTypography.h2.copyWith(
                          color: Colors.white,
                          fontSize: 20,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Icon(
                            Icons.blur_on_rounded,
                            color: AppColors.accent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'One daily lesson to step outside your bubble.',
                              style: AppTypography.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSharing ? null : _shareCardImage,
                icon: _isSharing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.photo_library_rounded),
                label: Text(_isSharing ? 'Generating Card...' : 'Share Card Image'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
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
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
