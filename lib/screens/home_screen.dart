import 'package:flutter/material.dart';

import '../core/motion.dart';
import '../core/palette.dart';
import '../core/routes.dart';
import '../core/text_styles.dart';
import '../data/films.dart';
import '../data/places.dart';
import '../models/place.dart';
import '../widgets/editorial.dart';
import '../widgets/film_cards.dart';
import '../widgets/place_cards.dart';
import 'film_player_screen.dart';
import 'place_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onExplore,
    required this.onFilms,
    required this.onOpenAbout,
  });

  final VoidCallback onExplore;
  final VoidCallback onFilms;
  final VoidCallback onOpenAbout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    final assets = <String>[
      'assets/images/lofoten_01.jpg',
      for (final place in places.where((p) => p.id != 'lofoten').take(4))
        place.square,
      for (final film in films.take(3)) film.poster,
    ];
    for (final asset in assets) {
      precacheImage(AssetImage(asset), context, onError: (_, _) {});
    }
  }

  void _openPlace(Place place, String tag) {
    Navigator.of(
      context,
    ).push(softRoute(PlaceScreen(place: place, heroTag: tag)));
  }

  void _openFilm(FieldFilm film) {
    Navigator.of(context).push(softRoute(FilmPlayerScreen(film: film)));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final hPad = width >= 760 ? 44.0 : 24.0;
    final recent = places.where((p) => p.id != 'lofoten').take(4).toList();

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 0),
                  child: _Header(onOpenAbout: widget.onOpenAbout),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 34, hPad, 0),
                  child: Reveal(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Kicker('A field journal for slow places'),
                        const SizedBox(height: 18),
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: 'Places that\n'),
                              TextSpan(
                                text: 'stay',
                                style: AppText.serifItalic(
                                  44,
                                  color: Palette.clay,
                                  height: 0.98,
                                ),
                              ),
                              const TextSpan(text: ' with you.'),
                            ],
                          ),
                          style: AppText.display(44, height: 0.98),
                        ),
                        const SizedBox(height: 16),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 330),
                          child: Text(
                            'Eight places, five silent films, and a little room to keep the ones that matter.',
                            style: AppText.body(14, height: 1.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 30, hPad, 0),
                  child: Reveal(
                    delay: const Duration(milliseconds: 100),
                    child: FeaturedPlaceCard(
                      place: places.first,
                      heroTag: 'home-featured-${places.first.id}',
                      onTap: () => _openPlace(
                        places.first,
                        'home-featured-${places.first.id}',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 44),
                SectionHeader(
                  title: 'Recently collected',
                  action: 'The atlas',
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  onAction: widget.onExplore,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 264,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    itemCount: recent.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final place = recent[index];
                      return Reveal(
                        delay: Duration(milliseconds: 60 * index),
                        child: SmallPlaceCard(
                          place: place,
                          heroTag: 'home-recent-${place.id}',
                          onTap: () =>
                              _openPlace(place, 'home-recent-${place.id}'),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 44),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: const Reveal(child: _EditorNote()),
                ),
                const SizedBox(height: 44),
                SectionHeader(
                  title: 'Field films',
                  action: 'All films',
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  onAction: widget.onFilms,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 206,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    itemCount: films.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final film = films[index];
                      return Reveal(
                        delay: Duration(milliseconds: 60 * index),
                        child: SizedBox(
                          width: 305,
                          child: FeaturedFilmCard(
                            film: film,
                            height: 206,
                            onTap: () => _openFilm(film),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 50),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: _Closing(onExplore: widget.onExplore),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onOpenAbout});

  final VoidCallback onOpenAbout;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SunMark(size: 20, color: Palette.clay),
        const SizedBox(width: 9),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'elsewhere',
                style: AppText.display(27, height: 1.0),
              ),
              TextSpan(
                text: '.',
                style: AppText.display(27, color: Palette.clay, height: 1.0),
              ),
            ],
          ),
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'ISSUE 07',
              style: AppText.label(8.5, color: Palette.inkSoft, tracking: 1.4),
            ),
            const SizedBox(height: 3),
            Text(
              'OCT 2026',
              style: AppText.label(8, color: Palette.inkFaint, tracking: 1.2),
            ),
          ],
        ),
        const SizedBox(width: 12),
        RoundIconButton(
          icon: Icons.info_outline_rounded,
          size: 38,
          iconSize: 18,
          tooltip: 'About Elsewhere',
          background: Palette.paperBright,
          onTap: onOpenAbout,
        ),
      ],
    );
  }
}

class _EditorNote extends StatelessWidget {
  const _EditorNote();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        color: Palette.paperWarm,
        padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
        child: Stack(
          children: [
            Positioned(
              right: -46,
              bottom: -52,
              child: SunMark(
                size: 172,
                color: Palette.clay.withValues(alpha: 0.14),
                stroke: 1,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Kicker(
                  'From the editor',
                  line: false,
                  color: Palette.clay,
                ),
                const SizedBox(height: 16),
                Text(
                  '“We travel to be reminded that the world is larger than our plans — and softer than our deadlines.”',
                  style: AppText.serifItalic(23, height: 1.26),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(width: 24, height: 1, color: Palette.inkFaint),
                    const SizedBox(width: 10),
                    Text(
                      'ELSEWHERE · ISSUE 07',
                      style: AppText.label(
                        8.5,
                        color: Palette.inkFaint,
                        tracking: 1.3,
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

class _Closing extends StatelessWidget {
  const _Closing({required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Hairline()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SunMark(
                size: 16,
                color: Palette.clay.withValues(alpha: 0.8),
              ),
            ),
            const Expanded(child: Hairline()),
          ],
        ),
        const SizedBox(height: 24),
        Text('End of Issue 07', style: AppText.display(23, height: 1.0)),
        const SizedBox(height: 8),
        Text(
          'The atlas continues when you do.',
          textAlign: TextAlign.center,
          style: AppText.body(12.5, color: Palette.inkFaint, height: 1.5),
        ),
        const SizedBox(height: 18),
        InkWell(
          onTap: onExplore,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Text(
              'OPEN THE ATLAS',
              style: AppText.label(9, color: Palette.clay, tracking: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
