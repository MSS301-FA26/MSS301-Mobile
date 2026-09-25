import '../../../../core/demo/demo_scenario.dart';
import '../../../../core/money/vnd_money.dart';
import '../../../../core/time/app_clock.dart';
import '../../../orders/data/models/booking_enums.dart';
import '../../../orders/data/repositories/booking_repository.dart';
import '../models/payment_dto.dart';
import '../models/payment_enums.dart';
import 'payment_repository.dart';

class MockPaymentRepository implements PaymentRepository {
  MockPaymentRepository(
    this._clock,
    this._bookingRepository, {
    this.delay = Duration.zero,
  });

  final AppClock _clock;
  final BookingRepository _bookingRepository;
  final Duration delay;
  final Map<int, PaymentDto> _payments = {};
  var _nextPaymentId = DemoIds.payment;

  Future<void> _wait() => Future<void>.delayed(delay);

  @override
  Future<PaymentDto> createPayment(
    int userId,
    CreatePaymentRequestDto request,
  ) async {
    await _wait();
    final bookingId = request.bookingId;
    if (bookingId == null && request.foodOrderId == null) {
      throw const PaymentConflictException(
        'Payment cần bookingId hoặc foodOrderId.',
      );
    }
    var amount = VndMoney.zero;
    if (bookingId != null) {
      final booking = await _bookingRepository.getBooking(bookingId);
      if (booking == null) {
        throw const PaymentNotFoundException('Không tìm thấy booking.');
      }
      if (booking.status != BookingStatus.pendingPayment) {
        throw const PaymentConflictException(
          'Booking chưa sẵn sàng thanh toán.',
        );
      }
      amount = booking.totalAmount;
    }
    final id = _nextPaymentId++;
    final payment = PaymentDto(
      id: id,
      bookingId: bookingId,
      foodOrderId: request.foodOrderId,
      userId: userId,
      provider: PaymentProvider.vnpay,
      amount: amount,
      status: PaymentStatus.pending,
      paymentUrl: 'mock://vnpay/$id',
      paymentAccountLabel: 'VNPay Mock',
      refundAmount: VndMoney.zero,
      createdAt: _clock.now(),
    );
    _payments[id] = payment;
    return payment;
  }

  @override
  Future<PaymentDto?> getPayment(int paymentId) async {
    await _wait();
    return _payments[paymentId];
  }

  @override
  Future<PaymentDto?> getPaymentByBooking(int bookingId) async {
    await _wait();
    for (final payment in _payments.values) {
      if (payment.bookingId == bookingId) return payment;
    }
    return null;
  }

  @override
  Future<PaymentDto> markSuccess(int paymentId) async {
    await _wait();
    final current = _require(paymentId);
    if (current.status != PaymentStatus.pending) {
      throw const PaymentConflictException('Payment không còn pending.');
    }
    final success = current.copyWith(
      status: PaymentStatus.success,
      transactionId: 'MOCK-TXN-$paymentId',
      paidAt: _clock.now(),
    );
    _payments[paymentId] = success;
    return success;
  }

  @override
  Future<PaymentDto> markFailed(int paymentId) async {
    await _wait();
    final current = _require(paymentId);
    if (current.status != PaymentStatus.pending) {
      throw const PaymentConflictException('Payment không còn pending.');
    }
    final failed = current.copyWith(status: PaymentStatus.failed);
    _payments[paymentId] = failed;
    return failed;
  }

  @override
  Future<void> confirmSuccessfulBooking(int paymentId) async {
    await _wait();
    final payment = _require(paymentId);
    if (payment.status != PaymentStatus.success || payment.bookingId == null) {
      throw const PaymentConflictException(
        'Payment chưa thành công hoặc không gắn booking.',
      );
    }
    await _bookingRepository.applyPaymentSucceeded(payment.bookingId!);
  }

  PaymentDto _require(int id) {
    final value = _payments[id];
    if (value == null) {
      throw const PaymentNotFoundException('Không tìm thấy payment.');
    }
    return value;
  }
}
