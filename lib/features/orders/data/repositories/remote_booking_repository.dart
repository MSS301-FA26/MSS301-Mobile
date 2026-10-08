import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../models/booking_dto.dart';
import 'booking_repository.dart';

class RemoteBookingRepository implements BookingRepository {
  RemoteBookingRepository(this._dio);
  final Dio _dio;

  @override
  Future<List<BookingDto>> getBookings(int userId) async {
    final response = await _request(
      () => _dio.get(
        '/api/v1/bookings',
        queryParameters: {'page': 0, 'size': 20},
      ),
    );
    final data = _data(response)['content'];
    if (data is! List) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Invalid booking history response.',
      );
    }
    return data
        .map(
          (item) => BookingDto.fromJson(Map<String, Object?>.from(item as Map)),
        )
        .toList(growable: false);
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
  ) => _unsupported();
  @override
  Future<BookingDto> checkout(
    int bookingId,
    UpdateHoldingBookingRequestDto request,
  ) => _unsupported();
  @override
  Future<BookingDto> cancel(int bookingId) => _unsupported();
  @override
  Future<BookingDto> applyPaymentSucceeded(int bookingId) => _unsupported();

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
