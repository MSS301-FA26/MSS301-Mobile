import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../movie/data/repositories/catalog_providers.dart';
import '../../../showtime/data/models/showtime_dto.dart';

final seatMapProvider = FutureProvider.family<ShowtimeSeatMapDto, int>((
  ref,
  showtimeId,
) {
  return ref.watch(mockCatalogRepositoryProvider).getSeatMap(showtimeId);
});
