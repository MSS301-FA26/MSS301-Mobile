import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../movie/data/repositories/catalog_providers.dart';
import '../../../orders/data/repositories/booking_providers.dart';
import 'mock_payment_repository.dart';
import 'payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => MockPaymentRepository(
    ref.watch(appClockProvider),
    ref.watch(bookingRepositoryProvider),
  ),
);
