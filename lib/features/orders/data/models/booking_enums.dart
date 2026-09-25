enum BookingStatus {
  holding('HOLDING'),
  pendingPayment('PENDING_PAYMENT'),
  paid('PAID'),
  used('USED'),
  cancelled('CANCELLED'),
  expired('EXPIRED'),
  refunded('REFUNDED'),
  unknown('UNKNOWN');

  const BookingStatus(this.wireValue);
  final String wireValue;

  static BookingStatus parse(Object? value) => values.firstWhere(
    (item) => item.wireValue == value?.toString().toUpperCase(),
    orElse: () => unknown,
  );
}

enum BookingSeatStatus {
  holding('HOLDING'),
  booked('BOOKED'),
  checkedIn('CHECKED_IN'),
  released('RELEASED'),
  unknown('UNKNOWN');

  const BookingSeatStatus(this.wireValue);
  final String wireValue;

  static BookingSeatStatus parse(Object? value) => values.firstWhere(
    (item) => item.wireValue == value?.toString().toUpperCase(),
    orElse: () => unknown,
  );
}

enum BookingSeatType {
  standard('STANDARD'),
  vip('VIP'),
  couple('COUPLE'),
  unknown('UNKNOWN');

  const BookingSeatType(this.wireValue);
  final String wireValue;

  static BookingSeatType parse(Object? value) => values.firstWhere(
    (item) => item.wireValue == value?.toString().toUpperCase(),
    orElse: () => unknown,
  );
}
