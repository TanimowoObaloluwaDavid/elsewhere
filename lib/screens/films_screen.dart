import 'package:flutter/material.dart';

import '../core/motion.dart';
import '../core/palette.dart';
import '../core/routes.dart';
import '../core/text_styles.dart';
import '../data/films.dart';
import '../models/place.dart';
import '../widgets/editorial.dart';
import '../widgets/film_cards.dart';
import 'film_player_screen.dart';

class FilmsScreen extends StatelessWidget {
  const FilmsScreen({super.key});

  void _openFilm(BuildContext context, FieldFilm film) {
    Navigator.of(context).push(softRoute(FilmPlayerScreen(film: film)));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final hPad = width >= 760 ? 44.0 : 24.0;
    final featured = films.first;
    final rest = films.skip(1).toList();

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
                  child: Row(
                    children: [
                      const Kicker('Field films'),
                      const Spacer(),
                      Text(
                        '${films.length.toString().padLeft(2, '0')} FILMS',
                        style: AppText.label(
                          8.5,
                          color: Palette.inkFaint,
                          tracking: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 0),
                  child: Reveal(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: 'Short films,\n'),
                              TextSpan(
                                text: 'long silences.',
                                style: AppText.serifItalic(
                                  40,
                                  color: Palette.clay,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                          style: AppText.display(40, height: 1.0),
                        ),
                        const SizedBox(height: 12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 340),
                          child: Text(
                            'Silent, slow, and best with headphones and nowhere to be.',
                            style: AppText.body(13.5, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 26, hPad, 0),
                  child: Reveal(
                    delay: const Duration(milliseconds: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FeaturedFilmCard(
                          film: featured,
                          height: 226,
                          onTap: () => _openFilm(context, featured),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Text(
                              'A SILENT FIELD FILM · ${featured.year}',
                              style: AppText.label(
                                8.5,
                                color: Palette.inkFaint,
                                tracking: 1.3,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'NO NARRATION',
                              style: AppText.label(
                                8.5,
                                color: Palette.clay,
                                tracking: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 34),
                SectionHeader(
                  title: 'The reel',
                  action: '${films.length} FILMS',
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: Column(
                    children: [
                      for (var i = 0; i < rest.length; i++)
                        Reveal(
                          delay: Duration(milliseconds: 40 * i),
                          child: FilmRow(
                            film: rest[i],
                            showDivider: i != rest.length - 1,
                            onTap: () => _openFilm(context, rest[i]),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 38),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: const _SilenceCard(),
                ),
                const SizedBox(height: 44),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: Row(
                    children: [
                      const Expanded(child: Hairline()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'ELSEWHERE · THE REEL',
                          style: AppText.label(
                            8,
                            color: Palette.inkFaint,
                            tracking: 1.4,
                          ),
                        ),
                      ),
                      const Expanded(child: Hairline()),
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

class _SilenceCard extends StatelessWidget {
  const _SilenceCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        color: Palette.night,
        padding: const EdgeInsets.fromLTRB(26, 28, 26, 26),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -50,
              child: SunMark(
                size: 150,
                color: Palette.clay.withValues(alpha: 0.35),
                stroke: 1,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '“A good film does not explain a place. It simply leaves the window open.”',
                  style: AppText.serifItalic(
                    22,
                    color: Palette.cream,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(width: 24, height: 1, color: Palette.clay),
                    const SizedBox(width: 10),
                    Text(
                      'ON SILENCE',
                      style: AppText.label(
                        8,
                        color: Palette.cream.withValues(alpha: 0.5),
                        tracking: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
