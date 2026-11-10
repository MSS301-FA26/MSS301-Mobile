import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import 'booking_repository.dart';
import 'remote_booking_repository.dart';

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => RemoteBookingRepository(ref.watch(dioProvider)),
);
