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

  String _metadata(Movie movie) => [
    if (movie.genreTags.isNotEmpty) movie.genreTags.join(', '),
    if (movie.isComingSoon && movie.releaseDate != null)
      'Khởi chiếu ${_date(movie.releaseDate!)}'
    else
      movie.duration,
  ].join(' • ');

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final scale = MediaQuery.textScalerOf(context);
      final width = scale.scale(14) > 20
          ? math.min(box.maxWidth - 48, 320.0)
          : box.maxWidth >= 600
          ? 210.0
          : 176.0;
      double textHeight(String text, TextStyle style) {
        final painter = TextPainter(
          text: TextSpan(
            text: text,
          style: DefaultTextStyle.of(context).style.merge(style),
          ),
          textScaler: scale,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: width);
        final height = painter.height;
        painter.dispose();
        return height;
      }

      final textSpace = movies.fold<double>(
        0,
        (height, movie) => math.max(
          height,
          textHeight(movie.title, AppTextStyles.cardTitle) +
              6 +
              textHeight(_metadata(movie), AppTextStyles.caption),
        ),
      );
      return SizedBox(
        height: width * 1.5 + 12 + textSpace + 4,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: movies.length,
          separatorBuilder: (_, _) => const SizedBox(width: 16),
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
                        if (movie.isComingSoon && movie.releaseDate != null)
                          Positioned(
                            left: 8,
                            right: 8,
                            top: 8,
                            child: IgnorePointer(
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                color: AppColors.deepPurple,
                                child: Text(
                                  'KHỞI CHIẾU ${_date(movie.releaseDate!)}',
                                  style: AppTextStyles.meta.copyWith(
                                    color: AppColors.text,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          )
                        else if (movie.format.isNotEmpty)
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
                  const SizedBox(height: 12),
                  Text(movie.title, style: AppTextStyles.cardTitle),
                  const SizedBox(height: 6),
                  Text(_metadata(movie), style: AppTextStyles.caption),
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
