import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../movie/data/repositories/catalog_providers.dart';
import '../../../auth/application/auth_session.dart';
import '../../data/repositories/booking_providers.dart';
import '../../data/repositories/remote_booking_repository.dart';
import '../models/ticket_order.dart';

final ordersProvider = FutureProvider<List<TicketOrder>>((ref) async {
  final userId = ref.watch(
    authSessionProvider.select((auth) => auth.session?.user.id),
  );
  if (userId == null) return [];
  final bookingRepository = ref.watch(bookingRepositoryProvider);
  final bookings = await bookingRepository.getBookings(
    bookingRepository is RemoteBookingRepository ? userId : 1,
  );
  final movies = bookingRepository is RemoteBookingRepository
      ? const []
      : await ref.watch(mockCatalogRepositoryProvider).getMovies();
  return bookings
      .where(
        (booking) =>
            bookingRepository is! RemoteBookingRepository ||
            booking.userId == userId,
      )
      .map((booking) {
        final movie = movies
            .where((item) => item.id == booking.movieId)
            .firstOrNull;
        return mapBookingToOrder(
          booking,
          moviePoster: movie?.posterUrl ?? movie?.avatarUrl ?? '',
          ageRating: movie?.ageRating ?? '',
        );
      })
      .toList(growable: false);
});
