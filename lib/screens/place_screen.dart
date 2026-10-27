import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/motion.dart';
import '../core/palette.dart';
import '../core/routes.dart';
import '../core/text_styles.dart';
import '../data/films.dart';
import '../data/places.dart';
import '../models/place.dart';
import '../state/journal.dart';
import '../widgets/editorial.dart';
import '../widgets/film_cards.dart';
import '../widgets/place_cards.dart';
import 'film_player_screen.dart';
import 'photo_viewer_screen.dart';

class PlaceScreen extends StatefulWidget {
  const PlaceScreen({super.key, required this.place, this.heroTag});

  final Place place;
  final String? heroTag;

  @override
  State<PlaceScreen> createState() => _PlaceScreenState();
}

class _PlaceScreenState extends State<PlaceScreen> {
  final _scroll = ScrollController();
  late final PageController _gallery = PageController(viewportFraction: 0.84);
  int _galleryIndex = 0;
  bool _showTop = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    final next = _scroll.hasClients && _scroll.offset > 160;
    if (next != _showTop) setState(() => _showTop = next);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _gallery.dispose();
    super.dispose();
  }

  void _openPlace(Place place, String tag) {
    Navigator.of(
      context,
    ).push(softRoute(PlaceScreen(place: place, heroTag: tag)));
  }

  void _openFilm(FieldFilm film) {
    Navigator.of(context).push(softRoute(FilmPlayerScreen(film: film)));
  }

  void _openPhoto(int index) {
    Navigator.of(context).push(
      softRoute(PhotoViewerScreen(place: widget.place, initialIndex: index)),
    );
  }

  Future<void> _toggleSaved(JournalController journal) async {
    HapticFeedback.mediumImpact();
    await journal.toggle(widget.place.id);
    if (!mounted) return;
    final saved = journal.isSaved(widget.place.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            saved ? 'Kept in your journal.' : 'Removed from your journal.',
          ),
        ),
      );
  }

  void _scrollToTop() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
    );
  }

  Place? _placeFor(String id) {
    for (final place in places) {
      if (place.id == id) return place;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final film = filmForPlace(place.id);
    final width = MediaQuery.sizeOf(context).width;
    final hPad = width >= 760 ? 44.0 : 24.0;
    final journal = context.watch<JournalController>();
    final saved = journal.isSaved(place.id);

    return Scaffold(
      backgroundColor: Palette.paper,
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: 472,
            backgroundColor: Palette.paper,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            leadingWidth: 68,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16, top: 6, bottom: 6),
              child: Align(
                alignment: Alignment.topCenter,
                child: RoundIconButton(
                  icon: Icons.arrow_back_rounded,
                  background: Palette.paperBright.withValues(alpha: 0.94),
                  onTap: () => Navigator.of(context).pop(),
                  tooltip: 'Back',
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16, top: 6, bottom: 6),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: RoundIconButton(
                    icon: saved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    background: Palette.paperBright.withValues(alpha: 0.94),
                    foreground: saved ? Palette.clay : Palette.ink,
                    tooltip: saved ? 'Remove from journal' : 'Keep this place',
                    onTap: () => _toggleSaved(journal),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _hero(),
                  const PhotoScrim(top: 0.55, bottom: 0.96),
                  Positioned(
                    left: hPad,
                    right: hPad,
                    bottom: 26,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Kicker(
                          'Field note n° ${place.noteNumber}',
                          color: Palette.cream.withValues(alpha: 0.72),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          place.country.toUpperCase(),
                          style: AppText.label(
                            9.5,
                            color: Palette.cream.withValues(alpha: 0.72),
                            tracking: 1.7,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          place.title,
                          style: AppText.display(
                            37,
                            color: Palette.cream,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '${place.days}  ·  ${place.season}',
                          style: AppText.label(
                            9,
                            color: Palette.cream.withValues(alpha: 0.68),
                            tracking: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 28, hPad, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Hairline(),
                      _MetaStrip(place: place),
                      const Hairline(),
                      const SizedBox(height: 28),
                      Reveal(
                        child: Text(
                          place.lede,
                          style: AppText.serifItalic(21, height: 1.42),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Kicker(
                        'The story',
                        line: false,
                        color: Palette.clay,
                      ),
                      const SizedBox(height: 16),
                      _Story(place: place),
                      const SizedBox(height: 38),
                      _BodyHeading(
                        title: 'Field notes',
                        meta:
                            '${place.notes.length.toString().padLeft(2, '0')} NOTES',
                      ),
                      const SizedBox(height: 4),
                      for (var i = 0; i < place.notes.length; i++)
                        _NoteBlock(
                          index: i + 1,
                          note: place.notes[i],
                          divider: i != place.notes.length - 1,
                        ),
                      const SizedBox(height: 38),
                      _BodyHeading(
                        title: 'The light here',
                        meta:
                            '${(_galleryIndex + 1).toString().padLeft(2, '0')} / ${place.gallery.length.toString().padLeft(2, '0')}',
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 390,
                        child: PageView.builder(
                          controller: _gallery,
                          padEnds: false,
                          itemCount: place.gallery.length,
                          onPageChanged: (value) =>
                              setState(() => _galleryIndex = value),
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _openPhoto(index),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(22),
                                        child: SizedBox.expand(
                                          child: AssetPhoto(
                                            asset: place.gallery[index],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          place.galleryCaptions[index],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppText.serifItalic(
                                            16,
                                            color: Palette.inkSoft,
                                            height: 1.2,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '0${index + 1}',
                                        style: AppText.label(
                                          8.5,
                                          color: Palette.inkFaint,
                                          tracking: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          for (var i = 0; i < place.gallery.length; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 260),
                              margin: const EdgeInsets.only(right: 5),
                              width: i == _galleryIndex ? 18 : 5,
                              height: 3,
                              decoration: BoxDecoration(
                                color: i == _galleryIndex
                                    ? Palette.clay
                                    : Palette.line,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          const Spacer(),
                          Text(
                            'TAP TO OPEN',
                            style: AppText.label(
                              8,
                              color: Palette.inkFaint,
                              tracking: 1.2,
                            ),
                          ),
                        ],
                      ),
                      if (film != null) ...[
                        const SizedBox(height: 40),
                        _BodyHeading(
                          title: 'A field film',
                          meta: film.duration,
                        ),
                        const SizedBox(height: 16),
                        Reveal(
                          child: FeaturedFilmCard(
                            film: film,
                            height: 196,
                            onTap: () => _openFilm(film),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          film.description,
                          style: AppText.body(12.5, height: 1.5),
                        ),
                      ] else ...[
                        const SizedBox(height: 34),
                        Container(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                          decoration: BoxDecoration(
                            color: Palette.paperWarm,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const SunMark(
                                size: 24,
                                color: Palette.clay,
                                stroke: 1,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  'No film for this place. Some places resist cameras.',
                                  style: AppText.serifItalic(
                                    16,
                                    color: Palette.inkSoft,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 40),
                      _QuoteCard(place: place),
                      const SizedBox(height: 40),
                      _BodyHeading(
                        title: 'Nearby the atlas',
                        meta: 'KEEP LOOKING',
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 246,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: place.nearby.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final id = place.nearby[index];
                            final nearby = _placeFor(id);
                            if (nearby == null) return const SizedBox.shrink();
                            return SmallPlaceCard(
                              place: nearby,
                              width: 140,
                              heroTag: 'nearby-${nearby.id}',
                              onTap: () =>
                                  _openPlace(nearby, 'nearby-${nearby.id}'),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 36),
                      Center(
                        child: Column(
                          children: [
                            const SunMark(
                              size: 20,
                              color: Palette.clay,
                              stroke: 1,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'FIELD NOTE N° ${place.noteNumber} · ELSEWHERE',
                              style: AppText.label(
                                8,
                                color: Palette.inkFaint,
                                tracking: 1.4,
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
          ),
        ],
      ),
      bottomNavigationBar: _SaveBar(
        saved: saved,
        showTop: _showTop,
        onSave: () => _toggleSaved(journal),
        onTop: _scrollToTop,
      ),
    );
  }

  Widget _hero() {
    final image = AssetPhoto(asset: widget.place.hero);
    if (widget.heroTag == null) return image;
    return Hero(tag: widget.heroTag!, child: image);
  }
}

class _MetaStrip extends StatelessWidget {
  const _MetaStrip({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          _MetaCell(label: 'SEASON', value: place.season, flex: 3),
          _MetaDivider(),
          _MetaCell(label: 'STAY', value: place.days, flex: 2),
          _MetaDivider(),
          _MetaCell(label: 'COORDINATES', value: place.coordinates, flex: 4),
        ],
      ),
    );
  }
}

class _MetaCell extends StatelessWidget {
  const _MetaCell({
    required this.label,
    required this.value,
    required this.flex,
  });

  final String label;
  final String value;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.label(7.5, color: Palette.inkFaint, tracking: 1.3),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.ui(11, weight: FontWeight.w500, height: 1.2),
          ),
        ],
      ),
    );
  }
}

class _MetaDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.only(right: 14),
      color: Palette.line,
    );
  }
}

class _Story extends StatelessWidget {
  const _Story({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final first = place.story.first;
    final split = first.indexOf('. ');
    final opening = split == -1 ? first : first.substring(0, split + 1);
    final rest = split == -1 ? '' : first.substring(split + 1).trimLeft();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: opening,
                style: AppText.serifItalic(19, height: 1.5),
              ),
              if (rest.isNotEmpty)
                TextSpan(
                  text: ' $rest',
                  style: AppText.body(15, color: Palette.ink, height: 1.65),
                ),
            ],
          ),
        ),
        if (place.story.length > 1) ...[
          const SizedBox(height: 18),
          Text(
            place.story[1],
            style: AppText.body(15, color: Palette.inkSoft, height: 1.65),
          ),
        ],
      ],
    );
  }
}

class _BodyHeading extends StatelessWidget {
  const _BodyHeading({required this.title, required this.meta});

  final String title;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: Text(title, style: AppText.display(26, height: 1.0))),
        Text(
          meta.toUpperCase(),
          style: AppText.label(8.5, color: Palette.inkFaint, tracking: 1.3),
        ),
      ],
    );
  }
}

class _NoteBlock extends StatelessWidget {
  const _NoteBlock({
    required this.index,
    required this.note,
    required this.divider,
  });

  final int index;
  final FieldNote note;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                index.toString().padLeft(2, '0'),
                style: AppText.display(19, color: Palette.clay, height: 1.0),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      style: AppText.ui(13.5, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(note.body, style: AppText.body(13, height: 1.55)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (divider) const Hairline(),
      ],
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        color: Palette.paperWarm,
        padding: const EdgeInsets.fromLTRB(26, 22, 26, 24),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              bottom: -42,
              child: SunMark(
                size: 140,
                color: Palette.clay.withValues(alpha: 0.13),
                stroke: 1,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '“',
                  style: AppText.display(58, color: Palette.clay, height: 0.7),
                ),
                const SizedBox(height: 8),
                Text(place.quote, style: AppText.serifItalic(23, height: 1.3)),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(width: 24, height: 1, color: Palette.inkFaint),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        '— ${place.quoteSource.toUpperCase()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.label(
                          8,
                          color: Palette.inkFaint,
                          tracking: 1.3,
                        ),
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

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.saved,
    required this.showTop,
    required this.onSave,
    required this.onTop,
  });

  final bool saved;
  final bool showTop;
  final VoidCallback onSave;
  final VoidCallback onTop;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Palette.paper,
        border: const Border(
          top: BorderSide(color: Palette.lineSoft, width: 0.8),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: saved ? 'In your journal' : 'Keep this place',
                    icon: saved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    background: saved ? Palette.clay : Palette.ink,
                    onTap: onSave,
                  ),
                ),
                if (showTop) ...[
                  const SizedBox(width: 10),
                  RoundIconButton(
                    icon: Icons.arrow_upward_rounded,
                    size: 52,
                    iconSize: 19,
                    background: Palette.paperBright,
                    tooltip: 'Back to top',
                    onTap: onTop,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
