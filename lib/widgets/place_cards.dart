import 'package:flutter/material.dart';

import '../core/palette.dart';
import '../core/text_styles.dart';
import '../models/place.dart';
import 'editorial.dart';

class _Pressable extends StatefulWidget {
  const _Pressable({required this.onTap, required this.child, this.label});

  final VoidCallback onTap;
  final Widget child;
  final String? label;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.985 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

class FeaturedPlaceCard extends StatelessWidget {
  const FeaturedPlaceCard({
    super.key,
    required this.place,
    required this.onTap,
    this.heroTag,
  });

  final Place place;
  final VoidCallback onTap;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _hero(child: AssetPhoto(asset: place.hero)),
          const PhotoScrim(top: 0.45, bottom: 0.92),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Palette.cream.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Palette.cream.withValues(alpha: 0.22),
                          width: 0.7,
                        ),
                      ),
                      child: Text(
                        'FIELD NOTE N° ${place.noteNumber}',
                        style: AppText.label(
                          9,
                          color: Palette.cream.withValues(alpha: 0.9),
                          tracking: 1.3,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.wb_sunny_outlined,
                      size: 17,
                      color: Palette.cream.withValues(alpha: 0.7),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '${place.country} · ${place.region}'.toUpperCase(),
                  style: AppText.label(
                    9.5,
                    color: Palette.cream.withValues(alpha: 0.78),
                    tracking: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  place.title,
                  style: AppText.display(33, color: Palette.cream, height: 1.0),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      '${place.days}  ·  ${place.season}',
                      style: AppText.label(
                        9,
                        color: Palette.cream.withValues(alpha: 0.68),
                        tracking: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Palette.cream.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_outward_rounded,
                        size: 18,
                        color: Palette.ink,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return _Pressable(
      label: '${place.name}: ${place.title}',
      onTap: onTap,
      child: AspectRatio(aspectRatio: 0.78, child: image),
    );
  }

  Widget _hero({required Widget child}) {
    if (heroTag == null) return child;
    return Hero(tag: heroTag!, child: child);
  }
}

class SmallPlaceCard extends StatelessWidget {
  const SmallPlaceCard({
    super.key,
    required this.place,
    required this.onTap,
    this.heroTag,
    this.width = 158,
    this.showCaption = true,
  });

  final Place place;
  final VoidCallback onTap;
  final String? heroTag;
  final double width;
  final bool showCaption;

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _hero(AssetPhoto(asset: place.square)),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Palette.ink.withValues(alpha: 0.58),
                ],
                stops: const [0.55, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 12,
            child: Text(
              place.noteNumber,
              style: AppText.label(
                9.5,
                color: Palette.cream.withValues(alpha: 0.85),
                tracking: 1.2,
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Text(
              place.country.toUpperCase(),
              style: AppText.label(
                8.5,
                color: Palette.cream.withValues(alpha: 0.72),
                tracking: 1.2,
              ),
            ),
          ),
        ],
      ),
    );

    return _Pressable(
      label: '${place.name}, ${place.country}',
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(aspectRatio: 0.76, child: image),
            if (showCaption) ...[
              const SizedBox(height: 12),
              Text(place.name, style: AppText.display(21, height: 1.0)),
              const SizedBox(height: 4),
              Text(
                '${place.region} · ${place.days.toLowerCase()}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.label(
                  8.5,
                  color: Palette.inkFaint,
                  tracking: 1.1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _hero(Widget child) {
    if (heroTag == null) return child;
    return Hero(tag: heroTag!, child: child);
  }
}

class PlaceListRow extends StatelessWidget {
  const PlaceListRow({
    super.key,
    required this.place,
    required this.onTap,
    this.heroTag,
    this.trailing,
    this.showDivider = true,
  });

  final Place place;
  final VoidCallback onTap;
  final String? heroTag;
  final Widget? trailing;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 92,
        height: 112,
        child: heroTag == null
            ? AssetPhoto(asset: place.square)
            : Hero(
                tag: heroTag!,
                child: AssetPhoto(asset: place.square),
              ),
      ),
    );

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                image,
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${place.noteNumber} · ${place.region}'.toUpperCase(),
                        style: AppText.label(
                          8.5,
                          color: Palette.clay,
                          tracking: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(place.name, style: AppText.display(25, height: 1.0)),
                      const SizedBox(height: 5),
                      Text(
                        place.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(12.5, height: 1.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${place.season}  ·  ${place.days}',
                        style: AppText.label(
                          8.5,
                          color: Palette.inkFaint,
                          tracking: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing ??
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: Palette.inkFaint,
                    ),
              ],
            ),
          ),
        ),
        if (showDivider) const Hairline(),
      ],
    );
  }
}

class SavedPlaceRow extends StatelessWidget {
  const SavedPlaceRow({
    super.key,
    required this.place,
    required this.onTap,
    required this.onRemove,
  });

  final Place place;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Palette.paperBright,
        borderRadius: BorderRadius.circular(22),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 76,
                  height: 94,
                  child: AssetPhoto(asset: place.square),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${place.country} · ${place.region}'.toUpperCase(),
                      style: AppText.label(
                        8.5,
                        color: Palette.clay,
                        tracking: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(place.name, style: AppText.display(23, height: 1.0)),
                    const SizedBox(height: 5),
                    Text(
                      place.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(12, height: 1.3),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                tooltip: 'Remove from journal',
                icon: const Icon(
                  Icons.bookmark_rounded,
                  size: 20,
                  color: Palette.clay,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
