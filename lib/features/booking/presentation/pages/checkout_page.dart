import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/checkout_summary.dart';
import '../../../movie/data/models/movie_dto.dart';
import '../../../movie/data/repositories/catalog_providers.dart';
import '../../application/booking_completion_controller.dart';
import '../widgets/booking_hold_countdown.dart';
import '../widgets/booking_progress.dart';
import '../widgets/checkout_order_summary.dart';
import '../widgets/checkout_combo_picker.dart';

final checkoutMovieMetadataProvider = FutureProvider.autoDispose
    .family<MovieDto?, int>(
      (ref, id) => ref.watch(catalogRepositoryProvider).getMovie(id),
      retry: (retryCount, error) => null,
    );

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
    final needsMetadata =
        quote.movie == null ||
        checkoutText([quote.movie?.ageRating]) == null ||
        checkoutText([
              quote.movie?.posterUrl,
              quote.showtime.posterUrl,
              booking.moviePosterSnapshot,
              booking.posterUrl,
            ]) ==
            null ||
        quote.movie?.durationMinutes == null;
    final metadata = needsMetadata
        ? ref
              .watch(checkoutMovieMetadataProvider(quote.showtime.movieId))
              .asData
              ?.value
        : null;
    final foods = quote.foods.isNotEmpty ? quote.foods : quote.foodItems;
    final productImages = {
      for (final product in state.products)
        product.selectionKey: product.imageUrl,
    };
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
                  CheckoutMovieSummary(
                    quote: quote,
                    booking: booking,
                    metadata: metadata,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  CheckoutTicketSummary(quote: quote),
                  const SizedBox(height: AppSpacing.sm),
                  CheckoutComboPicker(bookingId: bookingId),
                  CheckoutSection(
                    title: 'Bắp nước',
                    children: [
                      if (foods.isEmpty)
                        const CheckoutLine('Sản phẩm', 'Không chọn'),
                      for (final food in foods)
                        CheckoutFoodSummaryLine(
                          key: ValueKey(
                            'checkout-food-${food.isCombo ? 'combo' : 'item'}:${food.productId}',
                          ),
                          name: food.productName,
                          quantity: food.quantity,
                          isCombo: food.isCombo,
                          unitPrice: food.unitPrice,
                          lineTotal: food.lineTotal,
                          imageUrl:
                              productImages['${food.isCombo ? 'combo' : 'item'}:${food.productId}'],
                        ),
                      TextButton.icon(
                        key: const ValueKey('checkout-edit-food'),
                        onPressed: state.isBusy || state.payment != null
                            ? null
                            : () =>
                                  context.go(AppRoutes.concessions(bookingId)),
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(
                          foods.isEmpty
                              ? 'Quay lại chọn bắp nước'
                              : 'Sửa bắp nước',
                        ),
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
              label: state.phase == BookingCompletionPhase.preparingCheckout
                  ? 'Đang cập nhật báo giá…'
                  : state.isBusy
                  ? 'Đang tạo giao dịch…'
                  : 'Thanh toán VNPay',
              loading: state.isBusy,
              buttonKey: const ValueKey('checkout-pay'),
              onPressed:
                  state.isBusy ||
                      state.quoteNeedsRefresh ||
                      state.phase == BookingCompletionPhase.expired
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
