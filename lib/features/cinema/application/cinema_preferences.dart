import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../auth/application/auth_session.dart';

abstract interface class CinemaPreferenceStore {
  Future<int?> read(String scope);
  Future<void> write(String scope, int? cinemaId);
}

class SecureCinemaPreferenceStore implements CinemaPreferenceStore {
  const SecureCinemaPreferenceStore(this.storage);

  final FlutterSecureStorage storage;

  String _key(String scope) => 'preferred_cinema_$scope';

  @override
  Future<int?> read(String scope) async =>
      int.tryParse(await storage.read(key: _key(scope)) ?? '');

  @override
  Future<void> write(String scope, int? cinemaId) => cinemaId == null
      ? storage.delete(key: _key(scope))
      : storage.write(key: _key(scope), value: '$cinemaId');
}

final cinemaPreferenceStoreProvider = Provider<CinemaPreferenceStore>(
  (ref) => const SecureCinemaPreferenceStore(FlutterSecureStorage()),
);

final preferredCinemaProvider =
    AsyncNotifierProvider<PreferredCinemaController, int?>(
      PreferredCinemaController.new,
    );

class PreferredCinemaController extends AsyncNotifier<int?> {
  String _scope() {
    final userId = ref.read(authSessionProvider).session?.user.id;
    return userId == null ? 'guest' : 'user_$userId';
  }

  @override
  Future<int?> build() async {
    ref.watch(authSessionProvider.select((state) => state.session?.user.id));
    return ref.watch(cinemaPreferenceStoreProvider).read(_scope());
  }

  Future<void> choose(int? cinemaId) async {
    final scope = _scope();
    await ref.read(cinemaPreferenceStoreProvider).write(scope, cinemaId);
    if (_scope() == scope) state = AsyncData(cinemaId);
  }
}
