import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/demo/demo_scenario.dart';
import '../../data/repositories/account_providers.dart';
import '../models/account_summary.dart';

final accountSummaryProvider = FutureProvider<AccountSummary>((ref) async {
  final profileRepository = ref.watch(profileRepositoryProvider);
  final walletRepository = ref.watch(walletRepositoryProvider);
  final loyaltyRepository = ref.watch(loyaltyRepositoryProvider);
  final profile = await profileRepository.getProfile(DemoIds.user);
  final wallet = await walletRepository.getWallet(DemoIds.user);
  final loyalty = await loyaltyRepository.getLoyalty(DemoIds.user);
  return mapAccountSummary(profile, wallet, loyalty);
});
