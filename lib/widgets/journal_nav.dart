import 'package:flutter/material.dart';

import '../core/palette.dart';
import '../core/text_styles.dart';

class JournalNav extends StatelessWidget {
  const JournalNav({
    super.key,
    required this.index,
    required this.onTap,
    this.savedCount = 0,
  });

  final int index;
  final ValueChanged<int> onTap;
  final int savedCount;

  static const _items = [
    (Icons.menu_book_outlined, Icons.menu_book_rounded, 'Journal'),
    (Icons.explore_outlined, Icons.explore_rounded, 'Atlas'),
    (
      Icons.play_circle_outline_rounded,
      Icons.play_circle_fill_rounded,
      'Films',
    ),
    (Icons.bookmark_border_rounded, Icons.bookmark_rounded, 'Kept'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: Palette.ink,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Palette.ink.withValues(alpha: 0.22),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: List.generate(_items.length, (i) {
                final item = _items[i];
                final active = i == index;
                final showBadge = i == 3 && savedCount > 0;
                return Expanded(
                  child: InkWell(
                    onTap: () => onTap(i),
                    borderRadius: BorderRadius.circular(18),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              active ? item.$2 : item.$1,
                              size: 21,
                              color: Palette.cream.withValues(
                                alpha: active ? 1 : 0.45,
                              ),
                            ),
                            if (showBadge)
                              Positioned(
                                right: -5,
                                top: -3,
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Palette.clay,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.$3.toUpperCase(),
                          style: AppText.label(
                            8,
                            color: Palette.cream.withValues(
                              alpha: active ? 0.9 : 0.38,
                            ),
                            tracking: 1.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          width: active ? 14 : 0,
                          height: 1.5,
                          color: Palette.clay,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
