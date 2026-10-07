import 'package:dio/dio.dart';

import '../../../../core/contracts/json_parsers.dart';
import '../../../../core/network/api_exception.dart';
import '../models/payment_dto.dart';
import 'payment_repository.dart';

class RemotePaymentRepository implements PaymentRepository {
  RemotePaymentRepository(this._dio);
  final Dio _dio;

  @override
  Future<PaymentDto> createPayment(
    int userId,
    CreatePaymentRequestDto request,
  ) async {
    if (request.bookingId == null && request.foodOrderId == null) {
      throw const ApiException(
        type: ApiErrorType.badRequest,
        message: 'Payment requires a booking or food order.',
      );
    }
    final response = await _request(
      () => _dio.post(
        '/api/v1/payments/vnpay/create',
        data: {
          if (request.bookingId != null) 'bookingId': request.bookingId,
          if (request.foodOrderId != null) 'foodOrderId': request.foodOrderId,
        },
      ),
    );
    final data = _data(response);
    final paymentId = intFromJson(data['paymentId']);
    final payment = await getPayment(paymentId);
    if (payment == null) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Payment was created but could not be loaded.',
      );
    }
    return payment;
  }

  @override
  Future<PaymentDto?> getPayment(int paymentId) async {
    try {
      return PaymentDto.fromJson(
        _data(await _request(() => _dio.get('/api/v1/payments/$paymentId'))),
      );
    } on ApiException catch (error) {
      if (error.type == ApiErrorType.notFound) return null;
      rethrow;
    }
  }

  @override
  Future<PaymentDto?> getPaymentByBooking(int bookingId) async {
    try {
      return PaymentDto.fromJson(
        _data(
          await _request(() => _dio.get('/api/v1/payments/booking/$bookingId')),
        ),
      );
    } on ApiException catch (error) {
      if (error.type == ApiErrorType.notFound) return null;
      rethrow;
    }
  }

  @override
  Future<PaymentDto> markSuccess(int paymentId) => _unsupported();

  @override
  Future<PaymentDto> markFailed(int paymentId) => _unsupported();

  @override
  Future<void> confirmSuccessfulBooking(int paymentId) => _unsupported();

  Future<T> _unsupported<T>() => Future<T>.error(
    const ApiException(
      type: ApiErrorType.unknown,
      message: 'Payment status is authoritative; local status mutation is unavailable.',
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
        message: 'Invalid payment API response.',
      );
    }
    return Map<String, Object?>.from(body['data'] as Map);
  }
}
