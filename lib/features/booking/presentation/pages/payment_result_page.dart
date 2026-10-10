import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../payment/application/payment_launcher.dart';
import '../../application/booking_completion_controller.dart';
import '../widgets/payment_booking_summary.dart';
import '../widgets/payment_state_panel.dart';

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
    final realPayment =
        state.payment?.paymentUrl?.startsWith('mock://') != true;
    final icon = ready
        ? Icons.check_circle_rounded
        : failed
        ? Icons.error_outline_rounded
        : expired
        ? Icons.timer_off_outlined
        : state.phase == BookingCompletionPhase.openingPaymentGateway
        ? Icons.open_in_browser_rounded
        : Icons.account_balance_rounded;
    final color = ready
        ? AppColors.success
        : failed
        ? AppColors.error
        : expired
        ? AppColors.warning
        : AppColors.gold;
    final title = ready
        ? 'Booking đã được xác nhận'
        : failed
        ? 'Thanh toán thất bại'
        : expired
        ? 'Phiên giữ ghế đã hết'
        : state.phase == BookingCompletionPhase.openingPaymentGateway
        ? 'Đang mở VNPay'
        : state.phase == BookingCompletionPhase.verifyingBooking
        ? 'Đang xác minh booking'
        : realPayment
        ? 'VNPay'
        : 'VNPay Mock';

    final actions = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (realPayment &&
            state.payment?.paymentUrl != null &&
            !ready &&
            !failed &&
            !expired) ...[
          SizedBox(
            width: double.infinity,
            child: AppButton(
              key: const ValueKey('payment-launch'),
              label: 'Mở cổng thanh toán',
              onPressed: () => launchUrl(
                Uri.parse(state.payment!.paymentUrl!),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              key: const ValueKey('payment-refresh'),
              label: 'Kiểm tra trạng thái',
              variant: AppButtonVariant.secondary,
              onPressed: () => ref
                  .read(bookingCompletionProvider.notifier)
                  .refreshPaymentStatus(),
            ),
          ),
        ],
        if (!realPayment && !busy && !ready && !failed && !expired) ...[
          SizedBox(
            width: double.infinity,
            child: AppButton(
              key: const ValueKey('payment-open-webview'),
              label: 'Mở VNPay trong app',
              icon: Icons.open_in_browser_rounded,
              onPressed: () => ref
                  .read(bookingCompletionProvider.notifier)
                  .openPaymentGateway(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              key: const ValueKey('payment-open-deeplink'),
              label: 'Mở bằng app ngân hàng',
              icon: Icons.account_balance_wallet_rounded,
              variant: AppButtonVariant.secondary,
              onPressed: () => ref
                  .read(bookingCompletionProvider.notifier)
                  .openPaymentGateway(mode: PaymentLaunchMode.deepLink),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              key: const ValueKey('payment-success'),
              label: 'Mô phỏng callback thành công',
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
              label: 'Mô phỏng callback bị từ chối',
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
              onPressed: () => context.go(AppRoutes.ticket(state.booking!.id)),
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
    );
    final panel = PaymentStatePanel(
      icon: icon,
      color: color,
      title: title,
      message:
          state.message ??
          (ready
              ? 'Payment SUCCESS và booking PAID. Vé đã sẵn sàng.'
              : realPayment
              ? 'Mở VNPay hoặc quay lại ứng dụng chưa xác nhận thanh toán. Kiểm tra trạng thái để lấy kết quả từ hệ thống.'
              : 'VNPay Mock dùng cho luồng kiểm thử. Kết quả chỉ thay đổi sau callback mô phỏng.'),
      busy: busy,
      actions: actions,
      paymentUrl: !ready ? state.payment?.paymentUrl : null,
    );
    final hasSummary = state.payment != null || state.booking != null;
    final summary = PaymentBookingSummary(
      payment: state.payment,
      booking: state.booking,
    );

    return AppShell(
      currentIndex: 2,
      showBottomNavigation: false,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: const Text(
                      'Thanh toán',
                      style: AppTextStyles.screenTitle,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide =
                          constraints.maxWidth >= 700 &&
                          MediaQuery.textScalerOf(context).scale(16) <= 24;
                      if (wide && hasSummary) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: summary),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(child: panel),
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          panel,
                          if (hasSummary) ...[
                            const SizedBox(height: AppSpacing.lg),
                            summary,
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
