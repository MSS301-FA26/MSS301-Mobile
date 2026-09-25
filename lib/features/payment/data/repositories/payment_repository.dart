import '../models/payment_dto.dart';

abstract interface class PaymentRepository {
  Future<PaymentDto> createPayment(int userId, CreatePaymentRequestDto request);

  Future<PaymentDto?> getPayment(int paymentId);

  Future<PaymentDto?> getPaymentByBooking(int bookingId);

  Future<PaymentDto> markSuccess(int paymentId);

  Future<PaymentDto> markFailed(int paymentId);

  Future<void> confirmSuccessfulBooking(int paymentId);
}

class PaymentNotFoundException implements Exception {
  const PaymentNotFoundException(this.message);
  final String message;

  @override
  String toString() => message;
}

class PaymentConflictException implements Exception {
  const PaymentConflictException(this.message);
  final String message;

  @override
  String toString() => message;
}
