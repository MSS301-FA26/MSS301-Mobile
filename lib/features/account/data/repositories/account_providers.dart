import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../movie/data/repositories/catalog_providers.dart';
import 'account_repositories.dart';
import 'mock_account_repositories.dart';

final mockAccountStoreProvider = Provider<MockAccountStore>(
  (ref) => MockAccountStore(clock: ref.watch(appClockProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ref.watch(mockAccountStoreProvider),
);

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => ref.watch(mockAccountStoreProvider),
);

final loyaltyRepositoryProvider = Provider<LoyaltyRepository>(
  (ref) => ref.watch(mockAccountStoreProvider),
);
