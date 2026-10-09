import '../../../../core/contracts/json_parsers.dart';
import '../../../../core/money/vnd_money.dart';

enum FoodOrderStatus {
  pendingPayment('PENDING_PAYMENT'),
  paid('PAID'),
  pickedUp('PICKED_UP'),
  cancelled('CANCELLED'),
  expired('EXPIRED');

  const FoodOrderStatus(this.wireValue);
  final String wireValue;

  static FoodOrderStatus parse(Object? value) => values.firstWhere(
    (item) => item.wireValue == value?.toString().toUpperCase(),
    orElse: () => FoodOrderStatus.pendingPayment,
  );

  String get label => switch (this) {
    pendingPayment => 'Chờ thanh toán',
    paid => 'Đã thanh toán',
    pickedUp => 'Đã nhận hàng',
    cancelled => 'Đã hủy',
    expired => 'Đã hết hạn',
  };
}

class FoodOrderItemDto {
  const FoodOrderItemDto({
    required this.id,
    required this.productId,
    required this.isCombo,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });
  final int id;
  final int productId;
  final bool isCombo;
  final String productName;
  final int quantity;
  final VndMoney unitPrice;
  final VndMoney lineTotal;

  factory FoodOrderItemDto.fromJson(Map<String, Object?> json) =>
      FoodOrderItemDto(
        id: intFromJson(json['id']),
        productId: intFromJson(json['productId']),
        isCombo: boolFromJson(json['isCombo']),
        productName: json['productName']?.toString() ?? '',
        quantity: intFromJson(json['quantity'] ?? 0),
        unitPrice: VndMoney.fromJson(json['unitPrice']),
        lineTotal: VndMoney.fromJson(json['lineTotal']),
      );
}

class FoodOrderDto {
  const FoodOrderDto({
    required this.id,
    required this.orderCode,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.items,
    this.bookingId,
    this.bookingCode,
    this.paidAt,
    this.expiresAt,
    this.pickedUpAt,
    this.qrCode,
    this.createdByStaff = false,
  });
  final int id;
  final String orderCode;
  final int? bookingId;
  final String? bookingCode;
  final FoodOrderStatus status;
  final VndMoney totalAmount;
  final DateTime? paidAt;
  final DateTime? expiresAt;
  final DateTime? pickedUpAt;
  final String? qrCode;
  final DateTime createdAt;
  final bool createdByStaff;
  final List<FoodOrderItemDto> items;

  factory FoodOrderDto.fromJson(Map<String, Object?> json) => FoodOrderDto(
    id: intFromJson(json['id']),
    orderCode: json['orderCode']?.toString() ?? '',
    bookingId: nullableIntFromJson(json['bookingId']),
    bookingCode: json['bookingCode']?.toString(),
    status: FoodOrderStatus.parse(json['status']),
    totalAmount: VndMoney.fromJson(json['totalAmount']),
    paidAt: nullableDateTimeFromJson(json['paidAt']),
    expiresAt: nullableDateTimeFromJson(json['expiresAt']),
    pickedUpAt: nullableDateTimeFromJson(json['pickedUpAt']),
    qrCode: json['qrCode']?.toString(),
    createdAt: dateTimeFromJson(json['createdAt']),
    createdByStaff: boolFromJson(json['createdByStaff']),
    items: listFromJson(json['items'], FoodOrderItemDto.fromJson),
  );
}
