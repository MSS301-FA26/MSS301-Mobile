import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../orders/data/models/booking_dto.dart';
import 'seat_hold_repository.dart';

class RemoteSeatHoldRepository implements SeatHoldRepository {
  RemoteSeatHoldRepository(this._dio);
  final Dio _dio;
  @override
  bool get canEnterMockCheckout => false;

  @override
  Future<BookingDto> hold(HoldSeatsRequestDto request) => _request(
    () => _dio.post(
      '/api/v1/bookings/hold',
      data: {
        'showtimeId': request.showtimeId,
        'seatIds': request.seatIds,
        'tickets': request.tickets
            .map(
              (ticket) => {
                'seatId': ticket.seatId,
                'ticketType': ticket.ticketType.wireValue,
                if (ticket.viewerAge != null) 'viewerAge': ticket.viewerAge,
                'quantity': ticket.quantity,
              },
            )
            .toList(growable: false),
        'foods': request.foods
            .map(
              (food) => {
                'productId': food.productId,
                'isCombo': food.isCombo,
                'quantity': food.quantity,
              },
            )
            .toList(growable: false),
        if (request.holiday != null) 'holiday': request.holiday,
        if (request.loyaltyPointsToRedeem != null)
          'loyaltyPointsToRedeem': request.loyaltyPointsToRedeem,
      },
    ),
  );

  @override
  Future<BookingDto> getBooking(int bookingId) =>
      _request(() => _dio.get('/api/v1/bookings/$bookingId'));

  @override
  Future<BookingDto> cancel(int bookingId) =>
      _request(() => _dio.delete('/api/v1/bookings/$bookingId'));

  Future<BookingDto> _request(Future<Response<dynamic>> Function() call) async {
    try {
      final response = await call();
      final body = response.data;
      if (body is! Map || body['success'] != true || body['data'] is! Map) {
        throw const ApiException(
          type: ApiErrorType.unknown,
          message: 'Invalid booking API response.',
        );
      }
      return BookingDto.fromJson(
        Map<String, Object?>.from(body['data'] as Map),
      );
    } on DioException catch (error) {
      if (error.error case final ApiException mapped) throw mapped;
      rethrow;
    }
  }
}
