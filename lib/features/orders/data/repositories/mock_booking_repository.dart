import '../../../../core/demo/demo_scenario.dart';
import '../../../../core/time/app_clock.dart';
import '../../../movie/data/models/catalog_enums.dart';
import '../../../movie/data/models/food_quote_dto.dart';
import '../../../movie/data/repositories/catalog_repository.dart';
import '../mappers/seat_contract_mapper.dart';
import '../models/booking_dto.dart';
import '../models/booking_enums.dart';
import 'booking_repository.dart';

class MockBookingRepository implements BookingRepository {
  MockBookingRepository(
    this._clock,
    this._catalogRepository, {
    this.delay = Duration.zero,
  });

  final AppClock _clock;
  final CatalogRepository _catalogRepository;
  final Duration delay;
  final Map<int, BookingDto> _bookings = {};
  final Set<int> _heldSeatIds = {};
  var _nextBookingId = DemoIds.booking;

  Future<void> _wait() => Future<void>.delayed(delay);

  @override
  Future<BookingDto> holdSeats(int userId, HoldSeatsRequestDto request) async {
    await _wait();
    if (request.seatIds.any(_heldSeatIds.contains)) {
      throw const BookingConflictException('Ghế vừa được người khác giữ.');
    }
    final quote = await _catalogRepository.createCheckoutQuote(
      CheckoutQuoteRequestDto(
        showtimeId: request.showtimeId,
        seatIds: request.seatIds,
        tickets: request.tickets
            .map(
              (ticket) => QuoteTicketRequestDto(
                seatId: ticket.seatId,
                ticketType: ticket.ticketType,
                viewerAge: ticket.viewerAge ?? 22,
                quantity: ticket.quantity,
              ),
            )
            .toList(growable: false),
        foods: request.foods
            .map(
              (food) => QuoteFoodRequestDto(
                productId: food.productId,
                isCombo: food.isCombo,
                quantity: food.quantity,
              ),
            )
            .toList(growable: false),
        cinePointsToUse: request.loyaltyPointsToRedeem,
      ),
    );
    final bookingId = _nextBookingId++;
    final holdExpiresAt = _clock.now().add(const Duration(minutes: 3));
    final bookingSeats = quote.seats.indexed
        .map((entry) {
          final index = entry.$1;
          final seat = entry.$2;
          final parts = RegExp(r'^([A-Za-z]+)(\d+)$')
              .firstMatch(seat.seatLabel);
          return BookingSeatDto(
            id: bookingId * 100 + index,
            seatId: seat.seatId,
            showtimeId: request.showtimeId,
            rowLabel: parts?.group(1) ?? '',
            seatNumber: int.tryParse(parts?.group(2) ?? '') ?? 0,
            seatLabel: seat.seatLabel,
            seatType: mapCatalogSeatTypeToBooking(seat.seatType),
            unitPrice: seat.unitPrice,
            status: BookingSeatStatus.holding,
            ticketType: TicketType.adult,
          );
        })
        .toList(growable: false);
    final tickets = quote.tickets.indexed
        .map(
          (entry) => BookingTicketDto(
            id: bookingId * 1000 + entry.$1,
            seatId: entry.$2.seatId,
            ticketType: entry.$2.ticketType,
            viewerAge: 22,
            quantity: entry.$2.quantity,
            unitPrice: entry.$2.unitPrice,
            lineTotal: entry.$2.lineTotal,
          ),
        )
        .toList(growable: false);
    final foods = quote.foods.indexed
        .map(
          (entry) => BookingFoodDto(
            id: bookingId * 10000 + entry.$1,
            productId: entry.$2.productId,
            isCombo: entry.$2.isCombo,
            productName: entry.$2.productName,
            quantity: entry.$2.quantity,
            unitPrice: entry.$2.unitPrice,
            lineTotal: entry.$2.lineTotal,
          ),
        )
        .toList(growable: false);
    final booking = BookingDto(
      id: bookingId,
      bookingCode: 'CP-MOCK-$bookingId',
      userId: userId,
      showtimeId: request.showtimeId,
      movieId: quote.showtime.movieId,
      movieTitle: quote.showtime.movieTitle,
      movieTitleSnapshot: quote.showtime.movieTitle,
      cinemaName: quote.showtime.cinemaName,
      cinemaNameSnapshot: quote.showtime.cinemaName,
      roomName: quote.showtime.roomName,
      roomNameSnapshot: quote.showtime.roomName,
      showtimeStart: quote.showtime.startTime,
      showtimeStartSnapshot: quote.showtime.startTime,
      subtotal: quote.subtotal,
      discountAmount: quote.discount,
      loyaltyPointsRedeemed: request.loyaltyPointsToRedeem ?? 0,
      totalAmount: quote.total,
      status: BookingStatus.holding,
      holdExpiresAt: holdExpiresAt,
      seats: bookingSeats,
      tickets: tickets,
      foods: foods,
      createdAt: _clock.now(),
    );
    _bookings[bookingId] = booking;
    _heldSeatIds.addAll(request.seatIds);
    return booking;
  }

  @override
  Future<BookingDto> updateItems(
    int bookingId,
    UpdateHoldingBookingRequestDto request,
  ) async {
    await _wait();
    final current = _requireActive(bookingId);
    if (current.status != BookingStatus.holding &&
        current.status != BookingStatus.pendingPayment) {
      throw const BookingConflictException('Booking không thể cập nhật.');
    }
    final quote = await _catalogRepository.createCheckoutQuote(
      CheckoutQuoteRequestDto(
        showtimeId: current.showtimeId,
        seatIds: current.seats.map((seat) => seat.seatId).toList(),
        foods: request.foods
            .map(
              (food) => QuoteFoodRequestDto(
                productId: food.productId,
                isCombo: food.isCombo,
                quantity: food.quantity,
              ),
            )
            .toList(growable: false),
      ),
    );
    final foods = quote.foods.indexed
        .map(
          (entry) => BookingFoodDto(
            id: bookingId * 10000 + entry.$1,
            productId: entry.$2.productId,
            isCombo: entry.$2.isCombo,
            productName: entry.$2.productName,
            quantity: entry.$2.quantity,
            unitPrice: entry.$2.unitPrice,
            lineTotal: entry.$2.lineTotal,
          ),
        )
        .toList(growable: false);
    final updated = current.copyWith(
      subtotal: quote.subtotal,
      totalAmount: quote.total,
      loyaltyPointsRedeemed: request.loyaltyPointsToRedeem ?? 0,
      foods: foods,
    );
    _bookings[bookingId] = updated;
    return updated;
  }

  @override
  Future<BookingDto> checkout(
    int bookingId,
    UpdateHoldingBookingRequestDto request,
  ) async {
    final updated = await updateItems(bookingId, request);
    final pending = updated.copyWith(status: BookingStatus.pendingPayment);
    _bookings[bookingId] = pending;
    return pending;
  }

  @override
  Future<List<BookingDto>> getBookings(int userId) async {
    await _wait();
    return _bookings.values
        .map(_refreshExpiry)
        .where((booking) => booking.userId == userId)
        .toList(growable: false);
  }

  @override
  Future<BookingDto?> getBooking(int bookingId) async {
    await _wait();
    final booking = _bookings[bookingId];
    return booking == null ? null : _refreshExpiry(booking);
  }

  @override
  Future<BookingDto> cancel(int bookingId) async {
    await _wait();
    final current = _requireActive(bookingId);
    if (current.status != BookingStatus.holding &&
        current.status != BookingStatus.pendingPayment) {
      throw const BookingConflictException('Booking không thể hủy.');
    }
    final cancelled = current.copyWith(
      status: BookingStatus.cancelled,
      cancelledAt: _clock.now(),
      seats: current.seats
          .map((seat) => seat.copyWith(status: BookingSeatStatus.released))
          .toList(growable: false),
    );
    _releaseSeats(current);
    _bookings[bookingId] = cancelled;
    return cancelled;
  }

  @override
  Future<BookingDto> applyPaymentSucceeded(int bookingId) async {
    await _wait();
    final current = _requireActive(bookingId);
    if (current.status != BookingStatus.pendingPayment) {
      throw const BookingConflictException(
        'Booking không ở trạng thái chờ thanh toán.',
      );
    }
    final paid = current.copyWith(
      status: BookingStatus.paid,
      paidAt: _clock.now(),
      qrCode: 'MOCK-BOOKING-QR-$bookingId',
      seats: current.seats
          .map((seat) => seat.copyWith(status: BookingSeatStatus.booked))
          .toList(growable: false),
    );
    _bookings[bookingId] = paid;
    return paid;
  }

  BookingDto _requireActive(int bookingId) {
    final value = _bookings[bookingId];
    if (value == null) {
      throw const BookingNotFoundException('Không tìm thấy booking.');
    }
    return _refreshExpiry(value);
  }

  BookingDto _refreshExpiry(BookingDto booking) {
    final expiry = booking.holdExpiresAt;
    final expirable =
        booking.status == BookingStatus.holding ||
        booking.status == BookingStatus.pendingPayment;
    if (!expirable || expiry == null || !_clock.now().isAfter(expiry)) {
      return booking;
    }
    final expired = booking.copyWith(
      status: BookingStatus.expired,
      seats: booking.seats
          .map((seat) => seat.copyWith(status: BookingSeatStatus.released))
          .toList(growable: false),
    );
    _releaseSeats(booking);
    _bookings[booking.id] = expired;
    return expired;
  }

  void _releaseSeats(BookingDto booking) {
    _heldSeatIds.removeAll(booking.seats.map((seat) => seat.seatId));
  }
}
