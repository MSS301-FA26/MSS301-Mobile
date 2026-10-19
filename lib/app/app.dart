import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/routing/app_router.dart';
import '../core/routing/app_routes.dart';
import '../features/auth/application/auth_session.dart';
import '../features/food/data/repositories/standalone_food_repository.dart';
import '../features/orders/data/repositories/booking_providers.dart';
import '../features/payment/application/payment_return_checkpoint.dart';
import '../features/payment/data/repositories/payment_providers.dart';

class CinePremierApp extends ConsumerStatefulWidget {
  const CinePremierApp({super.key});

  @override
  ConsumerState<CinePremierApp> createState() => _CinePremierAppState();
}

class _CinePremierAppState extends ConsumerState<CinePremierApp> {
  int? _checkedUserId;

  Future<void> _resumePayment(int userId) async {
    final store = ref.read(paymentReturnCheckpointStoreProvider);
    final pending = await store.read(userId);
    if (pending == null || !mounted) return;
    try {
      final payment = await ref
          .read(paymentRepositoryProvider)
          .getPayment(pending.paymentId);
      if (payment == null ||
          payment.userId != userId ||
          (pending.kind == PendingPaymentKind.booking &&
              payment.bookingId != pending.orderId) ||
          (pending.kind == PendingPaymentKind.foodOrder &&
              payment.foodOrderId != pending.orderId)) {
        await store.clear(userId, paymentId: pending.paymentId);
        return;
      }
      if (pending.kind == PendingPaymentKind.booking) {
        final booking = await ref
            .read(bookingRepositoryProvider)
            .getBooking(pending.orderId);
        if (booking == null || booking.userId != userId) {
          await store.clear(userId, paymentId: pending.paymentId);
          return;
        }
      } else {
        // The food order endpoint checks ownership for the signed-in user.
        await ref.read(standaloneFoodRepositoryProvider).get(pending.orderId);
      }
      if (!mounted ||
          ref.read(authSessionProvider).session?.user.id != userId ||
          appRouter.routeInformationProvider.value.uri.path != AppRoutes.home) {
        return;
      }
      appRouter.go(
        pending.kind == PendingPaymentKind.booking
            ? AppRoutes.payment(pending.paymentId)
            : AppRoutes.foodOrderDetail(pending.orderId),
      );
    } catch (_) {
      // Keep the checkpoint for a later launch when the network is available.
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(
      authSessionProvider.select((auth) => auth.session?.user.id),
    );
    if (_checkedUserId != userId) {
      _checkedUserId = userId;
      if (userId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _resumePayment(userId);
        });
      }
    }
    return MaterialApp.router(
      title: 'CinePremier',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
