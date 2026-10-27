import 'package:flutter/material.dart';

import '../core/palette.dart';
import '../core/text_styles.dart';
import '../models/place.dart';
import '../widgets/editorial.dart';

class PhotoViewerScreen extends StatefulWidget {
  const PhotoViewerScreen({
    super.key,
    required this.place,
    this.initialIndex = 0,
  });

  final Place place;
  final int initialIndex;

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.place.gallery;
    return Scaffold(
      backgroundColor: Palette.night,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: images.length,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: InteractiveViewer(
                          minScale: 1,
                          maxScale: 3,
                          child: Image.asset(
                            images[index],
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.place.galleryCaptions[index],
                              style: AppText.serifItalic(
                                18,
                                color: Palette.cream.withValues(alpha: 0.82),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${(index + 1).toString().padLeft(2, '0')} / ${images.length.toString().padLeft(2, '0')}',
                            style: AppText.label(
                              9,
                              color: Palette.cream.withValues(alpha: 0.55),
                              tracking: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            Positioned(
              top: 12,
              left: 16,
              child: RoundIconButton(
                icon: Icons.close_rounded,
                background: Palette.cream.withValues(alpha: 0.14),
                foreground: Palette.cream,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: Text(
                widget.place.name.toUpperCase(),
                style: AppText.label(
                  9,
                  color: Palette.cream.withValues(alpha: 0.55),
                  tracking: 1.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
