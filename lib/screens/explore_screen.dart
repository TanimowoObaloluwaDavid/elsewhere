import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/motion.dart';
import '../core/palette.dart';
import '../core/routes.dart';
import '../core/text_styles.dart';
import '../data/places.dart';
import '../models/place.dart';
import '../widgets/editorial.dart';
import '../widgets/place_cards.dart';
import 'place_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, required this.onExploreFilms});

  final VoidCallback onExploreFilms;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  static const _regions = [
    'All',
    'Nordic',
    'Latin America',
    'Asia',
    'Africa',
    'Europe',
  ];

  final _search = TextEditingController();
  final _random = math.Random();
  String _region = 'All';
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Place> get _filtered {
    final q = _query.trim().toLowerCase();
    return places
        .where((place) {
          final regionMatch = _region == 'All' || place.region == _region;
          if (!regionMatch) return false;
          if (q.isEmpty) return true;
          final haystack = [
            place.name,
            place.country,
            place.region,
            place.title,
            place.lede,
            ...place.keywords,
          ].join(' ').toLowerCase();
          return haystack.contains(q);
        })
        .toList(growable: false);
  }

  void _openPlace(Place place) {
    Navigator.of(context).push(
      softRoute(PlaceScreen(place: place, heroTag: 'explore-${place.id}')),
    );
  }

  void _surpriseMe() {
    final pool = _filtered.isEmpty ? places : _filtered;
    final place = pool[_random.nextInt(pool.length)];
    _openPlace(place);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final hPad = width >= 760 ? 44.0 : 24.0;
    final results = _filtered;

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
                child: Row(
                  children: [
                    const Kicker('The atlas'),
                    const Spacer(),
                    Text(
                      '${places.length.toString().padLeft(2, '0')} PLACES',
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
                      Text(
                        'Everywhere,\nslowly.',
                        style: AppText.display(42, height: 0.99),
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 340),
                        child: Text(
                          'Search by country, mood, or weather. The atlas is small on purpose.',
                          style: AppText.body(13.5, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, 22, hPad, 0),
                child: _SearchField(
                  controller: _search,
                  query: _query,
                  onChanged: (value) => setState(() => _query = value),
                  onClear: () {
                    _search.clear();
                    setState(() => _query = '');
                  },
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  itemCount: _regions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final region = _regions[index];
                    final selected = region == _region;
                    return InkWell(
                      onTap: () => setState(() => _region = region),
                      borderRadius: BorderRadius.circular(30),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: selected ? Palette.ink : Palette.paperBright,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: selected ? Palette.ink : Palette.line,
                            width: 0.8,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            region.toUpperCase(),
                            style: AppText.label(
                              8.5,
                              color: selected ? Palette.cream : Palette.inkSoft,
                              tracking: 1.2,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, 18, hPad, 6),
                child: Row(
                  children: [
                    Text(
                      '${results.length.toString().padLeft(2, '0')} ${results.length == 1 ? 'PLACE' : 'PLACES'}',
                      style: AppText.label(
                        8.5,
                        color: Palette.inkFaint,
                        tracking: 1.4,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: _surpriseMe,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome_outlined,
                              size: 14,
                              color: Palette.clay,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'SURPRISE ME',
                              style: AppText.label(
                                8.5,
                                color: Palette.clay,
                                tracking: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: results.isEmpty
                    ? _EmptyAtlas(
                        query: _query,
                        onClear: () {
                          _search.clear();
                          setState(() {
                            _query = '';
                            _region = 'All';
                          });
                        },
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 36),
                        itemCount: results.length + 1,
                        itemBuilder: (context, index) {
                          if (index == results.length) {
                            if (_query.isNotEmpty || _region != 'All') {
                              return const SizedBox(height: 8);
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: _FilmCrossLink(
                                onTap: widget.onExploreFilms,
                              ),
                            );
                          }
                          final place = results[index];
                          return Reveal(
                            delay: Duration(milliseconds: 30 * index),
                            child: PlaceListRow(
                              place: place,
                              heroTag: 'explore-${place.id}',
                              showDivider: index != results.length - 1,
                              onTap: () => _openPlace(place),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Palette.paperBright,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Palette.line, width: 0.9),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        cursorColor: Palette.clay,
        style: AppText.body(14, color: Palette.ink, height: 1.2),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: 'Search places, moods, weather',
          hintStyle: AppText.body(13.5, color: Palette.inkFaint, height: 1.2),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(Icons.search_rounded, size: 20, color: Palette.inkSoft),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 46,
            minHeight: 20,
          ),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  onPressed: onClear,
                  splashRadius: 18,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Palette.inkFaint,
                  ),
                ),
          contentPadding: const EdgeInsets.only(right: 16),
        ),
      ),
    );
  }
}

class _EmptyAtlas extends StatelessWidget {
  const _EmptyAtlas({required this.query, required this.onClear});

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(36, 34, 36, 36),
      child: Column(
        children: [
          Opacity(
            opacity: 0.5,
            child: SunMark(size: 76, color: Palette.clay, stroke: 1),
          ),
          const SizedBox(height: 24),
          Text(
            'Nothing here yet',
            textAlign: TextAlign.center,
            style: AppText.display(27, height: 1.05),
          ),
          const SizedBox(height: 10),
          Text(
            query.isEmpty
                ? 'This corner of the atlas is still being written.'
                : 'No place matches “$query”. Try “desert”, “rain”, or “sea”.',
            textAlign: TextAlign.center,
            style: AppText.body(13, height: 1.55),
          ),
          const SizedBox(height: 18),
          TextButton(
            onPressed: onClear,
            child: Text(
              'Clear the search',
              style: AppText.ui(
                12.5,
                color: Palette.clay,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilmCrossLink extends StatelessWidget {
  const _FilmCrossLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Material(
        color: Palette.paperWarm,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const SunMark(size: 34, color: Palette.clay, stroke: 1),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'The atlas, in motion',
                        style: AppText.display(20, height: 1.0),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Five silent field films. No narration, no hurry.',
                        style: AppText.body(12, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Palette.inkSoft,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
