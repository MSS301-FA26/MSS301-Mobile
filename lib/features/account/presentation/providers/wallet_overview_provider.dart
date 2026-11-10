import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/account_dto.dart';
import '../../data/repositories/account_providers.dart';

class WalletOverview {
  const WalletOverview({
    required this.wallet,
    required this.transactions,
    required this.withdrawals,
  });

  final WalletDto wallet;
  final List<WalletTransactionDto> transactions;
  final List<WithdrawalDto> withdrawals;
}

final walletOverviewProvider = FutureProvider.family<WalletOverview, int>((
  ref,
  userId,
) async {
  final repository = ref.watch(walletRepositoryProvider);
  final (wallet, transactions, withdrawals) = await (
    repository.getWallet(userId),
    repository.getTransactions(userId),
    repository.getWithdrawals(userId),
  ).wait;
  return WalletOverview(
    wallet: wallet,
    transactions: transactions,
    withdrawals: withdrawals,
  );
});
