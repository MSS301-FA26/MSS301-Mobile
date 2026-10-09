import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../../../movie/data/models/catalog_enums.dart';
import '../../application/booking_completion_controller.dart';
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
        body: Center(
          child: AppButton(
            label: 'Quay lại bắp nước',
            onPressed: () => context.go(AppRoutes.concessions(bookingId)),
          ),
        ),
      );
    }
    return AppShell(
      currentIndex: 2,
      showBottomNavigation: false,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: ListTile(
              leading: IconButton(
                tooltip: 'Sửa bắp nước',
                onPressed: state.isBusy
                    ? null
                    : () => context.go(AppRoutes.concessions(bookingId)),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              title: const Text(
                'Xác nhận đơn',
                style: AppTextStyles.sectionTitle,
              ),
              subtitle: Text(booking.bookingCode, style: AppTextStyles.caption),
            ),
          ),
          const BookingProgress(currentStep: 3),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _Section(
                  title: quote.showtime.movieTitle ?? 'Phim',
                  children: [
                    _Line('Rạp', quote.showtime.cinemaName ?? '—'),
                    _Line('Phòng', quote.showtime.roomName ?? '—'),
                    _Line('Suất chiếu', _dateTime(quote.showtime.startTime)),
                    _Line(
                      'Ghế',
                      quote.seats.map((seat) => seat.seatLabel).join(', '),
                    ),
                    for (final ticket in quote.tickets)
                      _Line(
                        _ticketLabel(ticket.ticketType),
                        '${quote.seats.firstWhere((seat) => seat.seatId == ticket.seatId).seatLabel} • ${ticket.lineTotal.format()}',
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _Section(
                  title: 'Bắp nước',
                  children: quote.foods.isEmpty
                      ? const [_Line('Sản phẩm', 'Không chọn')]
                      : [
                          for (final food in quote.foods)
                            _Line(
                              '${food.productName} × ${food.quantity}',
                              food.lineTotal.format(),
                            ),
                        ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _Section(
                  title: 'Thanh toán',
                  children: [
                    _Line('Vé', quote.ticketSubtotal.format()),
                    _Line('Bắp nước', quote.foodSubtotal.format()),
                    if (quote.discount.amount > 0)
                      _Line('Giảm giá', '-${quote.discount.format()}'),
                    if (quote.cinePointsDiscount.amount > 0)
                      _Line(
                        'Quy đổi CinePoints',
                        '-${quote.cinePointsDiscount.format()}',
                      ),
                    const _Line('Phương thức', 'VNPay Mock'),
                    _Line('Tổng cộng', quote.total.format(), emphasized: true),
                  ],
                ),
                if (state.message != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    state.message!,
                    key: const ValueKey('checkout-message'),
                    style: const TextStyle(color: AppColors.adultBadge),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'CineWallet không được dùng để thanh toán vé. CinePoints tại checkout đang tắt cho đến khi backend thống nhất reserve/deduct/rollback.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: AppButton(
                key: const ValueKey('checkout-pay'),
                fullWidth: true,
                loading: state.isBusy,
                label: state.isBusy
                    ? 'Đang tạo giao dịch…'
                    : 'Thanh toán ${quote.total.format()}',
                onPressed: state.isBusy
                    ? null
                    : () async {
                        final payment = await ref
                            .read(bookingCompletionProvider.notifier)
                            .createPayment();
                        if (payment != null && context.mounted) {
                          context.go(AppRoutes.payment(payment.id));
                        }
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => AppSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.cardTitle),
        const SizedBox(height: AppSpacing.sm),
        ...children,
      ],
    ),
  );
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.emphasized = false});

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: AppTextStyles.caption)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: emphasized
                ? AppTextStyles.price.copyWith(color: AppColors.gold)
                : AppTextStyles.emphasis,
          ),
        ),
      ],
    ),
  );
}

String _dateTime(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')} • '
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _ticketLabel(TicketType type) => switch (type) {
  TicketType.child => 'Vé trẻ em',
  TicketType.student => 'Vé sinh viên',
  _ => 'Vé người lớn',
};
