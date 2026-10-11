import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/constants/cinema_info.dart';
import 'package:mss301_mobile/core/money/vnd_money.dart';
import 'package:mss301_mobile/core/network/api_exception.dart';
import 'package:mss301_mobile/core/theme/app_theme.dart';
import 'package:mss301_mobile/features/account/data/models/account_dto.dart';
import 'package:mss301_mobile/features/account/data/models/account_enums.dart';
import 'package:mss301_mobile/features/account/presentation/models/account_summary.dart';
import 'package:mss301_mobile/features/account/presentation/pages/account_page.dart';
import 'package:mss301_mobile/features/account/presentation/providers/account_summary_provider.dart';
import 'package:mss301_mobile/features/auth/application/auth_session.dart';
import 'package:mss301_mobile/shared/widgets/app_shell.dart';
import 'package:mss301_mobile/shared/widgets/cinema_header.dart';
import 'package:mss301_mobile/shared/widgets/cinema_info_sheet.dart';
import 'package:mss301_mobile/shared/widgets/repository_state_pane.dart';

import 'support/fake_auth_session.dart';

const _longName = 'Nguyễn Khách Hàng Có Họ Và Tên Rất Dài Từ Hồ Sơ Google';
const _longEmail = 'khach.hang.co.email.rat.dai.tu.ho.so@example.test';
const _profile = AccountSummary(
  userId: 5101,
  name: _longName,
  initials: 'NG',
  email: _longEmail,
  memberCode: 'CP-0005101',
  joinYear: 2024,
);
const _balance = VndMoney(987654321000);

Future<void> _pump(
  WidgetTester tester,
  Widget widget, {
  double width = 400,
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 856));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    RepaintBoundary(
      key: const ValueKey('post-google-responsive-boundary'),
      child: ProviderScope(
        // Every probe has its own fixture state; do not reuse a cached wallet.
        key: UniqueKey(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: widget,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpAccount(
  WidgetTester tester, {
  required double width,
  double textScale = 1,
  bool walletFailed = false,
}) => _pump(
  tester,
  ProviderScope(
    overrides: [
      authSessionProvider.overrideWith(
        () => FakeAuthSessionController(authenticatedCustomerState()),
      ),
      accountSummaryProvider.overrideWith((ref) async => _profile),
      accountWalletProvider.overrideWith((ref) async {
        if (walletFailed) {
          throw const ApiException(
            type: ApiErrorType.server,
            statusCode: 500,
            message: 'Test-only server failure, not user-facing copy.',
          );
        }
        return WalletDto(id: 77, balance: _balance, createdAt: DateTime(2024));
      }),
      accountLoyaltyProvider.overrideWith(
        (ref) async => const LoyaltyDto(
          userId: 5101,
          userEmail: _longEmail,
          points: 123456789,
          totalPoints: 234567890,
          status: LoyaltyStatus.active,
        ),
      ),
    ],
    child: const AccountPage(),
  ),
  width: width,
  textScale: textScale,
);

Future<void> _capture(WidgetTester tester, String name) async {
  const capture = bool.fromEnvironment('CAPTURE_POST_GOOGLE_HEADER');
  if (!capture) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('post-google-responsive-boundary')),
  );
  await tester.runAsync(() async {
    final picture = await boundary.toImage(pixelRatio: 1);
    try {
      final data = await picture.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('build/post-google-responsive');
      await directory.create(recursive: true);
      await File('${directory.path}/$name.png')
          .writeAsBytes(data!.buffer.asUint8List());
    } finally {
      picture.dispose();
    }
  });
}

void _expectTouchTarget(WidgetTester tester, Finder finder) {
  final size = tester.getSize(finder);
  expect(size.width, greaterThanOrEqualTo(44));
  expect(size.height, greaterThanOrEqualTo(44));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // Use the bundled production fonts, not test Ahem metrics, for the repro.
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final width in [320.0, 390.0, 400.0, 430.0, 768.0]) {
    for (final textScale in [1.0, 2.0]) {
      testWidgets('Account error shell fits $width at ${textScale * 100}%', (
        tester,
      ) async {
        await _pump(
          tester,
          AppShell(
            currentIndex: 4,
            body: RepositoryStatePane.error(onRetry: () {}),
          ),
          width: width,
          textScale: textScale,
        );
        expect(find.byType(CinemaHeader), findsOneWidget);
        expect(find.text(CinemaInfo.name), findsOneWidget);
        expect(find.text('Đã xảy ra lỗi'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      for (final compact in [false, true]) {
        testWidgets(
          '${compact ? 'Home compact' : 'Account'} header fits $width '
          'at ${textScale * 100}%',
          (tester) async {
            await _pump(
              tester,
              Scaffold(
                appBar: CinemaHeader(
                  compact: compact,
                  onHome: () {},
                  onSearch: () {},
                  onAccount: () {},
                  onNotifications: () {},
                ),
              ),
              width: width,
              textScale: textScale,
            );
            expect(tester.takeException(), isNull);
          },
        );
      }

      for (final walletFailed in [false, true]) {
        testWidgets(
          'Whole Account ${walletFailed ? 'wallet500' : 'wallet success'} fits '
          '$width at ${textScale * 100}%',
          (tester) async {
            await _pumpAccount(
              tester,
              width: width,
              textScale: textScale,
              walletFailed: walletFailed,
            );
            expect(find.text(_longName), findsOneWidget);
            expect(find.text(_longEmail), findsOneWidget);
            expect(find.text('Vé xem phim của tôi'), findsOneWidget);
            expect(find.text('Lịch sử đơn bắp nước'), findsOneWidget);
            expect(find.text('123.456.789'), findsOneWidget);
            expect(find.text('Đã xảy ra lỗi'), findsNothing);
            expect(tester.takeException(), isNull);
            final wallet = find.text(
              walletFailed ? 'Không thể tải thông tin ví.' : _balance.format(),
            );
            await tester.ensureVisible(wallet);
            await tester.pumpAndSettle();
            expect(wallet, findsOneWidget);
            expect(tester.takeException(), isNull);
            await tester.ensureVisible(find.text('Đăng xuất'));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  for (final compact in [false, true]) {
    testWidgets(
      '${compact ? 'Home compact' : 'Account'} header keeps 44px targets '
      'and all navigation actions at320',
      (tester) async {
        var homeCalls = 0;
        var searchCalls = 0;
        var accountCalls = 0;
        var notificationsCalls = 0;
        await _pump(
          tester,
          Scaffold(
            appBar: CinemaHeader(
              compact: compact,
              onHome: () => homeCalls++,
              onSearch: () => searchCalls++,
              onAccount: () => accountCalls++,
              onNotifications: () => notificationsCalls++,
            ),
          ),
          width: 320,
          textScale: 2,
        );
        final logo = find.byKey(const ValueKey('header-home-logo'));
        final search = find.byTooltip('Tìm kiếm');
        final account = find.byTooltip('Tài khoản');
        for (final target in [logo, search, account]) {
          _expectTouchTarget(tester, target);
        }
        await tester.tap(logo);
        await tester.tap(search);
        await tester.tap(account);
        await tester.pump();
        expect(homeCalls, 1);
        expect(searchCalls, 1);
        expect(accountCalls, 1);
        if (compact) {
          expect(find.byIcon(Icons.notifications_none), findsNothing);
          expect(find.text('CINEPREMIER'), findsOneWidget);
        } else {
          final notifications = find.byTooltip('Thông báo • Sắp có');
          _expectTouchTarget(tester, notifications);
          await tester.tap(notifications);
          expect(notificationsCalls, 1);
          final location = find.ancestor(
            of: find.text(CinemaInfo.name),
            matching: find.byType(InkWell),
          );
          _expectTouchTarget(tester, location);
          await tester.tap(location);
          await tester.pumpAndSettle();
          expect(find.byType(CinemaInfoSheet), findsOneWidget);
          expect(tester.takeException(), isNull);
          final lastFeature = find.text(CinemaInfo.features.last);
          await tester.ensureVisible(lastFeature);
          await tester.pumpAndSettle();
          expect(lastFeature.hitTestable(), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('capture post-login shell and shared header evidence', (
    tester,
  ) async {
    for (final width in [320.0, 400.0, 430.0, 768.0]) {
      for (final compact in [false, true]) {
        await _pump(
          tester,
          AppShell(
            currentIndex: compact ? 0 : 4,
            compactHeader: compact,
            body: RepositoryStatePane.error(onRetry: () {}),
          ),
          width: width,
        );
        expect(tester.takeException(), isNull);
        final mode = compact ? 'home-compact' : 'account';
        await _capture(tester, 'header-$mode-${width.toInt()}');
      }
    }
  });

  testWidgets(
    'capture actual Account success and isolated wallet500 evidence',
    (tester) async {
      for (final width in [320.0, 400.0, 430.0, 768.0]) {
        for (final walletFailed in [false, true]) {
          await _pumpAccount(tester, width: width, walletFailed: walletFailed);
          final phase = walletFailed ? 'wallet500' : 'wallet-success';
          expect(tester.takeException(), isNull);
          await _capture(tester, 'account-$phase-${width.toInt()}-top');
          await tester.ensureVisible(
            find.text(
              walletFailed ? 'Không thể tải thông tin ví.' : _balance.format(),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await _capture(tester, 'account-$phase-${width.toInt()}-wallet');
        }
      }
    },
  );
}
