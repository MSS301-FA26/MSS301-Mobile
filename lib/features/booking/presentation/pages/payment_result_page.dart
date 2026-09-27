import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../application/booking_completion_controller.dart';

class PaymentResultPage extends ConsumerStatefulWidget {
  const PaymentResultPage({super.key, required this.paymentId});

  final int paymentId;

  @override
  ConsumerState<PaymentResultPage> createState() => _PaymentResultPageState();
}

class _PaymentResultPageState extends ConsumerState<PaymentResultPage> {
  var _attached = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingCompletionProvider);
    if (!_attached) {
      _attached = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(bookingCompletionProvider.notifier)
            .attachPayment(widget.paymentId);
      });
    }
    final failed = state.phase == BookingCompletionPhase.paymentFailed;
    final ready = state.phase == BookingCompletionPhase.ticketReady;
    final expired = state.phase == BookingCompletionPhase.expired;
    final busy = state.isBusy;
    final icon = ready
        ? Icons.check_circle_rounded
        : failed
        ? Icons.error_outline_rounded
        : expired
        ? Icons.timer_off_outlined
        : Icons.account_balance_rounded;
    final color = ready
        ? Colors.greenAccent
        : failed || expired
        ? AppColors.adultBadge
        : AppColors.gold;
    final title = ready
        ? 'Booking đã được xác nhận'
        : failed
        ? 'Thanh toán thất bại'
        : expired
        ? 'Phiên giữ ghế đã hết'
        : state.phase == BookingCompletionPhase.verifyingBooking
        ? 'Đang xác minh booking'
        : 'VNPay Mock';

    return AppShell(
      currentIndex: 2,
      showBottomNavigation: false,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Icon(icon, size: 76, color: color),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  state.message ??
                      (ready
                          ? 'Payment SUCCESS và booking PAID. Vé đã sẵn sàng.'
                          : 'Đây là cổng thanh toán giả lập. Không có giao dịch thật.'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (busy) const CircularProgressIndicator(),
                if (!busy && !ready && !failed && !expired) ...[
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      key: const ValueKey('payment-success'),
                      label: 'Mô phỏng thanh toán thành công',
                      onPressed: () async {
                        final success = await ref
                            .read(bookingCompletionProvider.notifier)
                            .simulateSuccess();
                        if (success) ref.invalidate(ordersProvider);
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      key: const ValueKey('payment-failure'),
                      label: 'Mô phỏng giao dịch bị từ chối',
                      variant: AppButtonVariant.secondary,
                      onPressed: () => ref
                          .read(bookingCompletionProvider.notifier)
                          .simulateFailure(),
                    ),
                  ),
                ],
                if (failed) ...[
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      key: const ValueKey('payment-retry'),
                      label: 'Thử lại',
                      onPressed: () async {
                        final payment = await ref
                            .read(bookingCompletionProvider.notifier)
                            .retryPayment();
                        if (payment != null && context.mounted) {
                          context.go(AppRoutes.payment(payment.id));
                        }
                      },
                    ),
                  ),
                ],
                if (ready) ...[
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      key: const ValueKey('open-ticket'),
                      label: 'Mở vé QR',
                      icon: Icons.qr_code_rounded,
                      onPressed: () =>
                          context.go(AppRoutes.ticket(state.booking!.id)),
                    ),
                  ),
                ],
                if (expired) ...[
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: 'Chọn lại suất chiếu',
                      onPressed: () => context.go(AppRoutes.showtimes),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
