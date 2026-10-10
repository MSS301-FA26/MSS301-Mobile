import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mss301_mobile/core/config/feature_flags.dart';
import 'package:mss301_mobile/core/money/vnd_money.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/core/theme/app_theme.dart';
import 'package:mss301_mobile/features/account/presentation/models/account_summary.dart';
import 'package:mss301_mobile/features/account/presentation/pages/account_page.dart';
import 'package:mss301_mobile/features/account/presentation/providers/account_summary_provider.dart';
import 'package:mss301_mobile/features/account/presentation/widgets/account_menu.dart';
import 'package:mss301_mobile/features/account/presentation/widgets/account_profile_card.dart';
import 'package:mss301_mobile/features/account/presentation/widgets/membership_card.dart';
import 'package:mss301_mobile/features/auth/application/auth_session.dart';

import 'support/fake_auth_session.dart';

const _name = 'Nguyễn Khách Hàng Có Họ Và Tên Rất Dài Được Cung Cấp Từ Hồ Sơ';
const _email = 'khach.hang.co.dia.chi.email.rat.dai.duoc.cung.cap@example.test';
const _user = AccountSummary(
  userId: 8712,
  name: _name,
  initials: 'NS',
  email: _email,
  membershipTier: 'Diamond VIP',
  memberCode: 'CP-0008712',
  joinYear: 2024,
  points: 123456789,
  walletBalance: VndMoney(987654321000),
);

Future<void> _pumpComponent(
  WidgetTester tester,
  Widget component, {
  Size size = const Size(320, 844),
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: component,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _RecordingAuthSession extends FakeAuthSessionController {
  _RecordingAuthSession(super.initialState);

  int logoutCalls = 0;

  @override
  Future<bool> logout() async {
    logoutCalls++;
    return super.logout();
  }
}

Future<(GoRouter, _RecordingAuthSession)> _pumpAccount(
  WidgetTester tester, {
  bool authenticated = true,
  Future<AccountSummary> Function()? load,
  Size size = const Size(430, 844),
  double textScale = 1,
  bool settle = true,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final session = _RecordingAuthSession(
    authenticated ? authenticatedCustomerState() : unauthenticatedState,
  );
  final router = GoRouter(
    initialLocation: AppRoutes.account,
    routes: [
      GoRoute(path: AppRoutes.account, builder: (_, _) => const AccountPage()),
      for (final path in [
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.profile,
        AppRoutes.security,
        AppRoutes.orders,
        AppRoutes.foodOrders,
        AppRoutes.wallet,
        AppRoutes.points,
        AppRoutes.cinemaInfo,
        AppRoutes.policies,
        AppRoutes.support,
        AppRoutes.popBot,
        AppRoutes.vouchers,
        AppRoutes.vip,
        AppRoutes.favorites,
        AppRoutes.notifications,
        AppRoutes.previewFood,
      ])
        GoRoute(
          path: path,
          builder: (_, state) =>
              Scaffold(body: Text('Reached ${state.uri.path}')),
        ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authSessionProvider.overrideWith(() => session),
        accountSummaryProvider.overrideWith(
          (ref) => load?.call() ?? Future.value(_user),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.dark,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return (router, session);
}

Future<void> _reveal(WidgetTester tester, Finder target) async {
  final scrollable = find.byType(Scrollable).first;
  if (target.evaluate().isEmpty) {
    tester.state<ScrollableState>(scrollable).position.jumpTo(0);
    await tester.pump();
    await tester.scrollUntilVisible(target, 180, scrollable: scrollable);
  } else {
    await tester.ensureVisible(target);
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'account menu exposes keyboard focus above its surface and Enter activates',
    (tester) async {
      var taps = 0;
      await _pumpComponent(
        tester,
        AccountMenu(
          items: [
            AccountMenuItemData(
              icon: Icons.person_outline,
              label: 'Hồ sơ cá nhân',
              onTap: () => taps++,
            ),
          ],
        ),
      );
      final ink = find.descendant(
        of: find.byType(AccountMenuRow),
        matching: find.byType(InkWell),
      );
      final focusColor = tester.widget<InkWell>(ink).focusColor!;
      final focusSurface = Color.alphaBlend(
        focusColor,
        AppColors.primarySurface,
      );
      double contrast(Color first, Color second) {
        final a = first.computeLuminance();
        final b = second.computeLuminance();
        return a > b ? (a + 0.05) / (b + 0.05) : (b + 0.05) / (a + 0.05);
      }

      expect(contrast(focusSurface, AppColors.text), greaterThanOrEqualTo(4.5));
      expect(contrast(focusSurface, AppColors.gold), greaterThanOrEqualTo(4.5));
      expect(
        contrast(focusSurface, AppColors.textMuted),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        tester
            .widget<Material>(
              find.ancestor(of: ink, matching: find.byType(Material)).first,
            )
            .type,
        MaterialType.transparency,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(tester.binding.focusManager.primaryFocus?.hasFocus, isTrue);
      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find.descendant(
                      of: find.byType(AccountMenuRow),
                      matching: find.byType(DecoratedBox),
                    ),
                  )
                  .decoration
              as BoxDecoration;
      final border = decoration.border! as Border;
      expect(border.top.color, AppColors.focus);
      expect(border.top.width, greaterThanOrEqualTo(2));
      expect(
        contrast(border.top.color, AppColors.primarySurface),
        greaterThanOrEqualTo(3),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(taps, 1);
    },
  );

  testWidgets('account identity keeps full supplied name and email at320', (
    tester,
  ) async {
    await _pumpComponent(tester, const AccountProfileCard(user: _user));
    final name = tester.widget<Text>(find.text(_name));
    final email = tester.widget<Text>(find.text(_email));
    expect(name.maxLines, isNull);
    expect(name.overflow, isNot(TextOverflow.ellipsis));
    expect(email.maxLines, isNull);
    expect(email.overflow, isNot(TextOverflow.ellipsis));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'account menu keeps long label and trailing value readable at200%',
    (tester) async {
      const label = 'Trung tâm trợ giúp và chăm sóc khách hàng được cung cấp';
      const trailing = '12345678901234567890';
      await _pumpComponent(
        tester,
        AccountMenu(
          items: [
            AccountMenuItemData(
              icon: Icons.support_agent,
              label: label,
              trailing: trailing,
              status: 'Preview',
              onTap: () {},
            ),
          ],
        ),
        textScale: 2,
      );
      expect(tester.widget<Text>(find.text(label)).maxLines, isNull);
      expect(tester.widget<Text>(find.text(trailing)).maxLines, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('wallet real amount and management CTA fit at320', (
    tester,
  ) async {
    await _pumpComponent(tester, WalletTile(user: _user, onManage: () {}));
    expect(find.text(_user.walletBalance.format()), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CinePoints card does not claim derived VIP or currency value', (
    tester,
  ) async {
    await _pumpComponent(
      tester,
      const MembershipCard(user: _user, onQr: null),
      textScale: 2,
    );
    expect(find.text('123.456.789'), findsOneWidget);
    expect(find.textContaining('DIAMOND'), findsNothing);
    expect(find.textContaining('CP-0008712'), findsNothing);
    expect(find.textContaining('~'), findsNothing);
    final qr = tester.widget<TextButton>(find.byType(TextButton));
    expect(qr.onPressed, isNull);
    expect(find.text('Sắp có'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'account navigation starts with profile and security before booking',
    (tester) async {
      await _pumpAccount(tester);
      await _reveal(tester, find.text('Hồ sơ cá nhân'));
      final rows = tester.widgetList<AccountMenuRow>(
        find.byType(AccountMenuRow),
      );
      expect(rows.map((row) => row.item.label).take(4), [
        'Hồ sơ cá nhân',
        'Bảo mật & mật khẩu',
        'Vé xem phim của tôi',
        'Lịch sử đơn bắp nước',
      ]);
    },
  );

  for (final (label, destination) in [
    ('Hồ sơ cá nhân', AppRoutes.profile),
    ('Bảo mật & mật khẩu', AppRoutes.security),
    ('Vé xem phim của tôi', AppRoutes.orders),
    ('Lịch sử đơn bắp nước', AppRoutes.foodOrders),
    ('Quản lý ví', AppRoutes.wallet),
    ('CinePoints', AppRoutes.points),
    ('Thông tin rạp', AppRoutes.cinemaInfo),
    ('Chính sách', AppRoutes.policies),
    ('Trung tâm trợ giúp & CSKH', AppRoutes.support),
  ]) {
    testWidgets('$label keeps its existing production destination', (
      tester,
    ) async {
      final (router, _) = await _pumpAccount(tester);
      await _reveal(tester, find.text(label));
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, destination);
      expect(find.text('Reached $destination'), findsOneWidget);
    });
  }

  testWidgets(
    'guest has no fabricated identity and keeps auth and info actions',
    (tester) async {
      var loads = 0;
      final (router, _) = await _pumpAccount(
        tester,
        authenticated: false,
        load: () async {
          loads++;
          return _user;
        },
      );
      expect(loads, 0);
      expect(find.text(_name), findsNothing);
      for (final (label, destination) in [
        ('Đăng nhập', AppRoutes.login),
        ('Đăng ký', AppRoutes.register),
        ('Thông tin rạp', AppRoutes.cinemaInfo),
        ('Chính sách', AppRoutes.policies),
        ('Trung tâm trợ giúp & CSKH', AppRoutes.support),
      ]) {
        await _reveal(tester, find.text(label));
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, destination);
        router.go(AppRoutes.account);
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets('account loading does not fall back to fake profile values', (
    tester,
  ) async {
    final pending = Completer<AccountSummary>();
    await _pumpAccount(tester, load: () => pending.future, settle: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(_name), findsNothing);
    pending.complete(_user);
    await tester.pumpAndSettle();
    expect(find.text(_name), findsOneWidget);
  });

  testWidgets(
    'account error retains provider retry instead of a fake profile',
    (tester) async {
      var loads = 0;
      await _pumpAccount(
        tester,
        load: () async {
          if (++loads == 1) throw StateError('Profile unavailable');
          return _user;
        },
      );
      expect(find.text('Đã xảy ra lỗi'), findsOneWidget);
      expect(find.text(_name), findsNothing);
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(loads, 2);
      expect(find.text(_name), findsOneWidget);
    },
  );

  testWidgets('logout cancellation does not clear the session', (tester) async {
    final (_, session) = await _pumpAccount(tester);
    await _reveal(tester, find.text('Đăng xuất'));
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();
    expect(
      find.text('Bạn có chắc muốn kết thúc phiên đăng nhập?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Không'));
    await tester.pumpAndSettle();
    expect(session.logoutCalls, 0);
    expect(find.text(_name), findsOneWidget);
  });

  testWidgets('confirmed logout calls the existing signOut path once', (
    tester,
  ) async {
    final (_, session) = await _pumpAccount(tester);
    await _reveal(tester, find.text('Đăng xuất'));
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Đăng xuất'),
      ),
    );
    await tester.pumpAndSettle();
    expect(session.logoutCalls, 1);
    expect(find.text(_name), findsNothing);
    expect(find.text('Đăng nhập'), findsOneWidget);
  });

  testWidgets('preview actions retain exact flag gating and destinations', (
    tester,
  ) async {
    final (router, _) = await _pumpAccount(tester);
    for (final (enabled, label, route) in [
      (
        FeatureFlags.popBotPreview,
        'Trợ lý điện ảnh PopBot AI',
        AppRoutes.popBot,
      ),
      (
        FeatureFlags.voucherPreview,
        'Ưu đãi & Voucher cá nhân',
        AppRoutes.vouchers,
      ),
      (FeatureFlags.vipPreview, 'CinePremier VIP', AppRoutes.vip),
      (FeatureFlags.socialMoviePreview, 'Yêu thích', AppRoutes.favorites),
      (FeatureFlags.socialMoviePreview, 'Thông báo', AppRoutes.notifications),
      (
        FeatureFlags.independentFoodOrderPreview,
        'Đặt bắp nước độc lập',
        AppRoutes.previewFood,
      ),
    ]) {
      if (!enabled) {
        expect(find.text(label), findsNothing);
        continue;
      }
      final row = find.ancestor(
        of: find.text(label),
        matching: find.byType(AccountMenuRow),
      );
      expect(
        find.descendant(of: row, matching: find.text('Preview')),
        findsOneWidget,
      );
      await _reveal(tester, row);
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, route);
      router.go(AppRoutes.account);
      await tester.pumpAndSettle();
    }
    expect(find.textContaining('Thiết lập mật khẩu'), findsNothing);
    expect(find.textContaining('Liên kết thẻ'), findsNothing);
  });

  for (final width in [320.0, 430.0, 768.0]) {
    for (final guest in [false, true]) {
      testWidgets(
        'account ${guest ? 'guest' : 'customer'} fits $width at200%',
        (tester) async {
          await _pumpAccount(
            tester,
            authenticated: !guest,
            size: Size(width, 844),
            textScale: 2,
          );
          await _reveal(
            tester,
            find.text(guest ? 'Trung tâm trợ giúp & CSKH' : 'Đăng xuất'),
          );
          expect(tester.takeException(), isNull);
          if (!guest) {
            for (final row in tester.widgetList<AccountMenuRow>(
              find.byType(AccountMenuRow),
            )) {
              expect(
                tester.getSize(find.byWidget(row)).height,
                greaterThanOrEqualTo(48),
              );
            }
            expect(tester.widget<Text>(find.text(_name)).maxLines, isNull);
            expect(tester.widget<Text>(find.text(_email)).maxLines, isNull);
          }
        },
      );
    }
  }
}
