import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../../shared/widgets/age_badge.dart';
import '../../../movie/presentation/models/movie.dart';
import '../providers/poster_ambient_color.dart';

class MovieCoverflow extends StatefulWidget {
  const MovieCoverflow({
    super.key,
    required this.movies,
    required this.onOpen,
    required this.onBook,
    required this.onTrailer,
    this.colorLoader = posterAmbientColor,
  });
  final List<Movie> movies;
  final Future<Color> Function(String) colorLoader;
  final ValueChanged<Movie> onOpen, onBook, onTrailer;
  @override
  State<MovieCoverflow> createState() => _MovieCoverflowState();
}

class _MovieCoverflowState extends State<MovieCoverflow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _position;
  final _palette = <String, Color>{};
  final _requested = <String>{};
  int _selected = 0;
  double _step = 180, _dragStart = 0;
  @override
  void initState() {
    super.initState();
    _position = AnimationController.unbounded(vsync: this);
    _loadPalette(0);
  }

  @override
  void didUpdateWidget(MovieCoverflow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.movies.map((m) => m.id).join(',') !=
        widget.movies.map((m) => m.id).join(',')) {
      _position.stop();
      _position.value = 0;
      _selected = 0;
      _loadPalette(0);
    }
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  void _loadPalette(int center) {
    for (
      var i = math.max(0, center - 2);
      i < math.min(widget.movies.length, center + 3);
      i++
    ) {
      final source = widget.movies[i].posterAsset;
      if (!_requested.add(source)) continue;
      widget.colorLoader(source).then((color) {
        if (mounted) setState(() => _palette[source] = color);
      });
    }
  }

  Future<void> _settle(int target) async {
    if (widget.movies.isEmpty) return;
    target = target.clamp(0, widget.movies.length - 1);
    _loadPalette(target);
    try {
      await _position
          .animateTo(
            target.toDouble(),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 380),
            curve: Curves.easeOutCubic,
          )
          .orCancel;
      if (mounted) setState(() => _selected = target);
    } on TickerCanceled {
      /* A new gesture or tab replaced this transition. */
    }
  }

  Color _ambient(double position) {
    final left = position.floor().clamp(0, widget.movies.length - 1),
        right = position.ceil().clamp(0, widget.movies.length - 1);
    const neutral = Color(0xFF232631);
    return Color.lerp(
      _palette[widget.movies[left].posterAsset] ?? neutral,
      _palette[widget.movies[right].posterAsset] ?? neutral,
      position - position.floor(),
    )!;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.movies.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth,
            posterWidth = math.min(constraints.maxWidth * 0.64, 330.0);
        final posterHeight = posterWidth * 1.5;
        _step = posterWidth * 0.75;
        return AnimatedBuilder(
          animation: _position,
          builder: (context, _) {
            final position = _position.value.clamp(
              0.0,
              (widget.movies.length - 1).toDouble(),
            );
            final movie =
                widget.movies[_selected.clamp(0, widget.movies.length - 1)];
            final moving =
                _position.isAnimating || (position - _selected).abs() > 0.001;
            final first = math.max(0, position.floor() - 2);
            final last = math.min(
              widget.movies.length - 1,
              position.ceil() + 2,
            );
            final visible =
                List.generate(
                  last - first + 1,
                  (i) => first + i,
                ).where((i) => (i - position).abs() <= 2).toList()..sort(
                  (a, b) =>
                      (b - position).abs().compareTo((a - position).abs()),
                );
            return Column(
              children: [
                GestureDetector(
                  key: const ValueKey('movie-coverflow'),
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (_) {
                    _position.stop();
                    _dragStart = _position.value;
                  },
                  onHorizontalDragUpdate: (details) {
                    _position.value =
                        (_position.value - details.delta.dx / _step).clamp(
                          0.0,
                          (widget.movies.length - 1).toDouble(),
                        );
                    _loadPalette(_position.value.round());
                  },
                  onHorizontalDragEnd: (details) {
                    final delta = _position.value - _dragStart,
                        velocity = details.primaryVelocity ?? 0;
                    final target = velocity.abs() > 450
                        ? (velocity < 0
                              ? _position.value.floor() + 1
                              : _position.value.ceil() - 1)
                        : delta.abs() >= 0.27
                        ? (delta > 0
                              ? _position.value.ceil()
                              : _position.value.floor())
                        : _dragStart.round();
                    _settle(target);
                  },
                  onHorizontalDragCancel: () => _settle(_selected),
                  child: SizedBox(
                    width: width,
                    height: posterHeight + 42,
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Positioned.fill(
                          child: IgnorePointer(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  radius: 0.83,
                                  colors: [
                                    _ambient(position).withValues(alpha: 0.22),
                                    AppColors.background,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        for (final index in visible)
                          Positioned(
                            left: (width - posterWidth) / 2,
                            top: 20,
                            width: posterWidth,
                            height: posterHeight,
                            child: Builder(
                              builder: (context) {
                                final distance = index - position,
                                    depth = (index - position).abs().clamp(
                                      0.0,
                                      1.0,
                                    );
                                final opacity = distance.abs() > 1
                                    ? (0.82 * (2 - distance.abs())).clamp(
                                        0.0,
                                        1.0,
                                      )
                                    : 1 - depth * 0.18;
                                final scale = 1 - depth * 0.18;
                                final matrix = Matrix4.identity()
                                  ..setEntry(3, 2, 0.0014)
                                  ..translateByDouble(
                                    distance * _step,
                                    depth * 10,
                                    -depth * 30,
                                    1,
                                  )
                                  ..rotateY(-distance.clamp(-1.0, 1.0) * 0.55)
                                  ..scaleByDouble(scale, scale, 1, 1);
                                return Transform(
                                  alignment: Alignment.center,
                                  transform: matrix,
                                  child: Opacity(
                                    opacity: opacity,
                                    child: RepaintBoundary(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          borderRadius: AppRadii.small,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.65,
                                              ),
                                              blurRadius: 22,
                                              offset: const Offset(0, 12),
                                            ),
                                          ],
                                        ),
                                        child: Semantics(
                                          label: widget.movies[index].title,
                                          button: true,
                                          child: GestureDetector(
                                            key: ValueKey(
                                              'hero-open-${widget.movies[index].id}',
                                            ),
                                            onTap: () {
                                              if (index != _selected ||
                                                  moving) {
                                                _settle(index);
                                              } else {
                                                widget.onOpen(
                                                  widget.movies[index],
                                                );
                                              }
                                            },
                                            child: ClipRRect(
                                              borderRadius: AppRadii.small,
                                              child: ColoredBox(
                                                color: AppColors.surface,
                                                child: Stack(
                                                  fit: StackFit.expand,
                                                  children: [
                                                    ExcludeSemantics(
                                                      child: ImageFiltered(
                                                        imageFilter:
                                                            ui.ImageFilter.blur(
                                                              sigmaX: 18,
                                                              sigmaY: 18,
                                                              tileMode: ui
                                                                  .TileMode
                                                                  .clamp,
                                                            ),
                                                        child: Transform.scale(
                                                          scale: 1.12,
                                                          child: AppImage(
                                                            asset: widget
                                                                .movies[index]
                                                                .posterAsset,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const ColoredBox(
                                                      color: Color(0x59000000),
                                                    ),
                                                    AppImage(
                                                      asset: widget
                                                          .movies[index]
                                                          .posterAsset,
                                                      fit: BoxFit.contain,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    4,
                    AppSpacing.md,
                    16,
                  ),
                  child: Column(
                    children: [
                      Opacity(
                        opacity: (1 - (position - _selected).abs()).clamp(
                          0.0,
                          1.0,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 230),
                          reverseDuration: Duration.zero,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.04),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                          child: SizedBox(
                            key: ValueKey('movie-info-${movie.id}'),
                            width: double.infinity,
                            child: Column(
                              children: [
                                Text(
                                  movie.title.toUpperCase(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.sectionTitle,
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: [
                                    if (movie.ageRating.isNotEmpty)
                                      AgeBadge(rating: movie.ageRating),
                                    if (movie.duration.isNotEmpty)
                                      Text(
                                        movie.duration,
                                        style: AppTextStyles.caption,
                                      ),
                                    if (movie.releaseDate != null)
                                      Text(
                                        '${movie.releaseDate!.day.toString().padLeft(2, '0')}/${movie.releaseDate!.month.toString().padLeft(2, '0')}/${movie.releaseDate!.year}',
                                        style: AppTextStyles.caption,
                                      ),
                                  ],
                                ),
                                if (movie.genreTags.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      movie.genreTags.join(' · '),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.caption,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          key: ValueKey('hero-book-${movie.id}'),
                          label: movie.isNowShowing ? 'Đặt vé' : 'Xem chi tiết',
                          icon: movie.isNowShowing
                              ? Icons.confirmation_number_outlined
                              : Icons.arrow_forward_rounded,
                          onPressed: moving
                              ? null
                              : () => movie.isNowShowing
                                    ? widget.onBook(movie)
                                    : widget.onOpen(movie),
                        ),
                      ),
                      if (movie.trailerUrl?.isNotEmpty == true)
                        TextButton.icon(
                          onPressed: moving
                              ? null
                              : () => widget.onTrailer(movie),
                          icon: const Icon(Icons.play_circle_outline, size: 18),
                          label: const Text(
                            'Xem trailer',
                            style: AppTextStyles.caption,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
