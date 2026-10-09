import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/demo/demo_scenario.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/models/account_dto.dart';
import '../../data/repositories/account_providers.dart';
import '../models/account_summary.dart';

final accountSummaryProvider = FutureProvider<AccountSummary>((ref) async {
  final profileRepository = ref.watch(profileRepositoryProvider);
  final walletRepository = ref.watch(walletRepositoryProvider);
  final loyaltyRepository = ref.watch(loyaltyRepositoryProvider);
  final profile = await profileRepository.getProfile(DemoIds.user);
  final wallet = await walletRepository.getWallet(DemoIds.user);
  final loyalty = await loyaltyRepository.getLoyalty(DemoIds.user);
  return mapAccountSummary(profile, wallet, loyalty);
});

final loyaltyOverviewProvider =
    FutureProvider<(LoyaltyDto, LoyaltyConfigurationDto)>((ref) async {
      final repository = ref.watch(loyaltyRepositoryProvider);
      final points = await repository.getLoyalty(DemoIds.user);
      final configuration = await repository.getConfiguration();
      return (points, configuration);
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
  @override
  LoyaltyRedeemState build() => const LoyaltyRedeemState();

  Future<void> redeem(int points) async {
    if (state.isSubmitting) return;
    state = const LoyaltyRedeemState(status: LoyaltyRedeemStatus.submitting);
    try {
      await ref.read(loyaltyRepositoryProvider).redeemPoints(points);
      ref.invalidate(loyaltyOverviewProvider);
      ref.invalidate(accountSummaryProvider);
      state = const LoyaltyRedeemState(
        status: LoyaltyRedeemStatus.success,
        message: 'Đổi điểm thành công. Số dư đã được cập nhật từ hệ thống.',
      );
    } catch (error) {
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
