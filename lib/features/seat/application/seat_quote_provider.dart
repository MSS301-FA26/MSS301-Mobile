import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../movie/data/models/food_quote_dto.dart';
import '../../movie/data/repositories/catalog_providers.dart';
import 'booking_entry_session.dart';

/// Use the same pricing authority as hold/checkout, including cinema rules
/// and showtime surcharges. A changed selection invalidates the old quote.
final seatQuoteProvider = FutureProvider.autoDispose<CheckoutQuoteDto?>((ref) {
  final session = ref.watch(bookingEntryProvider);
  if (!session.assignmentComplete ||
      session.showtimeId == null ||
      session.hasActiveHold) {
    return null;
  }
  return ref
      .watch(catalogRepositoryProvider)
      .createCheckoutQuote(
        CheckoutQuoteRequestDto(
          showtimeId: session.showtimeId!,
          seatIds: session.selectedSeatIds.toList(growable: false),
          tickets: session.assignments.values
              .map(
                (item) => QuoteTicketRequestDto(
                  seatId: item.seatId,
                  ticketType: item.ticketType,
                  viewerAge:
                      item.viewerAge ??
                      BookingTicketPolicy.defaultViewerAge(item.ticketType),
                ),
              )
              .toList(growable: false),
        ),
      );
});
