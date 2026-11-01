import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../auth/application/auth_session.dart';

abstract interface class WatchlistStore {
  Future<Map<int, DateTime>> read(int userId);
  Future<void> write(int userId, Map<int, DateTime> items);
}

class SecureWatchlistStore implements WatchlistStore {
  const SecureWatchlistStore(this.storage);
  final FlutterSecureStorage storage;

  String _key(int userId) => 'watchlist_user_$userId';

  @override
  Future<Map<int, DateTime>> read(int userId) async {
    final raw = await storage.read(key: _key(userId));
    if (raw == null) return {};
    final decoded = jsonDecode(raw);
    if (decoded is! Map) throw const FormatException('Invalid watchlist');
    return {
      for (final entry in decoded.entries)
        int.parse(entry.key.toString()): DateTime.parse(entry.value.toString()),
    };
  }

  @override
  Future<void> write(int userId, Map<int, DateTime> items) => storage.write(
    key: _key(userId),
    value: jsonEncode({
      for (final entry in items.entries)
        '${entry.key}': entry.value.toUtc().toIso8601String(),
    }),
  );
}

final watchlistStoreProvider = Provider<WatchlistStore>(
  (ref) => const SecureWatchlistStore(FlutterSecureStorage()),
);

final watchlistProvider =
    AsyncNotifierProvider<WatchlistController, Map<int, DateTime>>(
      WatchlistController.new,
    );

class WatchlistController extends AsyncNotifier<Map<int, DateTime>> {
  bool _busy = false;

  @override
  Future<Map<int, DateTime>> build() async {
    final userId = ref.watch(
      authSessionProvider.select((auth) => auth.session?.user.id),
    );
    return userId == null ? {} : ref.read(watchlistStoreProvider).read(userId);
  }

  Future<bool> setSaved(int movieId, bool saved) async {
    final userId = ref.read(authSessionProvider).session?.user.id;
    if (userId == null || _busy) return false;
    _busy = true;
    try {
      final before = await future;
      if (ref.read(authSessionProvider).session?.user.id != userId) {
        return false;
      }
      final next = Map<int, DateTime>.from(before);
      if (saved) {
        next.putIfAbsent(movieId, DateTime.now().toUtc);
      } else {
        next.remove(movieId);
      }
      await ref.read(watchlistStoreProvider).write(userId, next);
      if (ref.mounted &&
          ref.read(authSessionProvider).session?.user.id == userId) {
        state = AsyncData(next);
      }
      return true;
    } finally {
      _busy = false;
    }
  }
}
