import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/app/app.dart';
import 'package:mss301_mobile/core/network/api_exception.dart';
import 'package:mss301_mobile/core/network/network_logger.dart';
import 'package:mss301_mobile/core/routing/app_router.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/features/account/application/profile_controller.dart';
import 'package:mss301_mobile/features/account/data/models/account_dto.dart';
import 'package:mss301_mobile/features/account/data/repositories/account_providers.dart';
import 'package:mss301_mobile/features/account/data/repositories/account_repositories.dart';
import 'package:mss301_mobile/features/account/data/repositories/remote_profile_repository.dart';
import 'package:mss301_mobile/features/account/presentation/providers/account_summary_provider.dart';
import 'package:mss301_mobile/features/auth/application/auth_session.dart';
import 'package:mss301_mobile/features/auth/data/auth_models.dart';

import 'support/fake_auth_session.dart';

class _Backend implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  int failStatus = 0;
  Completer<void>? gate;
  final profile = <String, dynamic>{
    'id': 5101,
    'email': 'customer@example.test',
    'fullName': 'Customer',
    'phone': '0901234567',
    'birthYear': 2000,
    'avatarUrl': null,
    'status': 'ACTIVE',
    'emailVerified': true,
    'phoneVerified': false,
    'roles': ['CUSTOMER'],
    'createdAt': '2026-01-01T00:00:00',
    'updatedAt': '2026-10-13T06:00:00',
  };
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options);
    await gate?.future;
    if (options.method == 'PUT' && failStatus == 0) {
      profile.addAll(options.data as Map<String, dynamic>);
    }
    if (options.path.endsWith('/avatar') && failStatus == 0) {
      profile['avatarUrl'] = (options.data as FormData).fields
          .firstWhere((f) => f.key == 'avatarUrl')
          .value;
    }
    return ResponseBody.fromString(
      jsonEncode({
        'success': failStatus == 0,
        'message': 'Old password is incorrect',
        'data': options.path.endsWith('/password') ? null : profile,
      }),
      failStatus == 0 ? 200 : failStatus,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _SwitchAuth extends FakeAuthSessionController {
  _SwitchAuth() : super(authenticatedCustomerState());
  void changeUser(int id) => state = AuthState(
    status: AuthStatus.authenticated,
    session: AuthSession(
      accessToken: 'test',
      refreshToken: 'test',
      tokenType: 'Bearer',
      expiresInMs: 1,
      user: AuthUser(
        id: id,
        email: 'other@example.test',
        fullName: 'Other',
        roles: const ['CUSTOMER'],
      ),
      roles: const ['CUSTOMER'],
    ),
  );
}

class _Verifier extends AvatarVerifier {
  Completer<void>? gate;
  @override
  Future<void> verify(String url, {CancelToken? cancelToken}) async {
    await gate?.future;
  }
}

class _BrokenWallet implements WalletRepository {
  @override
  Future<WalletDto> getWallet(int id) => Future.error(
    const ApiException(type: ApiErrorType.server, message: 'Wallet failed'),
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _BrokenLoyalty implements LoyaltyRepository {
  @override
  Future<LoyaltyDto> getLoyalty(int id) => Future.error(
    const ApiException(type: ApiErrorType.server, message: 'Loyalty failed'),
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Backend backend;
  late RemoteProfileRepository repository;
  late _Verifier verifier;
  late ProviderContainer container;
  setUp(() {
    backend = _Backend();
    verifier = _Verifier();
    final dio = Dio()..httpClientAdapter = backend;
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (e, h) => h.next(
          e.copyWith(
            error: const ApiException(
              type: ApiErrorType.badRequest,
              message: 'Old password is incorrect',
            ),
          ),
        ),
      ),
    );
    repository = RemoteProfileRepository(dio);
    container = ProviderContainer(
      overrides: [
        authSessionProvider.overrideWith(_SwitchAuth.new),
        profileRepositoryProvider.overrideWithValue(repository),
        remoteProfileRepositoryProvider.overrideWithValue(repository),
        avatarVerifierProvider.overrideWithValue(verifier),
        walletRepositoryProvider.overrideWithValue(_BrokenWallet()),
        loyaltyRepositoryProvider.overrideWithValue(_BrokenLoyalty()),
      ],
    );
  });
  tearDown(() => container.dispose());

  test('profile is JWT scoped, save refreshes session, empty optional fields become null', () async {
    final listener = container.listen(currentProfileProvider, (_, _) {});
    addTearDown(listener.close);
    final profile = await container.read(currentProfileProvider.future);
    expect(profile.id, 5101);
    expect(backend.calls.single.path, '/api/v1/users/me');
    expect(backend.calls.single.queryParameters, isEmpty);
    final before = container.read(authSessionProvider).session!;
    expect(
      await container
          .read(profileMutationProvider.notifier)
          .save(const UserProfileUpdateDto(fullName: 'New Customer')),
      isTrue,
    );
    final call = backend.calls.firstWhere((c) => c.method == 'PUT');
    expect(call.data, {
      'fullName': 'New Customer',
      'phone': null,
      'birthYear': null,
    });
    expect(
      container.read(authSessionProvider).session!.user.fullName,
      'New Customer',
    );
    expect(
      container.read(authSessionProvider).session!.accessToken,
      before.accessToken,
    );
    expect(
      (await container.read(currentProfileProvider.future)).fullName,
      'New Customer',
    );
  });

  test(
    'password errors are not success and request matches backend DTO',
    () async {
      backend.failStatus = 400;
      final controller = container.read(profileMutationProvider.notifier);
      expect(
        await controller.password('Old123!', 'New12345!', 'New12345!'),
        isFalse,
      );
      expect(
        container.read(profileMutationProvider).message,
        'Old password is incorrect',
      );
      backend.failStatus = 0;
      expect(
        await controller.password('Old123!', 'New12345!', 'New12345!'),
        isTrue,
      );
      expect(backend.calls.last.data, {
        'oldPassword': 'Old123!',
        'newPassword': 'New12345!',
        'confirmPassword': 'New12345!',
      });
      expect(
        container.read(profileMutationProvider).message,
        'Đã đổi mật khẩu.',
      );
    },
  );

  test(
    'avatar posts URL as multipart and verification after logout never posts',
    () async {
      final controller = container.read(profileMutationProvider.notifier);
      expect(
        await controller.avatar('https://example.test/avatar.png'),
        isTrue,
      );
      expect(backend.calls.last.path, '/api/v1/users/me/avatar');
      expect(
        container.read(authSessionProvider).session!.user.avatarUrl,
        'https://example.test/avatar.png',
      );
      verifier.gate = Completer<void>();
      final pending = controller.avatar('https://example.test/other.png');
      await container.read(authSessionProvider.notifier).logout();
      verifier.gate!.complete();
      expect(await pending, isFalse);
      expect(
        backend.calls.where((c) => c.path.endsWith('/avatar')),
        hasLength(1),
      );
    },
  );

  test(
    'double save is blocked and late response after logout is ignored',
    () async {
      backend.gate = Completer<void>();
      final controller = container.read(profileMutationProvider.notifier);
      final pending = controller.save(
        const UserProfileUpdateDto(fullName: 'Late'),
      );
      expect(
        await controller.save(
          const UserProfileUpdateDto(fullName: 'Duplicate'),
        ),
        isFalse,
      );
      await container.read(authSessionProvider.notifier).logout();
      backend.gate!.complete();
      expect(await pending, isFalse);
      expect(container.read(authSessionProvider).session, isNull);
      expect(container.read(profileMutationProvider).message, isNull);
    },
  );

  test(
    'wallet/loyalty errors keep real profile and do not fabricate balances',
    () async {
      final summary = await container.read(accountSummaryProvider.future);
      expect(summary.name, 'Customer');
      expect(summary.walletBalance, isNull);
      expect(summary.points, isNull);
    },
  );

  test('changing user while avatar validation waits cannot update the next account', () async {
    verifier.gate = Completer<void>();
    final pending = container
        .read(profileMutationProvider.notifier)
        .avatar('https://example.test/avatar.png');
    (container.read(authSessionProvider.notifier) as _SwitchAuth).changeUser(
      5102,
    );
    verifier.gate!.complete();
    expect(await pending, isFalse);
    expect(backend.calls, isEmpty);
    expect(container.read(authSessionProvider).session!.user.id, 5102);
    expect(container.read(authSessionProvider).session!.user.avatarUrl, isNull);
  });

  test('validation and logging match profile/password contract', () {
    expect(profileBirthYearError('2025', 2026), isNull);
    expect(profileBirthYearError('2027', 2026), isNotNull);
    expect(profileBirthYearError('invalid', 2026), isNotNull);
    expect(profilePhoneError('+84901234567'), isNull);
    expect(profilePhoneError('123'), isNotNull);
    expect(profilePhoneError(''), isNull);
    expect(newPasswordError('abcdefgh'), isNotNull);
    expect(newPasswordError('Strong123!'), isNull);
    expect(
      RedactedNetworkLogger.redact({
        'oldPassword': 'a',
        'newPassword': 'b',
        'confirmPassword': 'c',
      }),
      {
        'oldPassword': '[REDACTED]',
        'newPassword': '[REDACTED]',
        'confirmPassword': '[REDACTED]',
      },
    );
  });

  testWidgets(
    'cancelling avatar dialog keeps existing avatar and sends no update',
    (tester) async {
      appRouter.go(AppRoutes.profile);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const CinePremierApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('profile-avatar')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('avatar-url')),
        'https://example.test/image.png',
      );
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(backend.calls.where((call) => call.method == 'POST'), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('profile save error keeps entered fields and never shows saved', (
    tester,
  ) async {
    appRouter.go(AppRoutes.profile);
    await tester.binding.setSurfaceSize(const Size(320, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const CinePremierApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('profile-name')),
      'Edited Customer',
    );
    backend.failStatus = 400;
    await tester.ensureVisible(find.byKey(const ValueKey('profile-save')));
    await tester.tap(find.byKey(const ValueKey('profile-save')));
    await tester.pumpAndSettle();
    expect(find.text('Đã lưu hồ sơ.'), findsNothing);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('profile-name')))
          .controller!
          .text,
      'Edited Customer',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'security form requires confirmation, posts only valid input and shows server failure',
    (tester) async {
      appRouter.go(AppRoutes.security);
      backend.failStatus = 400;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const CinePremierApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('password-current')),
        'Old123!',
      );
      await tester.enterText(
        find.byKey(const ValueKey('password-new')),
        'New12345!',
      );
      await tester.tap(find.byKey(const ValueKey('password-save')));
      await tester.pumpAndSettle();
      expect(backend.calls, isEmpty);
      await tester.enterText(
        find.byKey(const ValueKey('password-confirm')),
        'New12345!',
      );
      await tester.tap(find.byKey(const ValueKey('password-save')));
      await tester.pumpAndSettle();
      expect(find.text('Old password is incorrect'), findsOneWidget);
      expect(find.text('Đã đổi mật khẩu.'), findsNothing);
    },
  );
}
