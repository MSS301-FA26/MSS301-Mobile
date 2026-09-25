import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../movie/data/repositories/catalog_providers.dart';
import '../../data/models/showtime_dto.dart';
import '../models/showtime_models.dart';

final showtimesProvider = FutureProvider<List<MovieShowtime>>((ref) async {
  final repository = ref.watch(catalogRepositoryProvider);
  final values = await repository.getShowtimes();
  final byMovie = <int, List<ShowtimeDto>>{};
  for (final showtime in values) {
    byMovie.putIfAbsent(showtime.movieId, () => []).add(showtime);
  }
  return byMovie.entries
      .map((entry) => mapShowtimesToPresentation(entry.key, entry.value))
      .toList(growable: false);
});
