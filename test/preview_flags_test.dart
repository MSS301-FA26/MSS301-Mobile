import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/app/app.dart';
import 'package:mss301_mobile/core/config/feature_flags.dart';
import 'package:mss301_mobile/core/routing/app_router.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';

void main() {
  testWidgets('R7 preview build exposes isolated provisional flows', (
    tester,
  ) async {
    const allPreviewEnabled =
        FeatureFlags.independentFoodOrderPreview &&
        FeatureFlags.refundPreview &&
        FeatureFlags.voucherPreview &&
        FeatureFlags.vipPreview &&
        FeatureFlags.socialMoviePreview &&
        FeatureFlags.popBotPreview;
    if (!allPreviewEnabled) {
      expect(FeatureFlags.independentFoodOrderPreview, isFalse);
      return;
    }

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const ProviderScope(child: CinePremierApp()));

    final routes = <String, String>{
      AppRoutes.previewFood: 'Đặt bắp nước',
      AppRoutes.previewRefund(5101): 'Hoàn / Đổi vé',
      AppRoutes.vouchers: 'Voucher',
      AppRoutes.vip: 'CinePremier VIP',
      AppRoutes.favorites: 'Yêu thích',
      AppRoutes.notifications: 'Thông báo',
      AppRoutes.popBot: 'PopBot AI • Preview',
    };
    for (final entry in routes.entries) {
      appRouter.go(entry.key);
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsAtLeastNWidgets(1));
      expect(find.textContaining('Sắp có'), findsNothing);
    }
  });
}
