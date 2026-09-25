import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/demo/demo_scenario.dart';
import '../../../movie/data/repositories/catalog_providers.dart';
import '../../data/repositories/booking_providers.dart';
import '../models/ticket_order.dart';

final ordersProvider = FutureProvider<List<TicketOrder>>((ref) async {
  final bookingRepository = ref.watch(bookingRepositoryProvider);
  final catalogRepository = ref.watch(catalogRepositoryProvider);
  final bookings = await bookingRepository.getBookings(DemoIds.user);
  final movies = await catalogRepository.getMovies();
  return bookings
      .map((booking) {
        final movie = movies
            .where((item) => item.id == booking.movieId)
            .firstOrNull;
        return mapBookingToOrder(
          booking,
          moviePoster: movie?.posterUrl ?? movie?.avatarUrl ?? '',
          ageRating: movie?.ageRating ?? 'P',
        );
      })
      .toList(growable: false);
});
