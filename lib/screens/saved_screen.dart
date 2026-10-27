import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/motion.dart';
import '../core/palette.dart';
import '../core/routes.dart';
import '../core/text_styles.dart';
import '../models/place.dart';
import '../state/journal.dart';
import '../widgets/editorial.dart';
import '../widgets/place_cards.dart';
import 'place_screen.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key, required this.onExplore});

  final VoidCallback onExplore;

  void _openPlace(BuildContext context, String id) {
    final match = context
        .read<JournalController>()
        .savedPlaces
        .where((place) => place.id == id)
        .toList();
    if (match.isEmpty) return;
    Navigator.of(context).push(softRoute(PlaceScreen(place: match.first)));
  }

  Future<void> _remove(
    BuildContext context,
    JournalController journal,
    String id,
  ) async {
    HapticFeedback.selectionClick();
    await journal.remove(id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Removed from your journal.')),
      );
  }

  Future<void> _confirmClear(
    BuildContext context,
    JournalController journal,
  ) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Palette.paperBright,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Clear your journal?', style: AppText.display(25)),
        content: Text(
          'Every place you have kept will be removed. The atlas itself stays right where it is.',
          style: AppText.body(13.5, height: 1.5),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Keep it',
              style: AppText.ui(12.5, color: Palette.inkSoft),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Clear',
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
    if (shouldClear == true) {
      await journal.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final hPad = width >= 760 ? 44.0 : 24.0;

    return Consumer<JournalController>(
      builder: (context, journal, _) {
        final saved = journal.savedPlaces;
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
                          const Kicker('Your journal'),
                          const Spacer(),
                          Text(
                            '${saved.length.toString().padLeft(2, '0')} KEPT',
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
                                  const TextSpan(text: 'Kept\n'),
                                  TextSpan(
                                    text: 'places.',
                                    style: AppText.serifItalic(
                                      42,
                                      color: Palette.clay,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                              style: AppText.display(42, height: 1.0),
                            ),
                            const SizedBox(height: 12),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 340),
                              child: Text(
                                saved.isEmpty
                                    ? 'A small journal of places you would like to return to. It lives on this device.'
                                    : '${saved.length == 1 ? 'One place' : '${saved.length} places'}, held close. The rest of the atlas is still out there.',
                                style: AppText.body(13.5, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeIn,
                        child: saved.isEmpty
                            ? _EmptyJournal(
                                key: const ValueKey('empty'),
                                onExplore: onExplore,
                              )
                            : _SavedList(
                                key: const ValueKey('list'),
                                saved: saved,
                                onOpen: (id) => _openPlace(context, id),
                                onRemove: (id) => _remove(context, journal, id),
                                onExplore: onExplore,
                                onClear: () => _confirmClear(context, journal),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyJournal extends StatelessWidget {
  const _EmptyJournal({super.key, required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(26, 34, 26, 28),
          decoration: BoxDecoration(
            color: Palette.paperWarm,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              const SunMark(size: 72, color: Palette.clay, stroke: 1),
              const SizedBox(height: 24),
              Text(
                'Nothing collected yet',
                textAlign: TextAlign.center,
                style: AppText.display(28, height: 1.05),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(
                  'When a place stays with you, keep it here. Your journal lives on this device, away from the noise.',
                  textAlign: TextAlign.center,
                  style: AppText.body(13, height: 1.55),
                ),
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                label: 'Open the atlas',
                icon: Icons.explore_outlined,
                expanded: false,
                onTap: onExplore,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          '“A journal is a promise to return.”',
          textAlign: TextAlign.center,
          style: AppText.serifItalic(20, color: Palette.inkSoft, height: 1.35),
        ),
      ],
    );
  }
}

class _SavedList extends StatelessWidget {
  const _SavedList({
    super.key,
    required this.saved,
    required this.onOpen,
    required this.onRemove,
    required this.onExplore,
    required this.onClear,
  });

  final List<Place> saved;
  final ValueChanged<String> onOpen;
  final ValueChanged<String> onRemove;
  final VoidCallback onExplore;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final place in saved)
          SavedPlaceRow(
            place: place,
            onTap: () => onOpen(place.id),
            onRemove: () => onRemove(place.id),
          ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Find another place',
          icon: Icons.arrow_outward_rounded,
          onTap: onExplore,
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          decoration: BoxDecoration(
            color: Palette.paperWarm,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Kicker('A note to self', line: false, color: Palette.clay),
              const SizedBox(height: 5),
              Text(
                '“A journal is a promise to return.”',
                style: AppText.serifItalic(18, height: 1.25),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: TextButton(
            onPressed: onClear,
            child: Text(
              'Clear journal',
              style: AppText.label(9, color: Palette.inkFaint, tracking: 1.3),
            ),
          ),
        ),
      ],
    );
  }
}
