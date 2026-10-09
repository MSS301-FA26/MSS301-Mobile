import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/money/vnd_money.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/features/account/data/models/account_dto.dart';
import 'package:mss301_mobile/features/account/data/models/account_enums.dart';
import 'package:mss301_mobile/features/account/data/repositories/account_providers.dart';
import 'package:mss301_mobile/features/account/data/repositories/account_repositories.dart';

import 'support/pump_test_app.dart';

void main() {
  testWidgets('confirms redemption and renders refreshed backend points', (
    tester,
  ) async {
    final repository = _LoyaltyRepository();
    await pumpTestApp(
      tester,
      initialLocation: AppRoutes.points,
      providerOverrides: [
        loyaltyRepositoryProvider.overrideWith((ref) => repository),
      ],
    );

    expect(find.text('800 điểm'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('loyalty-redeem-points')),
      '250',
    );
    await tester.tap(find.byKey(const ValueKey('loyalty-redeem-submit')));
    await tester.pumpAndSettle();

    expect(
      find.text('Đổi 250 điểm từ số dư hiện tại 800 điểm?'),
      findsOneWidget,
    );
    expect(repository.redeemCalls, 0);
    await tester.tap(find.text('Xác nhận đổi'));
    await tester.pumpAndSettle();

    expect(repository.redeemCalls, 1);
    expect(repository.lastPoints, 250);
    expect(find.text('550 điểm'), findsOneWidget);
    expect(find.textContaining('Đổi điểm thành công'), findsOneWidget);
  });

  testWidgets('does not open confirmation for an invalid amount', (
    tester,
  ) async {
    final repository = _LoyaltyRepository();
    await pumpTestApp(
      tester,
      initialLocation: AppRoutes.points,
      providerOverrides: [
        loyaltyRepositoryProvider.overrideWith((ref) => repository),
      ],
    );
    await tester.enterText(
      find.byKey(const ValueKey('loyalty-redeem-points')),
      '0',
    );
    await tester.tap(find.byKey(const ValueKey('loyalty-redeem-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Số điểm phải lớn hơn 0.'), findsOneWidget);
    expect(find.text('Xác nhận đổi điểm'), findsNothing);
    expect(repository.redeemCalls, 0);
  });
}

class _LoyaltyRepository implements LoyaltyRepository {
  var points = 800;
  var redeemCalls = 0;
  int? lastPoints;

  @override
  Future<LoyaltyDto> getLoyalty(int userId) async => LoyaltyDto(
    userId: userId,
    userEmail: 'customer@example.com',
    points: points,
    totalPoints: 1200,
    status: LoyaltyStatus.active,
  );

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
  Future<LoyaltyDto> redeemPoints(int pointsToRedeem) async {
    redeemCalls++;
    lastPoints = pointsToRedeem;
    points -= pointsToRedeem;
    return getLoyalty(1);
  }
}
