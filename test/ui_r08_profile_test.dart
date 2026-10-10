import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mss301_mobile/core/demo/demo_scenario.dart';
import 'package:mss301_mobile/core/money/vnd_money.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/core/theme/app_theme.dart';
import 'package:mss301_mobile/features/account/data/models/account_dto.dart';
import 'package:mss301_mobile/features/account/data/repositories/account_providers.dart';
import 'package:mss301_mobile/features/account/data/repositories/account_repositories.dart';
import 'package:mss301_mobile/features/account/presentation/models/account_summary.dart';
import 'package:mss301_mobile/features/account/presentation/pages/account_detail_pages.dart';
import 'package:mss301_mobile/features/account/presentation/providers/account_summary_provider.dart';
import 'package:mss301_mobile/shared/widgets/app_button.dart';

const _name = 'Tên khách hàng được cung cấp từ hồ sơ';
final _profile = UserProfileDto.fromJson({
  'id': 781,
  'email': 'supplied@example.test',
  'fullName': _name,
  'phone': '0912345678',
  'birthYear': 1998,
  'status': 'ACTIVE',
  'emailVerified': true,
  'phoneVerified': false,
  'roles': ['CUSTOMER'],
  'createdAt': '2024-10-10T12:00:00',
  'updatedAt': '2026-10-10T12:00:00',
});

class _ProfileRepository implements ProfileRepository {
  final loadIds = <int>[];
  final saved = <(int, UserProfileUpdateDto)>[];
  Completer<UserProfileDto>? loadPending;
  Completer<UserProfileDto>? savePending;
  Object? saveError;

  @override
  Future<UserProfileDto> getProfile(int userId) async {
    loadIds.add(userId);
    return loadPending == null ? _profile : await loadPending!.future;
  }

  @override
  Future<UserProfileDto> updateProfile(
    int userId,
    UserProfileUpdateDto request,
  ) async {
    saved.add((userId, request));
    if (saveError != null) throw saveError!;
    return savePending == null
        ? _profile.copyWith(
            fullName: request.fullName,
            phone: request.phone,
            birthYear: request.birthYear,
          )
        : await savePending!.future;
  }
}

const _summary = AccountSummary(
  userId: 781,
  name: _name,
  initials: 'TK',
  email: 'supplied@example.test',
  membershipTier: 'Member',
  memberCode: 'SUPPLIED-781',
  joinYear: 2024,
  points: 17,
  walletBalance: VndMoney(0),
);

Future<ProviderContainer> _pump(
  WidgetTester tester,
  _ProfileRepository repository, {
  Size size = const Size(430, 844),
  double textScale = 1,
  bool settle = true,
  void Function()? onSummaryBuild,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: '/profile',
    routes: [
      GoRoute(path: '/profile', builder: (_, _) => const ProfileEditPage()),
      GoRoute(
        path: AppRoutes.account,
        builder: (_, _) => const Scaffold(body: Text('Account destination')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileRepositoryProvider.overrideWithValue(repository),
        accountSummaryProvider.overrideWith((ref) async {
          onSummaryBuild?.call();
          return _summary;
        }),
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
  return ProviderScope.containerOf(
    tester.element(find.byType(ProfileEditPage)),
  );
}

Finder _field(String label) => find.ancestor(
  of: find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label,
  ),
  matching: find.byType(TextFormField),
);

Future<void> _reveal(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String label, String value) async {
  final field = _field(label);
  await _reveal(tester, field);
  await tester.enterText(field, value);
}

Future<void> _save(WidgetTester tester, {bool settle = true}) async {
  final save = find.byKey(const ValueKey('profile-save'));
  await _reveal(tester, save);
  await tester.tap(save);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

void main() {
  testWidgets('profile form stays comfortably constrained at 768 px', (
    tester,
  ) async {
    await _pump(tester, _ProfileRepository(), size: const Size(768, 844));
    expect(tester.getSize(_field('Họ và tên')).width, lessThanOrEqualTo(560));
    expect(tester.takeException(), isNull);
  });

  testWidgets('load uses current identity and supplied profile values only', (
    tester,
  ) async {
    final repository = _ProfileRepository();
    await _pump(tester, repository);
    expect(repository.loadIds, [DemoIds.user]);
    expect(
      tester.widget<TextFormField>(_field('Họ và tên')).controller!.text,
      _name,
    );
    expect(
      tester.widget<TextFormField>(_field('Số điện thoại')).controller!.text,
      '0912345678',
    );
    expect(
      tester.widget<TextFormField>(_field('Năm sinh')).controller!.text,
      '1998',
    );
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.text('supplied@example.test'), findsNothing);
    expect(find.text('Tiểu sử Điện ảnh'), findsNothing);
    expect(find.text('Thiết lập mật khẩu'), findsNothing);
  });

  testWidgets(
    'save preserves trimmed payload and invalidates account summary',
    (tester) async {
      var summaryBuilds = 0;
      final repository = _ProfileRepository();
      final container = await _pump(
        tester,
        repository,
        onSummaryBuild: () => summaryBuilds++,
      );
      final subscription = container.listen(accountSummaryProvider, (_, _) {});
      addTearDown(subscription.close);
      await container.read(accountSummaryProvider.future);
      expect(summaryBuilds, 1);
      await _enter(tester, 'Họ và tên', '  Khách hàng mới  ');
      await _enter(tester, 'Số điện thoại', '  0987654321  ');
      await _enter(tester, 'Năm sinh', '  2000  ');
      await _save(tester);
      expect(repository.saved, hasLength(1));
      final (userId, request) = repository.saved.single;
      expect(userId, DemoIds.user);
      expect(request.fullName, 'Khách hàng mới');
      expect(request.phone, '0987654321');
      expect(request.birthYear, 2000);
      expect(find.text('Đã lưu hồ sơ.'), findsOneWidget);
      await container.read(accountSummaryProvider.future);
      expect(summaryBuilds, 2);
    },
  );

  for (final (label, value, error) in [
    ('Họ và tên', 'A', 'Họ tên không hợp lệ'),
    ('Số điện thoại', '12345678', 'Số điện thoại không hợp lệ'),
    ('Năm sinh', '1899', 'Năm sinh không hợp lệ'),
    ('Năm sinh', '2021', 'Năm sinh không hợp lệ'),
  ]) {
    testWidgets('existing validation rejects $label=$value', (tester) async {
      final repository = _ProfileRepository();
      await _pump(tester, repository);
      await _enter(tester, label, value);
      await _save(tester);
      expect(repository.saved, isEmpty);
      expect(find.text(error), findsOneWidget);
    });
  }

  for (final year in ['', 'not-a-year']) {
    testWidgets('current optional parsing retains null for year "$year"', (
      tester,
    ) async {
      final repository = _ProfileRepository();
      await _pump(tester, repository);
      await _enter(tester, 'Số điện thoại', '');
      await _enter(tester, 'Năm sinh', year);
      await _save(tester);
      expect(repository.saved.single.$2.phone, '');
      expect(repository.saved.single.$2.birthYear, isNull);
      expect(find.text('Đã lưu hồ sơ.'), findsOneWidget);
    });
  }

  testWidgets('pending load keeps existing spinner until profile resolves', (
    tester,
  ) async {
    final pending = Completer<UserProfileDto>();
    final repository = _ProfileRepository()..loadPending = pending;
    await _pump(tester, repository, settle: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    pending.complete(_profile);
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(repository.loadIds, [DemoIds.user]);
  });

  testWidgets('pending save disables original CTA without duplicate requests', (
    tester,
  ) async {
    final pending = Completer<UserProfileDto>();
    final repository = _ProfileRepository()..savePending = pending;
    await _pump(tester, repository);
    await _save(tester, settle: false);
    final save = find.byKey(const ValueKey('profile-save'));
    expect(tester.widget<AppButton>(save).onPressed, isNull);
    expect(find.text('Đang lưu…'), findsOneWidget);
    await tester.tap(save);
    await tester.pump();
    expect(repository.saved, hasLength(1));
    expect(find.text('Đã lưu hồ sơ.'), findsNothing);
    pending.complete(_profile);
    await tester.pumpAndSettle();
    expect(tester.widget<AppButton>(save).onPressed, isNotNull);
    expect(find.text('Đã lưu hồ sơ.'), findsOneWidget);
  });

  testWidgets('save error remains recoverable without false success', (
    tester,
  ) async {
    const message =
        'Không thể cập nhật hồ sơ lúc này. Thông báo được cung cấp cần hiển thị đầy đủ để khách hàng đọc và thử lưu lại khi kết nối ổn định.';
    final repository = _ProfileRepository()
      ..saveError = const AccountConflictException(message);
    await _pump(tester, repository);
    await _save(tester);
    expect(find.text(message), findsOneWidget);
    expect(find.text('Đã lưu hồ sơ.'), findsNothing);
    expect(
      tester
          .widget<AppButton>(find.byKey(const ValueKey('profile-save')))
          .onPressed,
      isNotNull,
    );
    repository.saveError = null;
    await _save(tester);
    expect(repository.saved, hasLength(2));
    expect(find.text(message), findsNothing);
    expect(find.text('Đã lưu hồ sơ.'), findsOneWidget);
  });

  for (final width in [320.0, 430.0, 768.0]) {
    testWidgets('profile labels and save stay usable at $width px', (
      tester,
    ) async {
      await _pump(tester, _ProfileRepository(), size: Size(width, 844));
      for (final label in ['Họ và tên', 'Số điện thoại', 'Năm sinh']) {
        expect(_field(label), findsOneWidget);
      }
      final save = find.byKey(const ValueKey('profile-save'));
      await _reveal(tester, save);
      expect(save.hitTestable(), findsOneWidget);
      expect(tester.getSize(save).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('long feedback wraps at 320 px with 200 percent text', (
    tester,
  ) async {
    const message =
        'Không thể cập nhật hồ sơ lúc này. Vui lòng kiểm tra kết nối và thử lưu lại thông tin cá nhân sau khi mạng ổn định.';
    final repository = _ProfileRepository()
      ..saveError = const AccountConflictException(message);
    await _pump(tester, repository, size: const Size(320, 844), textScale: 2);
    await _save(tester);
    final feedback = find.text(message);
    await _reveal(tester, feedback);
    expect(tester.widget<Text>(feedback).maxLines, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard can reach save with the keyboard inset visible', (
    tester,
  ) async {
    final repository = _ProfileRepository();
    await _pump(tester, repository, size: const Size(320, 844));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    await _enter(tester, 'Họ và tên', 'Tên nhập từ bàn phím');
    final save = find.byKey(const ValueKey('profile-save'));
    await _reveal(tester, save);
    final focus = Focus.of(tester.element(find.text('Lưu thay đổi')));
    focus.requestFocus();
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    expect(save.hitTestable(), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(repository.saved.single.$2.fullName, 'Tên nhập từ bàn phím');
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile back retains account route', (tester) async {
    await _pump(tester, _ProfileRepository());
    await tester.tap(find.byTooltip('Quay lại tài khoản'));
    await tester.pumpAndSettle();
    expect(find.text('Account destination'), findsOneWidget);
  });
}
