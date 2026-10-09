import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/money/vnd_money.dart';
import 'package:mss301_mobile/core/network/api_exception.dart';
import 'package:mss301_mobile/features/account/data/models/account_dto.dart';
import 'package:mss301_mobile/features/account/data/models/account_enums.dart';
import 'package:mss301_mobile/features/account/data/repositories/account_providers.dart';
import 'package:mss301_mobile/features/account/data/repositories/account_repositories.dart';
import 'package:mss301_mobile/features/account/presentation/providers/account_summary_provider.dart';

void main() {
  test(
    'prevents duplicate redemption and refreshes authoritative points',
    () async {
      final repository = _LoyaltyRepository();
      final container = ProviderContainer(
        overrides: [
          loyaltyRepositoryProvider.overrideWith((ref) => repository),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(loyaltyOverviewProvider, (_, _) {});
      addTearDown(subscription.close);
      await container.read(loyaltyOverviewProvider.future);

      final controller = container.read(
        loyaltyRedeemControllerProvider.notifier,
      );
      final first = controller.redeem(100);
      final duplicate = controller.redeem(200);
      expect(
        container.read(loyaltyRedeemControllerProvider).status,
        LoyaltyRedeemStatus.submitting,
      );
      expect(repository.redeemCallCount, 1);
      expect(repository.lastPoints, 100);

      repository.pending.complete(_loyalty(points: 900));
      await Future.wait([first, duplicate]);
      expect(
        container.read(loyaltyRedeemControllerProvider).status,
        LoyaltyRedeemStatus.success,
      );
      expect(
        (await container.read(loyaltyOverviewProvider.future)).$1.points,
        900,
      );
    },
  );

  test(
    'exposes insufficient points as an error without success state',
    () async {
      final repository = _LoyaltyRepository(
        error: const ApiException(
          type: ApiErrorType.badRequest,
          statusCode: 400,
          message: 'Insufficient loyalty points',
        ),
      );
      final container = ProviderContainer(
        overrides: [
          loyaltyRepositoryProvider.overrideWith((ref) => repository),
        ],
      );
      addTearDown(container.dispose);
      await container
          .read(loyaltyRedeemControllerProvider.notifier)
          .redeem(2000);
      final state = container.read(loyaltyRedeemControllerProvider);
      expect(state.status, LoyaltyRedeemStatus.error);
      expect(state.message, 'Số điểm hiện có không đủ để đổi.');
    },
  );
}

class _LoyaltyRepository implements LoyaltyRepository {
  _LoyaltyRepository({this.error});
  final Object? error;
  final pending = Completer<LoyaltyDto>();
  int redeemCallCount = 0;
  int? lastPoints;
  var _points = 1000;

  @override
  Future<LoyaltyDto> getLoyalty(int userId) async => _loyalty(points: _points);

  @override
  Future<LoyaltyConfigurationDto> getConfiguration() async =>
      const LoyaltyConfigurationDto(
        id: 1,
        earningRatePercent: 1,
        redemptionPoints: 100,
        redemptionValueVnd: VndMoney(10000),
        expiryMonth: 12,
        expiryDay: 31,
        expiryTime: '23:59:00',
      );

  @override
  Future<LoyaltyDto> redeemPoints(int points) {
    redeemCallCount++;
    lastPoints = points;
    if (error != null) return Future.error(error!);
    return pending.future.then((loyalty) {
      _points = loyalty.points;
      return loyalty;
    });
  }
}

LoyaltyDto _loyalty({required int points}) => LoyaltyDto(
  userId: 1,
  userEmail: 'customer@example.com',
  points: points,
  totalPoints: 1200,
  status: LoyaltyStatus.active,
);
