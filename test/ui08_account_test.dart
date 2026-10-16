import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/money/vnd_money.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/features/account/presentation/models/account_summary.dart';
import 'package:mss301_mobile/features/account/application/profile_controller.dart';
import 'package:mss301_mobile/features/account/data/models/account_dto.dart';
import 'package:mss301_mobile/features/account/presentation/widgets/account_profile_card.dart';
import 'package:mss301_mobile/features/account/presentation/widgets/membership_card.dart';
import 'package:mss301_mobile/features/account/presentation/widgets/account_menu.dart';

import 'support/pump_test_app.dart';

AccountSummary user({
  int? points = 123456789,
  VndMoney? balance = const VndMoney(987654321),
  String? avatar,
}) => AccountSummary(
  userId: 1,
  name: 'Nguyễn Thị Tường Vy với họ và tên dài để kiểm tra đầy đủ thông tin',
  initials: 'NV',
  email: 'customer.with.a.long.email.address@example.com',
  membershipTier: 'Diamond VIP',
  memberCode: 'CP-00000000000001',
  joinYear: 2026,
  points: points,
  walletBalance: balance,
  avatarUrl: avatar,
);

Future<void> openCards(
  WidgetTester tester,
  AccountSummary value, {
  double width = 390,
  double scale = 1,
  VoidCallback? retry,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 1000),
            textScaler: TextScaler.linear(scale),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AccountProfileCard(user: value),
                  MembershipCard(user: value, onQr: null, onRetry: retry),
                  WalletTile(user: value, onManage: () {}, onRetry: retry),
                  AccountMenu(
                    items: [
                      AccountMenuItemData(
                        icon: Icons.support_agent,
                        label: 'Trung tâm trợ giúp và chăm sóc khách hàng',
                        trailing:
                            'Nội dung phụ dài không được chiếm chỗ tên menu',
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 360.0, 390.0, 430.0]) {
    testWidgets(
      'account long name/email, points and wallet fit $width with large text',
      (tester) async {
        final value = user(avatar: 'https://invalid.example/avatar.png');
        await openCards(tester, value, width: width, scale: 1.6);
        expect(tester.takeException(), isNull);
        expect(find.text(value.name), findsOneWidget);
        expect(tester.widget<Text>(find.text(value.name)).maxLines, isNull);
        expect(tester.widget<Text>(find.text(value.email)).maxLines, isNull);
        expect(find.text('Diamond VIP'), findsOneWidget);
        expect(find.byIcon(Icons.person_rounded), findsOneWidget);
      },
    );
  }

  testWidgets(
    'failed balances are not zero and retry stays next to failed data',
    (tester) async {
      var retries = 0;
      final value = user(points: null, balance: null);
      await openCards(tester, value, retry: () => retries++);
      expect(find.text(value.name), findsOneWidget);
      expect(find.text('Chưa tải được điểm'), findsOneWidget);
      expect(find.text('Chưa tải được số dư'), findsOneWidget);
      expect(find.text('0đ'), findsNothing);
      await tester.ensureVisible(
        find.byKey(const ValueKey('account-points-retry')),
      );
      await tester.tap(find.byKey(const ValueKey('account-points-retry')));
      await tester.ensureVisible(
        find.byKey(const ValueKey('account-wallet-retry')),
      );
      await tester.tap(find.byKey(const ValueKey('account-wallet-retry')));
      expect(retries, 2);
    },
  );

  testWidgets('real zero balances display zero instead of retry', (
    tester,
  ) async {
    await openCards(tester, user(points: 0, balance: VndMoney.zero));
    expect(find.text('0'), findsOneWidget);
    expect(find.text('0đ'), findsOneWidget);
    expect(find.byKey(const ValueKey('account-wallet-retry')), findsNothing);
    expect(find.byKey(const ValueKey('account-points-retry')), findsNothing);
  });

  for (final profile in [true, false]) {
    testWidgets(
      '${profile ? 'profile' : 'password'} form scrolls with keyboard and large text without submitting',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpTestApp(
          tester,
          initialLocation: profile ? AppRoutes.profile : AppRoutes.security,
          size: const Size(320, 1000),
          providerOverrides: [
            currentProfileProvider.overrideWith(
              (ref) async => UserProfileDto.fromJson({
                'id': 5101,
                'fullName': user().name,
                'email': user().email,
                'status': 'ACTIVE',
                'createdAt': '2026-01-01T00:00:00Z',
                'updatedAt': '2026-01-01T00:00:00Z',
              }),
            ),
          ],
        );
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        final action = find.byKey(
          ValueKey(profile ? 'profile-save' : 'password-save'),
        );
        await tester.ensureVisible(action);
        await tester.pumpAndSettle();
        expect(action.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (profile) {
          final avatar = find.byKey(const ValueKey('profile-avatar'));
          await tester.ensureVisible(avatar);
          await tester.pumpAndSettle();
          await tester.tap(avatar);
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('avatar-url')), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.tap(find.text('Hủy'));
          await tester.pumpAndSettle();
        }
      },
    );
  }
}
