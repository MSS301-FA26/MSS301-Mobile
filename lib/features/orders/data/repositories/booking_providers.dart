import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../movie/data/repositories/catalog_providers.dart';
import 'booking_repository.dart';
import 'mock_booking_repository.dart';

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => MockBookingRepository(
    ref.watch(appClockProvider),
    ref.watch(mockCatalogRepositoryProvider),
  ),
);
