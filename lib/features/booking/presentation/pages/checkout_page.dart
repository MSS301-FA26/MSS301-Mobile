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
import '../../../account/presentation/providers/account_summary_provider.dart';
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
                  Material(
                    color: Colors.transparent,
                    child: ExpansionTile(
                      key: const ValueKey('checkout-ticket-details'),
                      initiallyExpanded: true,
                      title: Text('Chi tiết ${quote.seats.length} vé'),
                      children: [CheckoutTicketSummary(quote: quote)],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  CheckoutComboPicker(bookingId: bookingId),
                  const SizedBox(height: AppSpacing.sm),
                  CheckoutSection(
                    key: const ValueKey('checkout-food-details'),
                    title: foods.isEmpty
                        ? 'Bắp nước'
                        : 'Bắp nước • ${foods.length} loại',
                    children: [
                      if (foods.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceHigh,
                            borderRadius: AppRadii.control,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.fastfood_outlined,
                                color: AppColors.textMuted,
                              ),
                              SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  'Bạn chưa chọn bắp nước cho đơn này.',
                                  style: AppTextStyles.body,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                      const SizedBox(height: AppSpacing.sm),
                      const Divider(),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          key: const ValueKey('checkout-edit-food'),
                          onPressed: state.isBusy || state.payment != null
                              ? null
                              : () => context.go(
                                  AppRoutes.concessions(bookingId),
                                ),
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(
                            foods.isEmpty
                                ? 'Chọn bắp nước'
                                : 'Chỉnh sửa bắp nước',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  CheckoutSection(
                    title: 'CinePoint',
                    children: [
                      CinePointRedemption(
                        selectedPoints: state.loyaltyPointsToRedeem,
                        ticketSubtotal: quote.ticketSubtotal.amount,
                        cinemaId: quote.cinema?.id,
                        enabled: !state.isBusy && state.payment == null,
                        onApply: (points) => ref
                            .read(bookingCompletionProvider.notifier)
                            .applyLoyaltyPoints(points),
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
              notice: state.quoteNeedsRefresh
                  ? 'Giá hoặc sản phẩm đã đổi. Vui lòng chờ báo giá mới trước khi thanh toán.'
                  : state.message,
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

class CinePointRedemption extends ConsumerStatefulWidget {
  const CinePointRedemption({
    super.key,
    required this.selectedPoints,
    required this.ticketSubtotal,
    required this.cinemaId,
    required this.enabled,
    required this.onApply,
  });

  final int selectedPoints;
  final int ticketSubtotal;
  final int? cinemaId;
  final bool enabled;
  final Future<void> Function(int points) onApply;

  @override
  ConsumerState<CinePointRedemption> createState() =>
      _CinePointRedemptionState();
}

class _CinePointRedemptionState extends ConsumerState<CinePointRedemption> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.selectedPoints == 0 ? '' : '${widget.selectedPoints}',
    );
  }

  @override
  void didUpdateWidget(covariant CinePointRedemption oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPoints != widget.selectedPoints) {
      _controller.text = widget.selectedPoints == 0
          ? ''
          : '${widget.selectedPoints}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loyalty = ref.watch(checkoutLoyaltyOverviewProvider(widget.cinemaId));
    return loyalty.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => const Text(
        'Không thể tải số dư CinePoint.',
        style: AppTextStyles.caption,
      ),
      data: (data) {
        final points = data.$1.points;
        final config = data.$2;
        final pointValue = config.redemptionPoints <= 0
            ? 0.0
            : config.redemptionValueVnd.amount /
                  config.redemptionPoints *
                  (config.redemptionRatePercent / 100);
        final maxFromBalance = (points * config.maxRedemptionPercent / 100)
            .floor();
        final maxDiscount =
            (widget.ticketSubtotal * config.maxRedemptionPercent / 100).floor();
        final maxFromPrice = pointValue <= 0
            ? 0
            : (maxDiscount / pointValue).floor();
        final maxPoints = maxFromBalance < maxFromPrice
            ? maxFromBalance
            : maxFromPrice;

        Future<void> apply(int value) async {
          final safe = value.clamp(0, maxPoints);
          _controller.text = safe == 0 ? '' : '$safe';
          await widget.onApply(safe);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Khả dụng: $points điểm • Tối đa: $maxPoints điểm',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('checkout-cinepoint-input'),
                    controller: _controller,
                    enabled: widget.enabled && maxPoints > 0,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Điểm muốn sử dụng',
                      hintText: 'Nhập CinePoint',
                    ),
                    onSubmitted: (value) =>
                        apply(int.tryParse(value.trim()) ?? 0),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  key: const ValueKey('checkout-cinepoint-max'),
                  onPressed: widget.enabled && maxPoints > 0
                      ? () => apply(maxPoints)
                      : null,
                  child: const Text('Tối đa'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                key: const ValueKey('checkout-cinepoint-apply'),
                onPressed: widget.enabled
                    ? () => apply(int.tryParse(_controller.text.trim()) ?? 0)
                    : null,
                child: Text(
                  widget.selectedPoints > 0
                      ? 'Cập nhật điểm'
                      : 'Áp dụng CinePoint',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
