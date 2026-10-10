import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../movie/presentation/models/movie.dart';

class HomeHeroCarousel extends StatefulWidget {
  const HomeHeroCarousel({
    super.key,
    required this.movies,
    required this.onOpen,
  });
  final List<Movie> movies;
  final ValueChanged<Movie> onOpen;

  @override
  State<HomeHeroCarousel> createState() => _HomeHeroCarouselState();
}

class _HomeHeroCarouselState extends State<HomeHeroCarousel> {
  int _page = 0;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: MediaQuery.sizeOf(context).width >= 600 ? 2.8 : 16 / 9,
    child: Stack(
      children: [
        PageView.builder(
          itemCount: widget.movies.length,
          onPageChanged: (value) => setState(() => _page = value),
          itemBuilder: (context, index) {
            final movie = widget.movies[index];
            return Material(
              color: AppColors.surface,
              child: InkWell(
                key: ValueKey('hero-open-${movie.id}'),
                onTap: () => widget.onOpen(movie),
                child: AppImage(
                  asset: movie.bannerAsset ?? movie.posterAsset,
                  borderRadius: BorderRadius.zero,
                  semanticLabel: 'Xem phim ${movie.title}',
                ),
              ),
            );
          },
        ),
        Positioned(
          bottom: 12,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: Semantics(
                label: 'Ảnh ${_page + 1} trên ${widget.movies.length}',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: .65),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < widget.movies.length; i++)
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: i == _page
                                ? AppColors.text
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.textMuted),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
