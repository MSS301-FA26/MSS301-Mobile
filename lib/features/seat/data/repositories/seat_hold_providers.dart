import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import 'remote_seat_hold_repository.dart';
import 'seat_hold_repository.dart';

final seatHoldRepositoryProvider = Provider<SeatHoldRepository>(
  (ref) => RemoteSeatHoldRepository(ref.watch(dioProvider)),
);
