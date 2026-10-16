import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'dart:async';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../payment/application/payment_launcher.dart';
import '../../application/booking_completion_controller.dart';
import '../widgets/booking_hold_countdown.dart';

class PaymentResultPage extends ConsumerStatefulWidget {
  const PaymentResultPage({super.key, required this.paymentId});

  final int paymentId;

  @override
  ConsumerState<PaymentResultPage> createState() => _PaymentResultPageState();
}

class _PaymentResultPageState extends ConsumerState<PaymentResultPage>
    with WidgetsBindingObserver {
  var _attached = false;
  Timer? _pollTimer;
  var _pollCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollCount = 0;
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted || ++_pollCount > 20) {
        _pollTimer?.cancel();
        return;
      }
      final phase = ref.read(bookingCompletionProvider).phase;
      if (phase == BookingCompletionPhase.ticketReady ||
          phase == BookingCompletionPhase.expired ||
          phase == BookingCompletionPhase.paymentFailed) {
        _pollTimer?.cancel();
        return;
      }
      await ref.read(bookingCompletionProvider.notifier).refreshPaymentStatus();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.resumed) {
      ref
          .read(bookingCompletionProvider.notifier)
          .attachPayment(widget.paymentId);
      _startPolling();
    } else {
      _pollTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingCompletionProvider);
    if (!_attached) {
      _attached = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(bookingCompletionProvider.notifier)
            .attachPayment(widget.paymentId);
        if (mounted &&
            ref
                    .read(bookingCompletionProvider)
                    .payment
                    ?.paymentUrl
                    ?.startsWith('mock://') !=
                true) {
          _startPolling();
        }
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
        ? Colors.greenAccent
        : failed || expired
        ? AppColors.adultBadge
        : AppColors.gold;
    final title = ready
        ? 'Đặt vé thành công'
        : failed
        ? 'Thanh toán thất bại'
        : expired
        ? 'Phiên giữ ghế đã hết'
        : state.phase == BookingCompletionPhase.openingPaymentGateway
        ? 'Đang mở VNPay'
        : state.phase == BookingCompletionPhase.verifyingBooking
        ? 'Đang xác minh booking'
        : state.phase == BookingCompletionPhase.error
        ? 'Chưa xác định kết quả'
        : realPayment
        ? 'Chờ kết quả thanh toán'
        : 'VNPay Mock';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop ||
            state.isBusy &&
                state.phase != BookingCompletionPhase.verifyingBooking) {
          return;
        }
        final leave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Rời màn hình thanh toán?'),
            content: const Text(
              'Đơn vẫn được lưu. Kiểm tra kết quả tại Đơn của tôi.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Ở lại'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Rời đi'),
              ),
            ],
          ),
        );
        if (leave == true && context.mounted) context.go(AppRoutes.orders);
      },
      child: AppShell(
        currentIndex: 2,
        showBottomNavigation: false,
        bookingTitle: 'Thanh toán',
        bookingSubtitle: 'Bước 4/4',
        onBookingBack:
            state.isBusy &&
                state.phase != BookingCompletionPhase.verifyingBooking
            ? null
            : () => Navigator.of(context).maybePop(),
        body: SafeArea(
          child: Column(
            children: [
              BookingHoldCountdown(booking: state.booking),
              Expanded(
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
                                  ? 'Thanh toán thành công. Vé của bạn đã sẵn sàng.'
                                  : failed
                                  ? 'Giao dịch chưa thành công. Kiểm tra đơn trước khi thử lại.'
                                  : expired
                                  ? 'Hạn giữ ghế đã hết. Nếu đã thanh toán, hãy kiểm tra lại đơn để nhận kết quả từ hệ thống.'
                                  : state.phase ==
                                        BookingCompletionPhase.verifyingBooking
                                  ? 'Đã nhận kết quả thanh toán, đang chờ hệ thống xác nhận vé.'
                                  : 'Mở VNPay để thanh toán. Khi quay lại, ứng dụng sẽ kiểm tra kết quả. Không cần tạo giao dịch mới khi kết quả chưa rõ.'),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (state.payment != null) ...[
                          Text(
                            state.payment!.amount.format(),
                            style: AppTextStyles.sectionTitle.copyWith(
                              color: AppColors.gold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        if (!realPayment &&
                            state.payment?.paymentUrl != null &&
                            !ready) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceRaised,
                              borderRadius: AppRadii.card,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              state.payment!.paymentUrl!,
                              key: const ValueKey('payment-url'),
                              textAlign: TextAlign.center,
                              style: AppTextStyles.caption,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        if (busy)
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                            ),
                            child: CircularProgressIndicator(),
                          ),
                        if (realPayment &&
                            state.payment?.paymentUrl != null &&
                            !ready &&
                            !failed &&
                            !expired &&
                            state.phase !=
                                BookingCompletionPhase.verifyingBooking) ...[
                          SizedBox(
                            width: double.infinity,
                            child: AppButton(
                              key: const ValueKey('payment-launch'),
                              label: 'Mở cổng thanh toán',
                              onPressed: busy
                                  ? null
                                  : () => ref
                                        .read(
                                          bookingCompletionProvider.notifier,
                                        )
                                        .openPaymentGateway(
                                          mode: PaymentLaunchMode.deepLink,
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
                              onPressed: busy
                                  ? null
                                  : () => ref
                                        .read(
                                          bookingCompletionProvider.notifier,
                                        )
                                        .refreshPaymentStatus(),
                            ),
                          ),
                        ],
                        if (realPayment &&
                            !ready &&
                            (failed ||
                                expired ||
                                state.phase ==
                                    BookingCompletionPhase.verifyingBooking ||
                                state.phase ==
                                    BookingCompletionPhase.error)) ...[
                          AppButton(
                            label: 'Kiểm tra lại đơn',
                            variant: AppButtonVariant.secondary,
                            onPressed: busy
                                ? null
                                : () async {
                                    await ref
                                        .read(
                                          bookingCompletionProvider.notifier,
                                        )
                                        .attachPayment(widget.paymentId);
                                    if (mounted) _startPolling();
                                  },
                          ),
                        ],
                        if (!realPayment &&
                            !busy &&
                            !ready &&
                            !failed &&
                            !expired) ...[
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
                                  .openPaymentGateway(
                                    mode: PaymentLaunchMode.deepLink,
                                  ),
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
                              onPressed: () => context.go(
                                AppRoutes.ticket(state.booking!.id),
                              ),
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
            ],
          ),
        ),
      ),
    );
  }
}
