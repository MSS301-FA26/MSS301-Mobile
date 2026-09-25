import '../../../../core/contracts/json_parsers.dart';
import '../../../../core/money/vnd_money.dart';
import 'account_enums.dart';

class UserProfileUpdateDto {
  const UserProfileUpdateDto({
    required this.fullName,
    this.phone,
    this.birthYear,
  });

  final String fullName;
  final String? phone;
  final int? birthYear;
}

class UserProfileDto {
  const UserProfileDto({
    required this.id,
    required this.email,
    required this.fullName,
    required this.status,
    required this.emailVerified,
    required this.phoneVerified,
    required this.roles,
    required this.createdAt,
    required this.updatedAt,
    this.phone,
    this.avatarUrl,
    this.birthYear,
  });

  final int id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final int? birthYear;
  final UserStatus status;
  final bool emailVerified;
  final bool phoneVerified;
  final List<String> roles;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory UserProfileDto.fromJson(Map<String, Object?> json) => UserProfileDto(
    id: intFromJson(json['id']),
    email: json['email']?.toString() ?? '',
    fullName: json['fullName']?.toString() ?? '',
    phone: json['phone']?.toString(),
    avatarUrl: json['avatarUrl']?.toString(),
    birthYear: nullableIntFromJson(json['birthYear']),
    status: UserStatus.parse(json['status']),
    emailVerified: boolFromJson(json['emailVerified']),
    phoneVerified: boolFromJson(json['phoneVerified']),
    roles: stringListFromJson(json['roles']),
    createdAt: dateTimeFromJson(json['createdAt']),
    updatedAt: dateTimeFromJson(json['updatedAt']),
  );

  UserProfileDto copyWith({
    String? fullName,
    String? phone,
    int? birthYear,
    DateTime? updatedAt,
  }) => UserProfileDto(
    id: id,
    email: email,
    fullName: fullName ?? this.fullName,
    phone: phone ?? this.phone,
    avatarUrl: avatarUrl,
    birthYear: birthYear ?? this.birthYear,
    status: status,
    emailVerified: emailVerified,
    phoneVerified: phoneVerified,
    roles: roles,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class WalletDto {
  const WalletDto({
    required this.id,
    required this.balance,
    required this.createdAt,
  });

  final int id;
  final VndMoney balance;
  final DateTime createdAt;

  factory WalletDto.fromJson(Map<String, Object?> json) => WalletDto(
    id: intFromJson(json['id']),
    balance: VndMoney.fromJson(json['balance']),
    createdAt: dateTimeFromJson(json['createdAt']),
  );
}

class WalletTransactionDto {
  const WalletTransactionDto({
    required this.id,
    required this.walletId,
    required this.userId,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.createdAt,
    this.bookingId,
    this.referenceCode,
    this.description,
  });

  final int id;
  final int walletId;
  final int userId;
  final int? bookingId;
  final WalletTransactionType type;
  final VndMoney amount;
  final VndMoney balanceAfter;
  final String? referenceCode;
  final String? description;
  final DateTime createdAt;

  factory WalletTransactionDto.fromJson(Map<String, Object?> json) =>
      WalletTransactionDto(
        id: intFromJson(json['id']),
        walletId: intFromJson(json['walletId']),
        userId: intFromJson(json['userId']),
        bookingId: nullableIntFromJson(json['bookingId']),
        type: WalletTransactionType.parse(json['type']),
        amount: VndMoney.fromJson(json['amount']),
        balanceAfter: VndMoney.fromJson(json['balanceAfter']),
        referenceCode: json['referenceCode']?.toString(),
        description: json['description']?.toString(),
        createdAt: dateTimeFromJson(json['createdAt']),
      );
}

class WithdrawalCreateRequestDto {
  const WithdrawalCreateRequestDto({
    required this.amount,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
    this.walletPhone,
  });

  final VndMoney amount;
  final String bankName;
  final String accountNumber;
  final String accountHolder;
  final String? walletPhone;
}

class WithdrawalDto {
  const WithdrawalDto({
    required this.id,
    required this.amount,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
    required this.status,
    required this.createdAt,
    required this.userId,
    this.walletPhone,
    this.processedMethod,
    this.processedNote,
    this.processedAt,
    this.userName,
    this.userEmail,
  });

  final int id;
  final VndMoney amount;
  final String bankName;
  final String accountNumber;
  final String accountHolder;
  final String? walletPhone;
  final WithdrawalStatus status;
  final String? processedMethod;
  final String? processedNote;
  final DateTime? processedAt;
  final DateTime createdAt;
  final int userId;
  final String? userName;
  final String? userEmail;

  factory WithdrawalDto.fromJson(Map<String, Object?> json) => WithdrawalDto(
    id: intFromJson(json['id']),
    amount: VndMoney.fromJson(json['amount']),
    bankName: json['bankName']?.toString() ?? '',
    accountNumber: json['accountNumber']?.toString() ?? '',
    accountHolder: json['accountHolder']?.toString() ?? '',
    walletPhone: json['walletPhone']?.toString(),
    status: WithdrawalStatus.parse(json['status']),
    processedMethod: json['processedMethod']?.toString(),
    processedNote: json['processedNote']?.toString(),
    processedAt: nullableDateTimeFromJson(json['processedAt']),
    createdAt: dateTimeFromJson(json['createdAt']),
    userId: intFromJson(json['userId']),
    userName: json['userName']?.toString(),
    userEmail: json['userEmail']?.toString(),
  );
}

class LoyaltyDto {
  const LoyaltyDto({
    required this.userId,
    required this.userEmail,
    required this.points,
    required this.totalPoints,
    required this.status,
  });

  final int userId;
  final String userEmail;
  final int points;
  final int totalPoints;
  final LoyaltyStatus status;

  factory LoyaltyDto.fromJson(Map<String, Object?> json) => LoyaltyDto(
    userId: intFromJson(json['userId']),
    userEmail: json['userEmail']?.toString() ?? '',
    points: intFromJson(json['points'] ?? 0),
    totalPoints: intFromJson(json['totalPoints'] ?? 0),
    status: LoyaltyStatus.parse(json['status']),
  );
}

class LoyaltyConfigurationDto {
  const LoyaltyConfigurationDto({
    required this.id,
    required this.earningRatePercent,
    required this.redemptionPoints,
    required this.redemptionValueVnd,
    required this.expiryMonth,
    required this.expiryDay,
    required this.expiryTime,
    this.lastExpiredAt,
    this.lastResetAt,
    this.lastResetSource,
  });

  final int id;
  final double earningRatePercent;
  final int redemptionPoints;
  final VndMoney redemptionValueVnd;
  final int expiryMonth;
  final int expiryDay;
  final String expiryTime;
  final DateTime? lastExpiredAt;
  final DateTime? lastResetAt;
  final String? lastResetSource;

  factory LoyaltyConfigurationDto.fromJson(Map<String, Object?> json) =>
      LoyaltyConfigurationDto(
        id: intFromJson(json['id']),
        earningRatePercent: doubleFromJson(json['earningRatePercent'] ?? 0),
        redemptionPoints: intFromJson(json['redemptionPoints'] ?? 0),
        redemptionValueVnd: VndMoney.fromJson(json['redemptionValueVnd']),
        expiryMonth: intFromJson(json['expiryMonth'] ?? 0),
        expiryDay: intFromJson(json['expiryDay'] ?? 0),
        expiryTime: json['expiryTime']?.toString() ?? '',
        lastExpiredAt: nullableDateTimeFromJson(json['lastExpiredAt']),
        lastResetAt: nullableDateTimeFromJson(json['lastResetAt']),
        lastResetSource: json['lastResetSource']?.toString(),
      );
}
