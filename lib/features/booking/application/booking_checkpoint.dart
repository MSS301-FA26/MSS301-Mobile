import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../auth/application/auth_session.dart';
import '../../orders/data/models/booking_dto.dart';
import '../../orders/data/models/booking_enums.dart';
import '../../orders/data/repositories/booking_providers.dart';

class BookingCheckpoint {
  const BookingCheckpoint({
    required this.bookingId,
    this.paymentId,
    this.viewerAges = const {},
  });
  final int bookingId;
  final int? paymentId;
  final Map<int, int> viewerAges;
}

abstract interface class BookingCheckpointStore {
  Future<BookingCheckpoint?> read(int userId);
  Future<void> save(int userId, BookingCheckpoint checkpoint);
  Future<void> clear(int userId);
}

class SecureBookingCheckpointStore implements BookingCheckpointStore {
  final _storage = const FlutterSecureStorage();
  String _key(int userId) => 'booking_checkpoint_v1_$userId';

  @override
  Future<BookingCheckpoint?> read(int userId) async {
    try {
      final raw = await _storage.read(key: _key(userId));
      if (raw == null) return null;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return BookingCheckpoint(
        bookingId: (data['bookingId'] as num).toInt(),
        paymentId: (data['paymentId'] as num?)?.toInt(),
        viewerAges: {
          for (final entry in (data['viewerAges'] as Map? ?? {}).entries)
            int.parse(entry.key.toString()): (entry.value as num).toInt(),
        },
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(int userId, BookingCheckpoint checkpoint) async {
    try {
      await _storage.write(
        key: _key(userId),
        value: jsonEncode({
          'bookingId': checkpoint.bookingId,
          'paymentId': checkpoint.paymentId,
          'viewerAges': {
            for (final entry in checkpoint.viewerAges.entries)
              '${entry.key}': entry.value,
          },
        }),
      );
    } catch (_) {
      // The server-side order history remains a recovery path if storage fails.
    }
  }

  @override
  Future<void> clear(int userId) async {
    try {
      await _storage.delete(key: _key(userId));
    } catch (_) {
      // A stale checkpoint is always revalidated against server state.
    }
  }
}

final bookingCheckpointStoreProvider = Provider<BookingCheckpointStore>(
  (ref) => SecureBookingCheckpointStore(),
);

final resumableBookingProvider = FutureProvider<BookingDto?>((ref) async {
  final userId = ref.watch(authSessionProvider).session?.user.id;
  if (userId == null) return null;
  final store = ref.watch(bookingCheckpointStoreProvider);
  final checkpoint = await store.read(userId);
  if (checkpoint == null) return null;
  final booking = await ref
      .watch(bookingRepositoryProvider)
      .getBooking(checkpoint.bookingId);
  if (booking == null ||
      booking.userId != userId ||
      ![
        BookingStatus.holding,
        BookingStatus.pendingPayment,
      ].contains(booking.status)) {
    await store.clear(userId);
    return null;
  }
  return booking;
});
