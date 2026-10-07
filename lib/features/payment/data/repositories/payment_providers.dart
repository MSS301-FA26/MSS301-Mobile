import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import 'payment_repository.dart';
import 'remote_payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => RemotePaymentRepository(ref.watch(dioProvider)),
);
