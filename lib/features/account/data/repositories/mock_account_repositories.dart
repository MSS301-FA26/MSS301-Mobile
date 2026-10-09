import '../../../../core/demo/demo_scenario.dart';
import '../../../../core/money/vnd_money.dart';
import '../../../../core/time/app_clock.dart';
import '../models/account_dto.dart';
import '../models/account_enums.dart';
import 'account_repositories.dart';

class MockAccountStore
    implements ProfileRepository, WalletRepository, LoyaltyRepository {
  MockAccountStore({required AppClock clock, this.delay = Duration.zero})
    : _clock = clock,
      _profile = UserProfileDto(
        id: DemoIds.user,
        email: 'minh.nguyen@cinepremier.vn',
        fullName: 'Nguyễn Minh',
        phone: '0901234567',
        birthYear: 1998,
        status: UserStatus.active,
        emailVerified: true,
        phoneVerified: true,
        roles: const ['USER'],
        createdAt: clock.now().subtract(const Duration(days: 365)),
        updatedAt: clock.now(),
      ),
      _wallet = WalletDto(
        id: DemoIds.wallet,
        balance: const VndMoney(500000),
        createdAt: clock.now().subtract(const Duration(days: 180)),
      ),
      _loyalty = const LoyaltyDto(
        userId: DemoIds.user,
        userEmail: 'minh.nguyen@cinepremier.vn',
        points: 1250,
        totalPoints: 4200,
        status: LoyaltyStatus.active,
      );

  final AppClock _clock;
  final Duration delay;
  UserProfileDto _profile;
  WalletDto _wallet;
  LoyaltyDto _loyalty;
  final List<WalletTransactionDto> _transactions = [];
  final List<WithdrawalDto> _withdrawals = [];
  var _nextWithdrawalId = 8001;
  var _nextTransactionId = 9001;

  Future<void> _wait() => Future<void>.delayed(delay);

  @override
  Future<UserProfileDto> getProfile(int userId) async {
    await _wait();
    _requireUser(userId);
    return _profile;
  }

  @override
  Future<UserProfileDto> updateProfile(
    int userId,
    UserProfileUpdateDto request,
  ) async {
    await _wait();
    _requireUser(userId);
    if (request.fullName.trim().isEmpty) {
      throw const AccountConflictException('Họ tên không được để trống.');
    }
    _profile = _profile.copyWith(
      fullName: request.fullName.trim(),
      phone: request.phone,
      birthYear: request.birthYear,
      updatedAt: _clock.now(),
    );
    return _profile;
  }

  @override
  Future<WalletDto> getWallet(int userId) async {
    await _wait();
    _requireUser(userId);
    return _wallet;
  }

  @override
  Future<List<WalletTransactionDto>> getTransactions(int userId) async {
    await _wait();
    _requireUser(userId);
    return List.unmodifiable(_transactions);
  }

  @override
  Future<List<WithdrawalDto>> getWithdrawals(int userId) async {
    await _wait();
    _requireUser(userId);
    return List.unmodifiable(_withdrawals);
  }

  @override
  Future<WithdrawalDto> createWithdrawal(
    int userId,
    WithdrawalCreateRequestDto request,
  ) async {
    await _wait();
    _requireUser(userId);
    if (request.amount.amount < 10000) {
      throw const AccountConflictException('Số tiền rút tối thiểu là 10.000đ.');
    }
    if (request.amount.amount > _wallet.balance.amount) {
      throw const AccountConflictException('Số dư ví không đủ.');
    }
    final nextBalance = _wallet.balance - request.amount;
    _wallet = WalletDto(
      id: _wallet.id,
      balance: nextBalance,
      createdAt: _wallet.createdAt,
    );
    final withdrawal = WithdrawalDto(
      id: _nextWithdrawalId++,
      amount: request.amount,
      bankName: request.bankName,
      accountNumber: request.accountNumber,
      accountHolder: request.accountHolder,
      walletPhone: request.walletPhone,
      status: WithdrawalStatus.pending,
      createdAt: _clock.now(),
      userId: userId,
      userName: _profile.fullName,
      userEmail: _profile.email,
    );
    _withdrawals.add(withdrawal);
    _transactions.add(
      WalletTransactionDto(
        id: _nextTransactionId++,
        walletId: _wallet.id,
        userId: userId,
        type: WalletTransactionType.withdrawalHold,
        amount: request.amount,
        balanceAfter: nextBalance,
        referenceCode: 'WD-${withdrawal.id}',
        description: 'Tạm giữ tiền rút ví',
        createdAt: _clock.now(),
      ),
    );
    return withdrawal;
  }

  @override
  Future<LoyaltyDto> getLoyalty(int userId) async {
    await _wait();
    _requireUser(userId);
    return _loyalty;
  }

  @override
  Future<LoyaltyConfigurationDto> getConfiguration() async {
    await _wait();
    return const LoyaltyConfigurationDto(
      id: 1,
      earningRatePercent: 5,
      redemptionPoints: 1,
      redemptionValueVnd: VndMoney(1000),
      expiryMonth: 12,
      expiryDay: 31,
      expiryTime: '23:59:59',
    );
  }

  @override
  Future<LoyaltyDto> redeemPoints(int points) async {
    await _wait();
    if (points <= 0) {
      throw const AccountConflictException('Sá»‘ Ä‘iá»ƒm pháº£i lá»›n hÆ¡n 0.');
    }
    if (points > _loyalty.points) {
      throw const AccountConflictException(
        'KhÃ´ng Ä‘á»§ Ä‘iá»ƒm thá»ƒ thá»±c hiá»‡n.',
      );
    }
    _loyalty = LoyaltyDto(
      userId: _loyalty.userId,
      userEmail: _loyalty.userEmail,
      points: _loyalty.points - points,
      totalPoints: _loyalty.totalPoints,
      status: _loyalty.status,
    );
    return _loyalty;
  }

  void _requireUser(int userId) {
    if (userId != _profile.id) {
      throw const AccountNotFoundException('Không tìm thấy người dùng.');
    }
  }
}
