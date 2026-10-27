import 'package:flutter/material.dart';

import '../core/palette.dart';
import '../core/text_styles.dart';
import '../models/place.dart';
import 'editorial.dart';

class PlayGlyph extends StatelessWidget {
  const PlayGlyph({super.key, this.size = 46, this.dark = false});

  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dark ? Palette.ink : Palette.cream,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Palette.ink.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        Icons.play_arrow_rounded,
        color: dark ? Palette.cream : Palette.ink,
        size: size * 0.48,
      ),
    );
  }
}

class FeaturedFilmCard extends StatelessWidget {
  const FeaturedFilmCard({
    super.key,
    required this.film,
    required this.onTap,
    this.height = 218,
  });

  final FieldFilm film;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Play ${film.title}',
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AssetPhoto(asset: film.poster),
                const PhotoScrim(top: 0.3, bottom: 0.95),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Tag(
                    'NOW SHOWING',
                    color: Palette.cream,
                    background: Palette.ink.withValues(alpha: 0.40),
                    border: Palette.cream.withValues(alpha: 0.2),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Tag(
                    film.duration,
                    color: Palette.cream,
                    background: Palette.ink.withValues(alpha: 0.40),
                    border: Palette.cream.withValues(alpha: 0.2),
                  ),
                ),
                Center(child: PlayGlyph(size: 56)),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        film.title,
                        style: AppText.display(27, color: Palette.cream),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${film.location}  ·  ${film.year}',
                        style: AppText.label(
                          9,
                          color: Palette.cream.withValues(alpha: 0.75),
                          tracking: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FilmRow extends StatelessWidget {
  const FilmRow({
    super.key,
    required this.film,
    required this.onTap,
    this.showDivider = true,
  });

  final FieldFilm film;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 116,
                    height: 74,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AssetPhoto(asset: film.poster),
                        Center(child: PlayGlyph(size: 30)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(film.title, style: AppText.display(21, height: 1.0)),
                      const SizedBox(height: 5),
                      Text(
                        film.location,
                        style: AppText.label(
                          8.5,
                          color: Palette.inkFaint,
                          tracking: 1.1,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        film.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(12, height: 1.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  film.duration,
                  style: AppText.label(9, color: Palette.inkSoft),
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
