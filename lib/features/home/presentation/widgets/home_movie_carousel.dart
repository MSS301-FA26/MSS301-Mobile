import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/age_badge.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../movie/presentation/models/movie.dart';

class HomeMovieCarousel extends StatelessWidget {
  const HomeMovieCarousel({
    super.key,
    required this.movies,
    required this.onOpen,
    this.onBook,
  });
  final List<Movie> movies;
  final ValueChanged<Movie> onOpen;
  final ValueChanged<Movie>? onBook;

  String _metadata(Movie movie) =>
      movie.isComingSoon && movie.releaseDate != null
      ? 'Khởi chiếu ${_date(movie.releaseDate!)}'
      : [
          if (movie.genreTags.isNotEmpty) movie.genreTags.first,
          if (movie.duration.isNotEmpty) movie.duration,
        ].join(' • ');

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final scale = MediaQuery.textScalerOf(context);
      final width = scale.scale(14) > 20
          ? math.min(box.maxWidth - 48, 320.0)
          : box.maxWidth >= 600
          ? 210.0
          : (box.maxWidth - 16) / 2.2 - 12;
      double textHeight(String text, TextStyle style, int maxLines) {
        final painter = TextPainter(
          text: TextSpan(
            text: text,
            // Measure the same inherited typography that Text actually renders.
            // https://api.flutter.dev/flutter/painting/TextStyle/inherit.html
            style: DefaultTextStyle.of(context).style.merge(style),
          ),
          textScaler: scale,
          maxLines: maxLines,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: width);
        final height = painter.height;
        painter.dispose();
        return height;
      }

      final textSpace =
          textHeight('Ag\nAg', AppTextStyles.cardTitle, 2) +
          4 +
          textHeight('Ag', AppTextStyles.body, 1);
      return SizedBox(
        height: width * 1.5 + 8 + textSpace + 4,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: movies.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final movie = movies[index];
            return SizedBox(
              width: width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 2 / 3,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Material(
                          color: AppColors.surface,
                          borderRadius: AppRadii.card,
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            key: ValueKey('home-movie-${movie.id}'),
                            onTap: () => onOpen(movie),
                            child: AppImage(
                              asset: movie.posterAsset,
                              borderRadius: AppRadii.card,
                              semanticLabel: movie.title,
                            ),
                          ),
                        ),
                        if (movie.hasAgeRating)
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: IgnorePointer(
                              child: AgeBadge(rating: movie.ageRating),
                            ),
                          ),
                        if (movie.format.isNotEmpty)
                          Positioned(
                            left: 8,
                            top: 8,
                            child: IgnorePointer(
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                color: AppColors.background,
                                child: Text(
                                  movie.format,
                                  style: AppTextStyles.meta.copyWith(
                                    color: AppColors.gold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (onBook != null)
                          Positioned(
                            left: 4,
                            bottom: 4,
                            child: IconButton.filled(
                              key: ValueKey('now-showing-book-${movie.id}'),
                              tooltip: 'Đặt vé ${movie.title}',
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              onPressed: () => onBook!(movie),
                              icon: const Icon(
                                Icons.confirmation_number_outlined,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    movie.title,
                    style: AppTextStyles.cardTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    semanticsLabel: movie.title,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _metadata(movie),
                    style: AppTextStyles.body.copyWith(
                      color: movie.isComingSoon
                          ? AppColors.lavender
                          : AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
