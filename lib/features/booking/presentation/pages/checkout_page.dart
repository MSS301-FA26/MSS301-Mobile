import '../../../../core/time/vietnam_time.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/checkout_summary.dart';
import '../../../movie/data/models/catalog_enums.dart';
import '../../application/booking_completion_controller.dart';
import '../widgets/booking_hold_countdown.dart';
import '../widgets/booking_progress.dart';

class CheckoutPage extends ConsumerWidget {
  const CheckoutPage({super.key, required this.bookingId});

  final int bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingCompletionProvider);
    final booking = state.booking;
    final quote = state.quote;
    if (booking == null || quote == null || booking.id != bookingId) {
      return AppShell(
        currentIndex: 2,
        showBottomNavigation: false,
        bookingTitle: 'Xác nhận đơn',
        bookingSubtitle: 'Bước 4/4',
        onBookingBack: () => context.go(AppRoutes.concessions(bookingId)),
        body: Center(
          child: AppButton(
            label: 'Quay lại bắp nước',
            onPressed: () => context.go(AppRoutes.concessions(bookingId)),
          ),
        ),
      );
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !state.isBusy) {
          context.go(AppRoutes.concessions(bookingId));
        }
      },
      child: AppShell(
        currentIndex: 2,
        showBottomNavigation: false,
        bookingTitle: 'Xác nhận đơn',
        bookingSubtitle: 'Bước 4/4',
        onBookingBack: state.isBusy
            ? null
            : () => context.go(AppRoutes.concessions(bookingId)),
        body: Column(
          children: [
            const BookingProgress(currentStep: 3),
            BookingHoldCountdown(booking: booking),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  CheckoutSection(
                    title: quote.showtime.movieTitle ?? 'Phim',
                    children: [
                      CheckoutLine('Rạp', quote.showtime.cinemaName ?? '—'),
                      CheckoutLine('Phòng', quote.showtime.roomName ?? '—'),
                      CheckoutLine(
                        'Suất chiếu',
                        _dateTime(quote.showtime.startTime),
                      ),
                      CheckoutLine(
                        'Ghế',
                        quote.seats.map((seat) => seat.seatLabel).join(', '),
                      ),
                      for (final ticket in quote.tickets)
                        CheckoutLine(
                          _ticketLabel(ticket.ticketType),
                          '${quote.seats.firstWhere((seat) => seat.seatId == ticket.seatId).seatLabel} • ${ticket.lineTotal.format()}',
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  CheckoutSection(
                    title: 'Bắp nước',
                    children: quote.foods.isEmpty
                        ? const [CheckoutLine('Sản phẩm', 'Không chọn')]
                        : [
                            for (final food in quote.foods)
                              CheckoutLine(
                                '${food.productName} × ${food.quantity}',
                                food.lineTotal.format(),
                              ),
                          ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  CheckoutSection(
                    title: 'Thanh toán',
                    children: [
                      CheckoutLine('Vé', quote.ticketSubtotal.format()),
                      CheckoutLine('Bắp nước', quote.foodSubtotal.format()),
                      if (quote.fees.amount > 0)
                        CheckoutLine('Phí', quote.fees.format()),
                      if (quote.tax.amount > 0)
                        CheckoutLine('Thuế', quote.tax.format()),
                      if (quote.cinePointsDiscount.amount > 0)
                        CheckoutLine(
                          'Giảm từ điểm',
                          '-${quote.cinePointsDiscount.format()}',
                        ),
                      if (quote.discount.amount > 0)
                        CheckoutLine('Giảm giá', '-${quote.discount.format()}'),
                      const CheckoutLine('Phương thức', 'VNPay'),
                      CheckoutLine(
                        'Tổng cộng',
                        quote.total.format(),
                        emphasized: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Vui lòng kiểm tra thông tin vé và tổng tiền trước khi thanh toán.',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            PaymentActionBar(
              total: quote.total,
              notice: state.message,
              label: state.isBusy ? 'Đang tạo giao dịch…' : 'Thanh toán VNPay',
              loading: state.isBusy,
              buttonKey: const ValueKey('checkout-pay'),
              onPressed:
                  state.isBusy || state.phase == BookingCompletionPhase.expired
                  ? null
                  : () async {
                      final payment = await ref
                          .read(bookingCompletionProvider.notifier)
                          .createPayment();
                      if (payment != null && context.mounted) {
                        context.go(AppRoutes.payment(payment.id));
                      } else if (context.mounted &&
                          ref.read(bookingCompletionProvider).phase ==
                              BookingCompletionPhase.choosingFood) {
                        context.go(AppRoutes.concessions(bookingId));
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}

String _dateTime(DateTime value) => formatVietnamDateTime(value);

String _ticketLabel(TicketType type) => switch (type) {
  TicketType.child => 'Vé trẻ em',
  TicketType.student => 'Vé sinh viên',
  _ => 'Vé người lớn',
};
