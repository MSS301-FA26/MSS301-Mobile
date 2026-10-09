import '../models/account_dto.dart';

abstract interface class ProfileRepository {
  Future<UserProfileDto> getProfile(int userId);

  Future<UserProfileDto> updateProfile(
    int userId,
    UserProfileUpdateDto request,
  );
}

abstract interface class WalletRepository {
  Future<WalletDto> getWallet(int userId);

  Future<List<WalletTransactionDto>> getTransactions(int userId);

  Future<List<WithdrawalDto>> getWithdrawals(int userId);

  Future<WithdrawalDto> createWithdrawal(
    int userId,
    WithdrawalCreateRequestDto request,
  );
}

abstract interface class LoyaltyRepository {
  Future<LoyaltyDto> getLoyalty(int userId);

  Future<LoyaltyConfigurationDto> getConfiguration();

  Future<LoyaltyDto> redeemPoints(int points);
}

class AccountNotFoundException implements Exception {
  const AccountNotFoundException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AccountConflictException implements Exception {
  const AccountConflictException(this.message);
  final String message;

  @override
  String toString() => message;
}
