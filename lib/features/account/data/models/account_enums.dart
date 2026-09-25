enum UserStatus {
  active('ACTIVE'),
  disabled('DISABLED'),
  pendingVerification('PENDING_VERIFICATION'),
  unknown('UNKNOWN');

  const UserStatus(this.wireValue);
  final String wireValue;

  static UserStatus parse(Object? value) => values.firstWhere(
    (item) => item.wireValue == value?.toString().toUpperCase(),
    orElse: () => unknown,
  );
}

enum LoyaltyStatus {
  active('ACTIVE'),
  suspended('SUSPENDED'),
  expired('EXPIRED'),
  unknown('UNKNOWN');

  const LoyaltyStatus(this.wireValue);
  final String wireValue;

  static LoyaltyStatus parse(Object? value) => values.firstWhere(
    (item) => item.wireValue == value?.toString().toUpperCase(),
    orElse: () => unknown,
  );
}

enum WalletTransactionType {
  refundCredit('REFUND_CREDIT'),
  bookingDebit('BOOKING_DEBIT'),
  topUp('TOP_UP'),
  withdrawalHold('WITHDRAWAL_HOLD'),
  withdrawalPaid('WITHDRAWAL_PAID'),
  withdrawalRefund('WITHDRAWAL_REFUND'),
  unknown('UNKNOWN');

  const WalletTransactionType(this.wireValue);
  final String wireValue;

  static WalletTransactionType parse(Object? value) => values.firstWhere(
    (item) => item.wireValue == value?.toString().toUpperCase(),
    orElse: () => unknown,
  );
}

enum WithdrawalStatus {
  pending('PENDING'),
  paid('PAID'),
  rejected('REJECTED'),
  unknown('UNKNOWN');

  const WithdrawalStatus(this.wireValue);
  final String wireValue;

  static WithdrawalStatus parse(Object? value) => values.firstWhere(
    (item) => item.wireValue == value?.toString().toUpperCase(),
    orElse: () => unknown,
  );
}
