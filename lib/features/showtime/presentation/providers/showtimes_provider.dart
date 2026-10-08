import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../movie/data/repositories/catalog_providers.dart';
import '../../data/models/showtime_dto.dart';
import '../models/showtime_models.dart';

class ShowtimeQuery {
  const ShowtimeQuery({this.movieId, this.date});

  final int? movieId;
  final DateTime? date;

  @override
  bool operator ==(Object other) =>
      other is ShowtimeQuery &&
      other.movieId == movieId &&
      other.date?.year == date?.year &&
      other.date?.month == date?.month &&
      other.date?.day == date?.day;

  @override
  int get hashCode => Object.hash(movieId, date?.year, date?.month, date?.day);
}

final showtimesProvider =
    FutureProvider.family<List<MovieShowtime>, ShowtimeQuery>((
      ref,
      query,
    ) async {
      final repository = ref.watch(catalogRepositoryProvider);
      final values = await repository.getShowtimes(
        movieId: query.movieId,
        date: query.date,
      );
      final byMovie = <int, List<ShowtimeDto>>{};
      for (final showtime in values) {
        byMovie.putIfAbsent(showtime.movieId, () => []).add(showtime);
      }
      return byMovie.entries
          .map((entry) => mapShowtimesToPresentation(entry.key, entry.value))
          .toList(growable: false);
    });
