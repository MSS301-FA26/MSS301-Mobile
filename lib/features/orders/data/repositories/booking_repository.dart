import '../models/booking_dto.dart';

abstract interface class BookingRepository {
  Future<BookingDto> holdSeats(int userId, HoldSeatsRequestDto request);

  Future<BookingDto> updateItems(
    int bookingId,
    UpdateHoldingBookingRequestDto request,
  );

  Future<BookingDto> checkout(
    int bookingId,
    UpdateHoldingBookingRequestDto request,
  );

  Future<List<BookingDto>> getBookings(int userId);

  Future<BookingDto?> getBooking(int bookingId);

  Future<BookingDto> cancel(int bookingId);

  Future<BookingDto> applyPaymentSucceeded(int bookingId);
}

class BookingNotFoundException implements Exception {
  const BookingNotFoundException(this.message);
  final String message;

  @override
  String toString() => message;
}

class BookingConflictException implements Exception {
  const BookingConflictException(this.message);
  final String message;

  @override
  String toString() => message;
}
