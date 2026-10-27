import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/palette.dart';
import '../core/routes.dart';
import '../data/films.dart';
import '../data/places.dart';
import '../state/journal.dart';
import '../widgets/about_sheet.dart';
import '../widgets/journal_nav.dart';
import 'explore_screen.dart';
import 'film_player_screen.dart';
import 'films_screen.dart';
import 'home_screen.dart';
import 'place_screen.dart';
import 'saved_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  late int _index = widget.initialIndex;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleDeepLink());
  }

  void _select(int index) {
    if (index == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = index);
  }

  void _handleDeepLink() {
    if (!mounted) return;
    final params = Uri.base.queryParameters;
    final placeId = params['place'];
    final filmId = params['film'];
    if (placeId != null) {
      for (final place in places) {
        if (place.id == placeId) {
          Navigator.of(context).push(softRoute(PlaceScreen(place: place)));
          break;
        }
      }
    } else if (filmId != null) {
      for (final film in films) {
        if (film.id == filmId) {
          Navigator.of(context).push(softRoute(FilmPlayerScreen(film: film)));
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JournalController>(
      builder: (context, journal, _) {
        return Scaffold(
          backgroundColor: Palette.paper,
          body: IndexedStack(
            index: _index,
            children: [
              HomeScreen(
                onExplore: () => _select(1),
                onFilms: () => _select(2),
                onOpenAbout: () => showAboutSheet(context),
              ),
              ExploreScreen(onExploreFilms: () => _select(2)),
              const FilmsScreen(),
              SavedScreen(onExplore: () => _select(1)),
            ],
          ),
          bottomNavigationBar: JournalNav(
            index: _index,
            savedCount: journal.count,
            onTap: _select,
          ),
        );
      },
    );
  }
}
