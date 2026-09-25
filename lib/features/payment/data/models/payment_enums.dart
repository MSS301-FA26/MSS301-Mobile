enum PaymentStatus {
  pending('PENDING'),
  success('SUCCESS'),
  failed('FAILED'),
  refunded('REFUNDED'),
  unknown('UNKNOWN');

  const PaymentStatus(this.wireValue);
  final String wireValue;

  static PaymentStatus parse(Object? value) => values.firstWhere(
    (item) => item.wireValue == value?.toString().toUpperCase(),
    orElse: () => unknown,
  );
}

enum PaymentProvider {
  vnpay('VNPAY'),
  mock('MOCK'),
  cineWallet('CINEWALLET'),
  unknown('UNKNOWN');

  const PaymentProvider(this.wireValue);
  final String wireValue;

  static PaymentProvider parse(Object? value) => values.firstWhere(
    (item) => item.wireValue == value?.toString().toUpperCase(),
    orElse: () => unknown,
  );
}
