import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/account_dto.dart';
import '../../data/repositories/account_providers.dart';
import '../models/account_summary.dart';
import '../../application/profile_controller.dart';
import '../../../auth/application/auth_session.dart';

final accountSummaryProvider = FutureProvider<AccountSummary>((ref) async {
  final userId = ref.watch(
    authSessionProvider.select((auth) => auth.session?.user.id),
  );
  if (userId == null) {
    throw const ApiException(
      type: ApiErrorType.unauthorized,
      message: 'Vui lòng đăng nhập.',
    );
  }
  final profile = await ref.watch(currentProfileProvider.future);
  final walletRepository = ref.watch(walletRepositoryProvider);
  final loyaltyRepository = ref.watch(loyaltyRepositoryProvider);
  WalletDto? wallet;
  LoyaltyDto? loyalty;
  await Future.wait([
    Future<void>(() async {
      try {
        wallet = await walletRepository.getWallet(userId);
      } catch (_) {}
    }),
    Future<void>(() async {
      try {
        loyalty = await loyaltyRepository.getLoyalty(userId);
      } catch (_) {}
    }),
  ]);
  return mapAccountSummary(profile, wallet, loyalty);
});

final loyaltyOverviewProvider =
    FutureProvider<(LoyaltyDto, LoyaltyConfigurationDto)>((ref) async {
      final repository = ref.watch(loyaltyRepositoryProvider);
      final userId = ref.watch(
        authSessionProvider.select((auth) => auth.session?.user.id),
      );
      if (userId == null) {
        throw const ApiException(
          type: ApiErrorType.unauthorized,
          message: 'Vui lòng đăng nhập.',
        );
      }
      final points = await repository.getLoyalty(userId);
      final configuration = await repository.getConfiguration();
      return (points, configuration);
    });

final accountWalletProvider = FutureProvider<WalletDto>((ref) async {
  final userId = ref.watch(
    authSessionProvider.select((auth) => auth.session?.user.id),
  );
  if (userId == null) {
    throw const ApiException(
      type: ApiErrorType.unauthorized,
      message: 'Vui lÃ²ng Ä‘Äƒng nháº­p.',
    );
  }
  return ref.watch(walletRepositoryProvider).getWallet(userId);
});

final accountLoyaltyProvider = FutureProvider<LoyaltyDto>((ref) async {
  final userId = ref.watch(
    authSessionProvider.select((auth) => auth.session?.user.id),
  );
  if (userId == null) {
    throw const ApiException(
      type: ApiErrorType.unauthorized,
      message: 'Vui lÃ²ng Ä‘Äƒng nháº­p.',
    );
  }
  return ref.watch(loyaltyRepositoryProvider).getLoyalty(userId);
});

enum LoyaltyRedeemStatus { idle, submitting, success, error }

class LoyaltyRedeemState {
  const LoyaltyRedeemState({
    this.status = LoyaltyRedeemStatus.idle,
    this.message,
  });

  final LoyaltyRedeemStatus status;
  final String? message;
  bool get isSubmitting => status == LoyaltyRedeemStatus.submitting;
}

final loyaltyRedeemControllerProvider =
    NotifierProvider<LoyaltyRedeemController, LoyaltyRedeemState>(
      LoyaltyRedeemController.new,
    );

class LoyaltyRedeemController extends Notifier<LoyaltyRedeemState> {
  int _generation = 0;
  @override
  LoyaltyRedeemState build() {
    ref.watch(authSessionProvider.select((auth) => auth.session?.user.id));
    _generation++;
    return const LoyaltyRedeemState();
  }

  Future<void> redeem(int points) async {
    if (state.isSubmitting) return;
    if (ref.read(authSessionProvider).session == null) {
      state = const LoyaltyRedeemState(
        status: LoyaltyRedeemStatus.error,
        message: 'Vui lòng đăng nhập trước khi đổi điểm.',
      );
      return;
    }
    final generation = _generation;
    state = const LoyaltyRedeemState(status: LoyaltyRedeemStatus.submitting);
    try {
      await ref.read(loyaltyRepositoryProvider).redeemPoints(points);
      if (!ref.mounted || generation != _generation) return;
      ref.invalidate(loyaltyOverviewProvider);
      ref.invalidate(accountSummaryProvider);
      state = const LoyaltyRedeemState(
        status: LoyaltyRedeemStatus.success,
        message: 'Đổi điểm thành công. Số dư đã được cập nhật từ hệ thống.',
      );
    } catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = LoyaltyRedeemState(
        status: LoyaltyRedeemStatus.error,
        message: _safeRedeemError(error),
      );
    }
  }

  void resetMessage() {
    if (!state.isSubmitting) {
      state = const LoyaltyRedeemState();
    }
  }
}

String _safeRedeemError(Object error) {
  if (error is! ApiException) {
    return 'Không thể đổi điểm lúc này. Vui lòng thử lại.';
  }
  return switch (error.type) {
    ApiErrorType.unauthorized =>
      'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    ApiErrorType.forbidden => 'Tài khoản chưa được phép đổi điểm.',
    ApiErrorType.notFound => 'Không tìm thấy số dư điểm thưởng của tài khoản.',
    ApiErrorType.badRequest || ApiErrorType.validation =>
      error.message.toLowerCase().contains('insufficient')
          ? 'Số điểm hiện có không đủ để đổi.'
          : 'Số điểm yêu cầu không hợp lệ.',
    ApiErrorType.network ||
    ApiErrorType.timeout => 'Không thể kết nối. Hãy kiểm tra mạng và thử lại.',
    _ => 'Không thể đổi điểm lúc này. Vui lòng thử lại.',
  };
}
