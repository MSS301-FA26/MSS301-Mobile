import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mss301_mobile/core/demo/demo_scenario.dart';
import 'package:mss301_mobile/core/routing/app_routes.dart';
import 'package:mss301_mobile/features/account/application/wallet_bank_store.dart';
import 'package:mss301_mobile/features/account/data/repositories/account_providers.dart';
import 'package:mss301_mobile/features/auth/application/auth_session.dart';
import 'package:mss301_mobile/features/auth/data/auth_models.dart';

import 'support/pump_test_app.dart';

void main() {
  test(
    'saved bank details are isolated by user and survive a new store',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      const store = SecureWalletBankStore(FlutterSecureStorage());
      const bank = SavedBankAccount(
        bankName: 'VCB',
        accountNumber: '0123456789',
        accountHolder: 'NGUYEN MINH ANH',
      );
      await store.write(5101, bank);
      expect((await store.read(5101))?.accountNumber, '0123456789');
      expect(await store.read(5102), isNull);
      await store.clear(5101);
      expect(await store.read(5101), isNull);
    },
  );

  testWidgets('wallet submits a real-shaped withdrawal and reloads balance', (
    tester,
  ) async {
    final bankStore = _MemoryBankStore();
    await pumpTestApp(
      tester,
      authState: const AuthState(
        status: AuthStatus.authenticated,
        session: AuthSession(
          accessToken: 'test-access-token',
          refreshToken: 'test-refresh-token',
          tokenType: 'Bearer',
          expiresInMs: 3600000,
          user: AuthUser(
            id: DemoIds.user,
            email: 'customer@example.test',
            fullName: 'Test Customer',
            roles: ['CUSTOMER'],
          ),
          roles: ['CUSTOMER'],
        ),
      ),
      initialLocation: AppRoutes.wallet,
      size: const Size(390, 844),
      providerOverrides: [
        walletRepositoryProvider.overrideWith(
          (ref) => ref.watch(mockAccountStoreProvider),
        ),
        walletBankStoreProvider.overrideWithValue(bankStore),
        bankDirectoryProvider.overrideWith((ref) async => const []),
      ],
    );
    expect(find.byKey(const ValueKey('wallet-balance')), findsOneWidget);
    expect(find.text('500.000đ'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('wallet-toggle-withdraw')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm ngân hàng nhận tiền'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('wallet-bank-name')),
      'VCB',
    );
    await tester.enterText(
      find.byKey(const ValueKey('wallet-bank-number')),
      '0123456789',
    );
    await tester.enterText(
      find.byKey(const ValueKey('wallet-bank-holder')),
      'Nguyen Minh Anh',
    );
    await tester.ensureVisible(find.text('Lưu thông tin ngân hàng'));
    await tester.tap(find.text('Lưu thông tin ngân hàng'));
    await tester.pumpAndSettle();
    expect(bankStore.values[DemoIds.user]?.accountHolder, 'NGUYEN MINH ANH');

    await tester.enterText(
      find.byKey(const ValueKey('wallet-withdraw-amount')),
      '100000',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('wallet-withdraw-submit')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('wallet-withdraw-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gửi yêu cầu').last);
    await tester.pumpAndSettle();
    expect(find.text('400.000đ'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('wallet-withdrawal-8001')),
      findsOneWidget,
    );
  });
}

class _MemoryBankStore implements WalletBankStore {
  final values = <int, SavedBankAccount>{};

  @override
  Future<SavedBankAccount?> read(int userId) async => values[userId];

  @override
  Future<void> write(int userId, SavedBankAccount account) async {
    values[userId] = account;
  }

  @override
  Future<void> clear(int userId) async {
    values.remove(userId);
  }
}
