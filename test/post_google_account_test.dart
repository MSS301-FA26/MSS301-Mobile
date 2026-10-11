import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mss301_mobile/core/config/api_config.dart';
import 'package:mss301_mobile/core/config/app_config.dart';
import 'package:mss301_mobile/core/money/vnd_money.dart';
import 'package:mss301_mobile/core/network/auth_interceptor.dart';
import 'package:mss301_mobile/core/network/dio_client.dart';
import 'package:mss301_mobile/core/network/network_providers.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/core/theme/app_theme.dart';
import 'package:mss301_mobile/features/account/data/models/account_dto.dart';
import 'package:mss301_mobile/features/account/data/models/account_enums.dart';
import 'package:mss301_mobile/features/account/data/repositories/account_providers.dart';
import 'package:mss301_mobile/features/account/data/repositories/account_repositories.dart';
import 'package:mss301_mobile/features/account/presentation/pages/account_page.dart';
import 'package:mss301_mobile/features/auth/application/auth_session.dart';
import 'package:mss301_mobile/features/auth/application/google_auth_provider.dart';
import 'package:mss301_mobile/features/auth/data/auth_models.dart';
import 'package:mss301_mobile/features/auth/data/auth_remote_data_source.dart';
import 'package:mss301_mobile/features/auth/data/google_auth_adapter.dart';
import 'package:mss301_mobile/features/auth/presentation/pages/auth_page.dart';
import 'package:mss301_mobile/shared/widgets/app_surface.dart';

import 'support/fake_auth_session.dart';
import 'support/google_auth_test_support.dart';

const _walletError = 'Không thể tải thông tin ví.';
const _loyaltyError = 'Không thể tải thông tin điểm thưởng.';
const _profileName = 'Google Customer';
const _walletAmount = VndMoney(325000);

void main() {
  testWidgets('Account renders real wallet, profile and independent loyalty', (
    tester,
  ) async {
    final harness = await _pumpAccount(tester, walletStatus: 200);

    expect(find.text(_profileName), findsOneWidget);
    expect(find.text('Hồ sơ cá nhân'), findsOneWidget);
    expect(find.text('Vé xem phim của tôi'), findsOneWidget);
    expect(find.text('Lịch sử đơn bắp nước'), findsOneWidget);
    expect(find.text(_walletAmount.format()), findsOneWidget);
    expect(find.text('7.850'), findsOneWidget);
    expect(find.text(_walletError), findsNothing);
    expect(harness.http.count('/api/v1/wallet'), 1);
    expect(harness.http.count('/api/v1/loyalty/me'), 1);
    expect(harness.container.read(authSessionProvider).isAuthenticated, isTrue);
  });

  testWidgets(
    'wallet500 isolates error without hiding Account or faking zero',
    (tester) async {
      final harness = await _pumpAccount(tester, walletStatus: 500);

      expect(find.text(_profileName), findsOneWidget);
      for (final label in [
        'Hồ sơ cá nhân',
        'Bảo mật & mật khẩu',
        'Vé xem phim của tôi',
        'Lịch sử đơn bắp nước',
        'CinePoints',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('7.850'), findsOneWidget);
      expect(find.text('Ví CinePremier'), findsOneWidget);
      expect(find.text(_walletError), findsOneWidget);
      expect(find.text('Đã xảy ra lỗi'), findsNothing);
      expect(find.text(const VndMoney(0).format()), findsNothing);
      expect(find.text(_walletAmount.format()), findsNothing);
      final walletSurface = find
          .ancestor(
            of: find.text(_walletError),
            matching: find.byType(AppSurface),
          )
          .first;
      expect(
        find.descendant(
          of: walletSurface,
          matching: find.text('Ví CinePremier'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: walletSurface, matching: find.text('Thử lại')),
        findsOneWidget,
      );
      expect(harness.http.count('/api/v1/wallet'), 1);
      expect(harness.http.count('/api/v1/auth/refresh'), 0);
      expect(harness.storage.clearCalls, 0);
      expect(
        harness.container.read(authSessionProvider).isAuthenticated,
        isTrue,
      );
    },
  );

  testWidgets(
    'wallet retry alone preserves Account state and blocks duplicates',
    (tester) async {
      final harness = await _pumpAccount(tester, walletStatus: 500);
      final session = harness.container.read(authSessionProvider).session;
      final profileCalls = harness.profile.calls;
      final loyaltyCalls = harness.http.count('/api/v1/loyalty/me');
      final pending = Completer<void>();
      harness.http
        ..walletStatus = 200
        ..walletGate = pending;
      await tester.ensureVisible(find.text('Thử lại'));
      await tester.pumpAndSettle();
      final retry = tester
          .widget<ButtonStyleButton>(
            find.ancestor(
              of: find.text('Thử lại'),
              matching: find.byWidgetPredicate(
                (widget) => widget is ButtonStyleButton,
              ),
            ),
          )
          .onPressed!;

      // Capture before the rebuild: a fast second tap must not start a second GET.
      retry();
      retry();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      expect(harness.http.count('/api/v1/wallet'), 2);
      expect(harness.profile.calls, profileCalls);
      expect(harness.http.count('/api/v1/loyalty/me'), loyaltyCalls);
      expect(find.text(_profileName), findsOneWidget);
      expect(find.text('7.850'), findsOneWidget);
      expect(
        harness.container.read(authSessionProvider).session,
        same(session),
      );
      pending.complete();
      await tester.pumpAndSettle();

      expect(find.text(_walletAmount.format()), findsOneWidget);
      expect(find.text(_walletError), findsNothing);
      expect(harness.http.count('/api/v1/wallet'), 2);
      expect(harness.profile.calls, profileCalls);
      expect(harness.http.count('/api/v1/loyalty/me'), loyaltyCalls);
      expect(harness.storage.clearCalls, 0);
    },
  );

  testWidgets('failed wallet retry stays scoped and remains recoverable', (
    tester,
  ) async {
    final harness = await _pumpAccount(tester, walletStatus: 500);
    final profileCalls = harness.profile.calls;
    final loyaltyCalls = harness.http.count('/api/v1/loyalty/me');
    await tester.ensureVisible(find.text('Thử lại'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(find.text(_walletError), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.text(_profileName), findsOneWidget);
    expect(find.text('7.850'), findsOneWidget);
    expect(find.text(const VndMoney(0).format()), findsNothing);
    expect(harness.http.count('/api/v1/wallet'), 2);
    expect(harness.profile.calls, profileCalls);
    expect(harness.http.count('/api/v1/loyalty/me'), loyaltyCalls);
    expect(harness.container.read(authSessionProvider).isAuthenticated, isTrue);
  });

  testWidgets(
    'pending initial wallet cannot delay profile, tickets or loyalty',
    (tester) async {
      final pending = Completer<void>();
      addTearDown(() {
        if (!pending.isCompleted) pending.complete();
      });
      final harness = await _pumpAccount(
        tester,
        walletStatus: 200,
        walletGate: pending,
        settle: false,
      );

      expect(pending.isCompleted, isFalse);
      expect(find.text(_profileName), findsOneWidget);
      expect(find.text('Hồ sơ cá nhân'), findsOneWidget);
      expect(find.text('Vé xem phim của tôi'), findsOneWidget);
      expect(find.text('Lịch sử đơn bắp nước'), findsOneWidget);
      expect(find.text('7.850'), findsOneWidget);
      expect(find.text('Ví CinePremier'), findsOneWidget);
      expect(find.text(_walletAmount.format()), findsNothing);
      expect(find.text(const VndMoney(0).format()), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(harness.http.count('/api/v1/wallet'), 1);
      expect(harness.http.count('/api/v1/loyalty/me'), 1);
      pending.complete();
      await tester.pumpAndSettle();

      expect(find.text(_walletAmount.format()), findsOneWidget);
      expect(find.text(_profileName), findsOneWidget);
      expect(find.text('7.850'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(harness.http.count('/api/v1/wallet'), 1);
      expect(harness.http.count('/api/v1/loyalty/me'), 1);
    },
  );

  testWidgets(
    'loyalty500 isolates error and retries only loyalty without fake points',
    (tester) async {
      final harness = await _pumpAccount(
        tester,
        walletStatus: 200,
        loyaltyStatus: 500,
      );
      final profileCalls = harness.profile.calls;
      final session = harness.container.read(authSessionProvider).session;

      expect(find.text(_profileName), findsOneWidget);
      expect(find.text('Hồ sơ cá nhân'), findsOneWidget);
      expect(find.text('Vé xem phim của tôi'), findsOneWidget);
      expect(find.text('Lịch sử đơn bắp nước'), findsOneWidget);
      expect(find.text(_walletAmount.format()), findsOneWidget);
      expect(find.text(_loyaltyError), findsOneWidget);
      expect(find.text('Đã xảy ra lỗi'), findsNothing);
      expect(find.text('CinePoints hiện có'), findsNothing);
      expect(find.text('7.850'), findsNothing);
      expect(find.text('0'), findsNothing);
      final loyaltySurface = find
          .ancestor(
            of: find.text(_loyaltyError),
            matching: find.byType(AppSurface),
          )
          .first;
      expect(
        find.descendant(of: loyaltySurface, matching: find.text('CinePoints')),
        findsOneWidget,
      );
      final retryFinder = find.descendant(
        of: loyaltySurface,
        matching: find.text('Thử lại'),
      );
      expect(retryFinder, findsOneWidget);
      await tester.ensureVisible(retryFinder);
      await tester.pumpAndSettle();
      harness.http.loyaltyStatus = 200;
      await tester.tap(retryFinder);
      await tester.pumpAndSettle();

      expect(find.text(_loyaltyError), findsNothing);
      expect(find.text('7.850'), findsOneWidget);
      expect(find.text(_walletAmount.format()), findsOneWidget);
      expect(harness.http.count('/api/v1/loyalty/me'), 2);
      expect(harness.http.count('/api/v1/wallet'), 1);
      expect(harness.profile.calls, profileCalls);
      expect(
        harness.container.read(authSessionProvider).session,
        same(session),
      );
      expect(harness.storage.clearCalls, 0);
      expect(harness.http.count('/api/v1/auth/refresh'), 0);
    },
  );

  testWidgets(
    'real Google app session reaches Account and authenticates wallet',
    (tester) async {
      final harness = await _pumpAccount(
        tester,
        walletStatus: 500,
        signInWithGoogle: true,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('auth-google-login')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('auth-google-login')));
      await tester.pumpAndSettle();

      expect(
        harness.router.routeInformationProvider.value.uri.path,
        AppRoutes.account,
      );
      expect(find.byType(AccountPage), findsOneWidget);
      expect(find.text(_profileName), findsOneWidget);
      expect(find.text(_walletError), findsOneWidget);
      final state = harness.container.read(authSessionProvider);
      expect(state.isAuthenticated, isTrue);
      // Boolean checks deliberately avoid putting token values in failure output.
      expect(harness.storage.accessToken?.isNotEmpty, isTrue);
      expect(harness.storage.refreshToken?.isNotEmpty, isTrue);
      final walletRequest = harness.http.requests.singleWhere(
        (request) => request.path == '/api/v1/wallet',
      );
      final authenticated =
          walletRequest.headers['Authorization'] ==
          'Bearer ${harness.storage.accessToken}';
      expect(authenticated, isTrue);
      expect(
        walletRequest.uri.toString(),
        'http://localhost:8080/api/v1/wallet',
      );
      expect(walletRequest.method, 'GET');
      expect(walletRequest.queryParameters, isEmpty);
      expect(harness.http.count('/api/v1/auth/google'), 1);
      expect(harness.http.count('/api/v1/auth/refresh'), 0);
      expect(harness.storage.clearCalls, 0);
    },
  );

  testWidgets(
    'wallet500 preserves Google session until confirmed existing logout',
    (tester) async {
      final harness = await _pumpAccount(
        tester,
        walletStatus: 500,
        signInWithGoogle: true,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('auth-google-login')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('auth-google-login')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Không'));
      await tester.pumpAndSettle();
      expect(
        harness.container.read(authSessionProvider).isAuthenticated,
        isTrue,
      );
      expect(harness.storage.clearCalls, 0);
      expect(harness.http.count('/api/v1/auth/logout'), 0);
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Đăng xuất'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        harness.container.read(authSessionProvider).isAuthenticated,
        isFalse,
      );
      expect(harness.storage.accessToken == null, isTrue);
      expect(harness.storage.refreshToken == null, isTrue);
      expect(harness.http.count('/api/v1/auth/logout'), 1);
      expect(find.text(_profileName), findsNothing);
      expect(find.text('Đăng nhập'), findsOneWidget);
    },
  );
}

Future<_AccountHarness> _pumpAccount(
  WidgetTester tester, {
  required int walletStatus,
  int loyaltyStatus = 200,
  Completer<void>? walletGate,
  bool signInWithGoogle = false,
  bool settle = true,
}) async {
  await tester.binding.setSurfaceSize(const Size(430, 856));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final http = _AccountHttpAdapter()
    ..walletStatus = walletStatus
    ..loyaltyStatus = loyaltyStatus
    ..walletGate = walletGate;
  final storage = GoogleAuthTokenStorage();
  final profile = _ProfileRepository();
  final dio = createDioClient(
    ApiConfig(
      appConfig: AppConfig(
        environment: AppEnvironment.production,
        apiBaseUrl: 'http://localhost:8080',
      ),
    ),
  )..httpClientAdapter = http;
  dio.interceptors.add(
    AuthInterceptor(
      storage: storage,
      refreshClient: AuthRemoteDataSource(dio),
      retryClient: dio,
      onRefreshFailure: storage.clear,
    ),
  );
  addTearDown(() => dio.close(force: true));
  final session = AuthState(
    status: AuthStatus.authenticated,
    session: AuthSession.fromJson(
      Map<String, Object?>.from(googleSessionEnvelope()['data']! as Map),
    ),
  );
  if (!signInWithGoogle) {
    storage.accessToken = session.session!.accessToken;
    storage.refreshToken = session.session!.refreshToken;
  }
  final router = GoRouter(
    initialLocation: signInWithGoogle
        ? '${AppRoutes.login}?continue=${Uri.encodeComponent(AppRoutes.account)}'
        : AppRoutes.account,
    routes: [
      GoRoute(path: AppRoutes.account, builder: (_, _) => const AccountPage()),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const AuthPage(mode: AuthPageMode.login),
      ),
      for (final route in [
        AppRoutes.home,
        AppRoutes.profile,
        AppRoutes.security,
        AppRoutes.orders,
        AppRoutes.foodOrders,
        AppRoutes.wallet,
        AppRoutes.points,
        AppRoutes.cinemaInfo,
        AppRoutes.policies,
        AppRoutes.support,
      ])
        GoRoute(
          path: route,
          builder: (_, state) => Scaffold(body: Text(state.uri.path)),
        ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dioProvider.overrideWithValue(dio),
        secureTokenStorageProvider.overrideWithValue(storage),
        profileRepositoryProvider.overrideWithValue(profile),
        googleAuthAdapterProvider.overrideWithValue(_GoogleAdapter()),
        if (!signInWithGoogle)
          authSessionProvider.overrideWith(
            () => FakeAuthSessionController(session),
          ),
      ],
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // Pump bounded frames only: the deliberately pending wallet spinner must
    // not be used with pumpAndSettle, which would wait indefinitely.
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
  }
  final element = tester.element(
    find.byType(signInWithGoogle ? AuthPage : AccountPage),
  );
  return _AccountHarness(
    router,
    ProviderScope.containerOf(element),
    http,
    storage,
    profile,
  );
}

class _AccountHarness {
  _AccountHarness(
    this.router,
    this.container,
    this.http,
    this.storage,
    this.profile,
  );
  final GoRouter router;
  final ProviderContainer container;
  final _AccountHttpAdapter http;
  final GoogleAuthTokenStorage storage;
  final _ProfileRepository profile;
}

class _AccountHttpAdapter implements HttpClientAdapter {
  int walletStatus = 200;
  int loyaltyStatus = 200;
  Completer<void>? walletGate;
  final requests = <RequestOptions>[];
  int count(String path) =>
      requests.where((request) => request.path == path).length;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    var status = 200;
    Object? body;
    switch (options.path) {
      case '/api/v1/auth/google':
        body = googleSessionEnvelope();
      case '/api/v1/auth/logout':
        body = {'success': true, 'data': null};
      case '/api/v1/wallet':
        await walletGate?.future;
        status = walletStatus;
        body = status == 200
            ? {
                'success': true,
                'data': {
                  'id': 818,
                  'balance': _walletAmount.amount,
                  'createdAt': '2026-10-01T00:00:00',
                },
              }
            : {
                'success': false,
                'message': 'Internal server error',
                'data': null,
              };
      case '/api/v1/loyalty/me':
        status = loyaltyStatus;
        body = status == 200
            ? {
                'success': true,
                'data': {
                  'userId': 5101,
                  'userEmail': 'customer@example.test',
                  'points': 7850,
                  'totalPoints': 11000,
                  'status': 'ACTIVE',
                },
              }
            : {
                'success': false,
                'message': 'Internal server error',
                'data': null,
              };
      default:
        throw StateError('Unexpected test request path ${options.path}');
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _ProfileRepository implements ProfileRepository {
  int calls = 0;

  @override
  Future<UserProfileDto> getProfile(int userId) async {
    calls++;
    return UserProfileDto(
      id: 5101,
      email: 'customer@example.test',
      fullName: _profileName,
      status: UserStatus.active,
      emailVerified: true,
      phoneVerified: false,
      roles: const ['CUSTOMER'],
      createdAt: DateTime(2026, 10, 1),
      updatedAt: DateTime(2026, 10, 1),
    );
  }

  @override
  Future<UserProfileDto> updateProfile(
    int userId,
    UserProfileUpdateDto request,
  ) => throw UnsupportedError('Read-only test profile boundary');
}

class _GoogleAdapter implements GoogleAuthAdapter {
  @override
  Future<void> initialize() async {}

  @override
  Future<String?> authenticate() async => googleCredential;

  @override
  Stream<String?> get credentials => const Stream.empty();
}
