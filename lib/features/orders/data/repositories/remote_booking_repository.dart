import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../models/booking_dto.dart';
import 'booking_repository.dart';

class RemoteBookingRepository implements BookingRepository {
  RemoteBookingRepository(this._dio);
  final Dio _dio;

  @override
  Future<List<BookingDto>> getBookings(int userId) async {
    final bookings = <BookingDto>[];
    var page = 0;
    while (true) {
      final response = await _request(
        () => _dio.get(
          '/api/v1/bookings',
          queryParameters: {'page': page, 'size': 20, 'sort': 'createdAt,desc'},
        ),
      );
      final envelope = _data(response);
      final data = envelope['content'];
      if (data is! List) {
        throw const ApiException(
          type: ApiErrorType.unknown,
          message: 'Invalid booking history response.',
        );
      }
      bookings.addAll(
        data.map(
          (item) => BookingDto.fromJson(Map<String, Object?>.from(item as Map)),
        ),
      );
      final totalPages = envelope['totalPages'];
      if (data.isEmpty ||
          (totalPages is num ? page + 1 >= totalPages : data.length < 20)) {
        final unique = {for (final booking in bookings) booking.id: booking}
            .values
            .toList();
        unique.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return unique;
      }
      page++;
    }
  }

  @override
  Future<BookingDto?> getBooking(int bookingId) async {
    try {
      return BookingDto.fromJson(
        _data(await _request(() => _dio.get('/api/v1/bookings/$bookingId'))),
      );
    } on ApiException catch (error) {
      if (error.type == ApiErrorType.notFound) return null;
      rethrow;
    }
  }

  @override
  Future<BookingDto> holdSeats(int userId, HoldSeatsRequestDto request) =>
      _unsupported();
  @override
  Future<BookingDto> updateItems(
    int bookingId,
    UpdateHoldingBookingRequestDto request,
  ) async => BookingDto.fromJson(
    _data(
      await _request(
        () => _dio.put(
          '/api/v1/bookings/$bookingId/items',
          data: _items(request),
        ),
      ),
    ),
  );
  @override
  Future<BookingDto> checkout(
    int bookingId,
    UpdateHoldingBookingRequestDto request,
  ) async => BookingDto.fromJson(
    _data(
      await _request(
        () => _dio.post(
          '/api/v1/bookings/$bookingId/checkout',
          data: _items(request),
        ),
      ),
    ),
  );
  @override
  Future<BookingDto> cancel(int bookingId) async => BookingDto.fromJson(
    _data(await _request(() => _dio.delete('/api/v1/bookings/$bookingId'))),
  );
  @override
  Future<BookingDto> applyPaymentSucceeded(int bookingId) => _unsupported();

  Map<String, Object?> _items(UpdateHoldingBookingRequestDto request) => {
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
    if (request.loyaltyPointsToRedeem != null)
      'loyaltyPointsToRedeem': request.loyaltyPointsToRedeem,
  };

  Future<T> _unsupported<T>() => Future<T>.error(
    const ApiException(
      type: ApiErrorType.unknown,
      message: 'Booking mutation is outside history scope.',
    ),
  );

  Future<Response<dynamic>> _request(
    Future<Response<dynamic>> Function() call,
  ) async {
    try {
      return await call();
    } on DioException catch (error) {
      if (error.error case final ApiException mapped) throw mapped;
      rethrow;
    }
  }

  Map<String, Object?> _data(Response<dynamic> response) {
    final body = response.data;
    if (body is! Map || body['success'] != true || body['data'] is! Map) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Invalid booking API response.',
      );
    }
    return Map<String, Object?>.from(body['data'] as Map);
  }
}
