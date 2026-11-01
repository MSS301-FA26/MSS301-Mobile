import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SavedBankAccount {
  const SavedBankAccount({
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
  });

  final String bankName;
  final String accountNumber;
  final String accountHolder;

  factory SavedBankAccount.fromJson(Map<String, Object?> json) {
    final bankName = json['bankName']?.toString() ?? '';
    final accountNumber = json['accountNumber']?.toString() ?? '';
    final accountHolder = json['accountHolder']?.toString() ?? '';
    if (bankName.isEmpty || accountNumber.isEmpty || accountHolder.isEmpty) {
      throw const FormatException('Invalid saved bank account');
    }
    return SavedBankAccount(
      bankName: bankName,
      accountNumber: accountNumber,
      accountHolder: accountHolder,
    );
  }

  Map<String, Object?> toJson() => {
    'bankName': bankName,
    'accountNumber': accountNumber,
    'accountHolder': accountHolder,
  };
}

abstract interface class WalletBankStore {
  Future<SavedBankAccount?> read(int userId);
  Future<void> write(int userId, SavedBankAccount account);
  Future<void> clear(int userId);
}

class SecureWalletBankStore implements WalletBankStore {
  const SecureWalletBankStore(this.storage);
  final FlutterSecureStorage storage;

  String _key(int userId) => 'wallet_bank_user_$userId';

  @override
  Future<SavedBankAccount?> read(int userId) async {
    final raw = await storage.read(key: _key(userId));
    if (raw == null) return null;
    return SavedBankAccount.fromJson(
      Map<String, Object?>.from(jsonDecode(raw) as Map),
    );
  }

  @override
  Future<void> write(int userId, SavedBankAccount account) =>
      storage.write(key: _key(userId), value: jsonEncode(account.toJson()));

  @override
  Future<void> clear(int userId) => storage.delete(key: _key(userId));
}

final walletBankStoreProvider = Provider<WalletBankStore>(
  (ref) => const SecureWalletBankStore(FlutterSecureStorage()),
);

final savedBankAccountProvider = FutureProvider.family<SavedBankAccount?, int>(
  (ref, userId) => ref.watch(walletBankStoreProvider).read(userId),
);

class BankOption {
  const BankOption(this.shortName, this.fullName);
  final String shortName;
  final String fullName;
}

/// Public bank metadata only. A separate Dio avoids sending app auth tokens
/// to the VietQR host; the form still accepts a bank name if this fails.
final bankDirectoryProvider = FutureProvider<List<BankOption>>((ref) async {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );
  final response = await dio.get('https://api.vietqr.io/v2/banks');
  final body = response.data;
  if (body is! Map || body['data'] is! List) {
    throw const FormatException('Invalid bank directory');
  }
  final banks = <BankOption>[];
  final seen = <String>{};
  for (final entry in body['data'] as List) {
    if (entry is! Map) continue;
    final short = (entry['short_name'] ?? entry['shortName'])?.toString() ?? '';
    final name = entry['name']?.toString() ?? short;
    if (short.isNotEmpty && seen.add(short)) {
      banks.add(BankOption(short, name));
    }
  }
  banks.sort((a, b) => a.shortName.compareTo(b.shortName));
  return banks;
});
