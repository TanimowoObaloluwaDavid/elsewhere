import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../core/palette.dart';
import '../core/routes.dart';
import '../core/text_styles.dart';
import '../data/films.dart';
import '../models/place.dart';
import '../widgets/editorial.dart';
import '../widgets/film_cards.dart';

class FilmPlayerScreen extends StatefulWidget {
  const FilmPlayerScreen({super.key, required this.film});

  final FieldFilm film;

  @override
  State<FilmPlayerScreen> createState() => _FilmPlayerScreenState();
}

class _FilmPlayerScreenState extends State<FilmPlayerScreen> {
  VideoPlayerController? _controller;
  bool _loading = false;
  bool _failed = false;

  bool get _supportsVideo {
    if (kIsWeb) return true;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS => true,
      _ => false,
    };
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_controller != null) {
      await _togglePlay();
      return;
    }
    if (!_supportsVideo) {
      setState(() => _failed = true);
      return;
    }
    setState(() {
      _loading = true;
      _failed = false;
    });
    final controller = VideoPlayerController.asset(widget.film.asset);
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (_) {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _togglePlay() async {
    final controller = _controller;
    if (controller == null) {
      await _start();
      return;
    }
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (mounted) setState(() {});
  }

  String _time(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _openFilm(FieldFilm film) {
    Navigator.of(
      context,
    ).pushReplacement(softRoute(FilmPlayerScreen(film: film)));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final hPad = width >= 760 ? 44.0 : 20.0;
    final index = films.indexWhere((film) => film.id == widget.film.id) + 1;
    final next = films.where((film) => film.id != widget.film.id).take(2);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Palette.night,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 0),
                child: Row(
                  children: [
                    RoundIconButton(
                      icon: Icons.close_rounded,
                      background: Palette.cream.withValues(alpha: 0.1),
                      foreground: Palette.cream,
                      onTap: () => Navigator.of(context).pop(),
                      tooltip: 'Back to films',
                    ),
                    const Spacer(),
                    Text(
                      'FIELD FILM N° ${index.toString().padLeft(2, '0')}',
                      style: AppText.label(
                        8.5,
                        color: Palette.cream.withValues(alpha: 0.5),
                        tracking: 1.6,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 44,
                      child: Text(
                        widget.film.duration,
                        textAlign: TextAlign.right,
                        style: AppText.label(
                          9,
                          color: Palette.cream.withValues(alpha: 0.55),
                          tracking: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(hPad, 22, hPad, 0),
                        child: _buildStage(),
                      ),
                      if (_failed)
                        Padding(
                          padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
                          child: Text(
                            !_supportsVideo
                                ? 'Playback is available on Android, iOS, macOS and the web. Until then, the still is yours.'
                                : 'This film could not be loaded. The still is yours.',
                            style: AppText.body(
                              12,
                              color: Palette.cream.withValues(alpha: 0.55),
                              height: 1.5,
                            ),
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(hPad, 26, hPad, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'A SILENT FIELD FILM · ${widget.film.year}',
                              style: AppText.label(
                                8.5,
                                color: Palette.clay,
                                tracking: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.film.title,
                              style: AppText.display(
                                35,
                                color: Palette.cream,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.film.location,
                              style: AppText.label(
                                9,
                                color: Palette.cream.withValues(alpha: 0.5),
                                tracking: 1.3,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              widget.film.description,
                              style: AppText.body(
                                14,
                                color: Palette.cream.withValues(alpha: 0.78),
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'A single still, moved slowly. No narration, no music — just the weather that was there.',
                              style: AppText.serifItalic(
                                18,
                                color: Palette.cream.withValues(alpha: 0.62),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 26),
                            Container(
                              height: 1,
                              color: Palette.cream.withValues(alpha: 0.12),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                _Meta(
                                  label: 'LOCATION',
                                  value: widget.film.location,
                                ),
                                _Meta(
                                  label: 'DURATION',
                                  value: widget.film.duration,
                                ),
                                const _Meta(label: 'SOUND', value: 'SILENT'),
                              ],
                            ),
                            const SizedBox(height: 34),
                            Text(
                              'Next in the reel',
                              style: AppText.display(
                                24,
                                color: Palette.cream,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            for (final film in next)
                              _NextFilm(
                                film: film,
                                onTap: () => _openFilm(film),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStage() {
    final controller = _controller;
    final initialized = controller != null && controller.value.isInitialized;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: Colors.black,
              child: initialized
                  ? Center(
                      child: AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: VideoPlayer(controller),
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        AssetPhoto(asset: widget.film.poster),
                        const PhotoScrim(top: 0.25, bottom: 0.7),
                      ],
                    ),
            ),
            if (!initialized)
              Center(
                child: _loading
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Palette.cream,
                        ),
                      )
                    : GestureDetector(
                        onTap: _start,
                        child: const PlayGlyph(size: 62),
                      ),
              ),
            if (initialized)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _togglePlay,
                  child: AnimatedBuilder(
                    animation: controller,
                    builder: (context, _) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          if (!controller.value.isPlaying)
                            const Center(child: PlayGlyph(size: 58)),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(12, 24, 12, 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.65),
                                  ],
                                ),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: _togglePlay,
                                    icon: Icon(
                                      controller.value.isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Palette.cream,
                                      size: 22,
                                    ),
                                  ),
                                  Expanded(
                                    child: SizedBox(
                                      height: 18,
                                      child: VideoProgressIndicator(
                                        controller,
                                        allowScrubbing: true,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 7,
                                        ),
                                        colors: VideoProgressColors(
                                          playedColor: Palette.clay,
                                          bufferedColor: Palette.cream
                                              .withValues(alpha: 0.3),
                                          backgroundColor: Palette.cream
                                              .withValues(alpha: 0.2),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${_time(controller.value.position)} / ${_time(controller.value.duration)}',
                                    style: AppText.label(
                                      8,
                                      color: Palette.cream.withValues(
                                        alpha: 0.75,
                                      ),
                                      tracking: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            Positioned(
              top: 14,
              left: 14,
              child: Tag(
                'SILENT · LOOPING',
                color: Palette.cream,
                background: Palette.ink.withValues(alpha: 0.4),
                border: Palette.cream.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.label(
              7.5,
              color: Palette.cream.withValues(alpha: 0.4),
              tracking: 1.3,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.ui(
              10.5,
              color: Palette.cream.withValues(alpha: 0.78),
              weight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextFilm extends StatelessWidget {
  const _NextFilm({required this.film, required this.onTap});

  final FieldFilm film;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 86,
                height: 54,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AssetPhoto(asset: film.poster),
                    Center(child: PlayGlyph(size: 26)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    film.title,
                    style: AppText.display(
                      20,
                      color: Palette.cream,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    film.location,
                    style: AppText.label(
                      8,
                      color: Palette.cream.withValues(alpha: 0.45),
                      tracking: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              film.duration,
              style: AppText.label(
                8.5,
                color: Palette.cream.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
