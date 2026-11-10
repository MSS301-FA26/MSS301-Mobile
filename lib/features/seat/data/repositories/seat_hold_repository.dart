import '../../../orders/data/models/booking_dto.dart';

abstract interface class SeatHoldRepository {
  bool get canEnterMockCheckout;
  Future<BookingDto> hold(HoldSeatsRequestDto request);
  Future<BookingDto> getBooking(int bookingId);
  Future<BookingDto> cancel(int bookingId);
}
