import '../../../../core/contracts/json_parsers.dart';
import '../../../../core/money/vnd_money.dart';
import 'payment_enums.dart';

class CreatePaymentRequestDto {
  const CreatePaymentRequestDto({this.bookingId, this.foodOrderId});

  final int? bookingId;
  final int? foodOrderId;
}

class PaymentDto {
  const PaymentDto({
    required this.id,
    required this.userId,
    required this.provider,
    required this.amount,
    required this.status,
    required this.refundAmount,
    required this.createdAt,
    this.bookingId,
    this.foodOrderId,
    this.transactionId,
    this.paymentUrl,
    this.paymentAccountLabel,
    this.paidAt,
    this.refundedAt,
  });

  final int id;
  final int? bookingId;
  final int? foodOrderId;
  final int userId;
  final PaymentProvider provider;
  final String? transactionId;
  final VndMoney amount;
  final PaymentStatus status;
  final String? paymentUrl;
  final String? paymentAccountLabel;
  final DateTime? paidAt;
  final VndMoney refundAmount;
  final DateTime? refundedAt;
  final DateTime createdAt;

  factory PaymentDto.fromJson(Map<String, Object?> json) => PaymentDto(
    id: intFromJson(json['id']),
    bookingId: nullableIntFromJson(json['bookingId']),
    foodOrderId: nullableIntFromJson(json['foodOrderId']),
    userId: intFromJson(json['userId']),
    provider: PaymentProvider.parse(json['provider']),
    transactionId: json['transactionId']?.toString(),
    amount: VndMoney.fromJson(json['amount']),
    status: PaymentStatus.parse(json['status']),
    paymentUrl: json['paymentUrl']?.toString(),
    paymentAccountLabel: json['paymentAccountLabel']?.toString(),
    paidAt: nullableDateTimeFromJson(json['paidAt']),
    refundAmount: VndMoney.fromJson(json['refundAmount'] ?? 0),
    refundedAt: nullableDateTimeFromJson(json['refundedAt']),
    createdAt: dateTimeFromJson(json['createdAt']),
  );

  PaymentDto copyWith({
    PaymentStatus? status,
    String? transactionId,
    DateTime? paidAt,
    VndMoney? refundAmount,
    DateTime? refundedAt,
  }) => PaymentDto(
    id: id,
    bookingId: bookingId,
    foodOrderId: foodOrderId,
    userId: userId,
    provider: provider,
    transactionId: transactionId ?? this.transactionId,
    amount: amount,
    status: status ?? this.status,
    paymentUrl: paymentUrl,
    paymentAccountLabel: paymentAccountLabel,
    paidAt: paidAt ?? this.paidAt,
    refundAmount: refundAmount ?? this.refundAmount,
    refundedAt: refundedAt ?? this.refundedAt,
    createdAt: createdAt,
  );
}
