import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/features/auth/application/auth_session.dart';
import 'package:mss301_mobile/features/auth/data/auth_models.dart';
import 'package:mss301_mobile/features/movie/application/watchlist.dart';

class MemoryWatchlistStore implements WatchlistStore {
  final values = <int, Map<int, DateTime>>{};
  bool failWrite = false;

  @override
  Future<Map<int, DateTime>> read(int userId) async =>
      Map.of(values[userId] ?? const {});

  @override
  Future<void> write(int userId, Map<int, DateTime> items) async {
    if (failWrite) throw StateError('storage full');
    values[userId] = Map.of(items);
  }
}

AuthState signedIn(int id) => AuthState(
  status: AuthStatus.authenticated,
  session: AuthSession(
    accessToken: 'token',
    refreshToken: 'refresh',
    tokenType: 'Bearer',
    expiresInMs: 1000,
    user: AuthUser(
      id: id,
      email: '$id@example.test',
      fullName: 'Customer',
      roles: const ['CUSTOMER'],
    ),
    roles: const ['CUSTOMER'],
  ),
);

class SwitchAuth extends AuthSessionController {
  @override
  AuthState build() => signedIn(1);
  void change(int? id) => state = id == null
      ? const AuthState(status: AuthStatus.unauthenticated)
      : signedIn(id);
}

void main() {
  test('persists IDs per account and restores them after restart', () async {
    final store = MemoryWatchlistStore();
    ProviderContainer create() => ProviderContainer(
      overrides: [
        watchlistStoreProvider.overrideWithValue(store),
        authSessionProvider.overrideWith(SwitchAuth.new),
      ],
    );
    final first = create();
    addTearDown(first.dispose);
    expect(await first.read(watchlistProvider.future), isEmpty);
    expect(
      await first.read(watchlistProvider.notifier).setSaved(42, true),
      isTrue,
    );
    expect(
      await first.read(watchlistProvider.notifier).setSaved(42, true),
      isTrue,
    );
    expect(store.values[1]!.length, 1);
    (first.read(authSessionProvider.notifier) as SwitchAuth).change(2);
    expect(await first.read(watchlistProvider.future), isEmpty);
    final second = create();
    addTearDown(second.dispose);
    expect((await second.read(watchlistProvider.future)).keys, contains(42));
  });

  test('failed write does not report success or replace saved state', () async {
    final store = MemoryWatchlistStore()..failWrite = true;
    final container = ProviderContainer(
      overrides: [
        watchlistStoreProvider.overrideWithValue(store),
        authSessionProvider.overrideWith(SwitchAuth.new),
      ],
    );
    addTearDown(container.dispose);
    expect(await container.read(watchlistProvider.future), isEmpty);
    await expectLater(
      container.read(watchlistProvider.notifier).setSaved(7, true),
      throwsStateError,
    );
    expect(container.read(watchlistProvider).asData!.value, isEmpty);
  });
}
