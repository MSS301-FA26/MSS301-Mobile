import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum PendingPaymentKind { booking, foodOrder }

class PendingPaymentReturn {
  const PendingPaymentReturn({
    required this.userId,
    required this.paymentId,
    required this.orderId,
    required this.kind,
  });

  final int userId;
  final int paymentId;
  final int orderId;
  final PendingPaymentKind kind;
}

abstract interface class PaymentReturnCheckpointStore {
  Future<void> save(PendingPaymentReturn pending);
  Future<PendingPaymentReturn?> read(int userId);
  Future<void> clear(int userId, {int? paymentId});
}

class SecurePaymentReturnCheckpointStore
    implements PaymentReturnCheckpointStore {
  const SecurePaymentReturnCheckpointStore();

  static const _storage = FlutterSecureStorage();
  String _key(int userId) => 'payment_return_v1_$userId';

  @override
  Future<void> save(PendingPaymentReturn pending) async {
    try {
      await _storage.write(
        key: _key(pending.userId),
        value: jsonEncode({
          'userId': pending.userId,
          'paymentId': pending.paymentId,
          'orderId': pending.orderId,
          'kind': pending.kind.name,
        }),
      );
    } catch (_) {
      // The order history remains available if device storage is unavailable.
    }
  }

  @override
  Future<PendingPaymentReturn?> read(int userId) async {
    try {
      final raw = await _storage.read(key: _key(userId));
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final pending = PendingPaymentReturn(
        userId: json['userId'] as int,
        paymentId: json['paymentId'] as int,
        orderId: json['orderId'] as int,
        kind: PendingPaymentKind.values.byName(json['kind'] as String),
      );
      return pending.userId == userId &&
              pending.paymentId > 0 &&
              pending.orderId > 0
          ? pending
          : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clear(int userId, {int? paymentId}) async {
    try {
      if (paymentId != null) {
        final saved = await read(userId);
        if (saved?.paymentId != paymentId) return;
      }
      await _storage.delete(key: _key(userId));
    } catch (_) {
      // A later read still validates every stored payment against the server.
    }
  }
}

final paymentReturnCheckpointStoreProvider =
    Provider<PaymentReturnCheckpointStore>(
      (ref) => const SecurePaymentReturnCheckpointStore(),
    );
