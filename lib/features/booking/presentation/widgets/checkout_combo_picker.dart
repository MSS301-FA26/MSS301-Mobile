import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../food/presentation/widgets/food_product_card.dart';
import '../../../movie/data/models/food_quote_dto.dart';
import '../../../movie/data/repositories/catalog_providers.dart';
import '../../../orders/data/models/booking_enums.dart';
import '../../application/booking_completion_controller.dart';
import 'booking_hold_countdown.dart';

class CheckoutComboPicker extends ConsumerStatefulWidget {
  const CheckoutComboPicker({super.key, required this.bookingId});
  final int bookingId;
  @override
  ConsumerState<CheckoutComboPicker> createState() =>
      _CheckoutComboPickerState();
}

class _CheckoutComboPickerState extends ConsumerState<CheckoutComboPicker> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool _editable(WidgetRef ref, BookingCompletionState state) =>
      state.booking?.id == widget.bookingId &&
      state.booking?.status == BookingStatus.holding &&
      state.phase == BookingCompletionPhase.checkout &&
      !state.isBusy &&
      state.payment == null &&
      state.booking?.holdExpiresAt != null &&
      ref.read(appClockProvider).now().isBefore(state.booking!.holdExpiresAt!);

  void _change(WidgetRef ref, FoodProductDto product, int delta) {
    final current = ref.read(bookingCompletionProvider);
    if (!_editable(ref, current)) return;
    ref
        .read(bookingCompletionProvider.notifier)
        .changeCheckoutQuantity(product.id, delta, isCombo: product.isCombo);
  }

  void _showAll() {
    final ticks = Stream<int>.periodic(
      const Duration(seconds: 1),
      (tick) => tick,
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StreamBuilder<int>(
        stream: ticks,
        builder: (context, _) => FractionallySizedBox(
          heightFactor: .85,
          child: Consumer(
            builder: (context, ref, _) {
              final state = ref.watch(bookingCompletionProvider);
              if (state.booking?.id != widget.bookingId) {
                return const Center(
                  child: Text(
                    'Đơn hiện tại đã thay đổi. Vui lòng đóng danh sách.',
                  ),
                );
              }
              final enabled = _editable(ref, state);
              return Column(
                children: [
                  ListTile(
                    title: const Text('Combo & bắp nước'),
                    trailing: IconButton(
                      tooltip: 'Đóng',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                  BookingHoldCountdown(booking: state.booking),
                  if (state.isBusy) const LinearProgressIndicator(),
                  if (state.message != null)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 104),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: Text(state.message!, style: AppTextStyles.body),
                      ),
                    ),
                  if (state.quoteNeedsRefresh && !state.isBusy)
                    TextButton(
                      onPressed: enabled
                          ? () => ref
                                .read(bookingCompletionProvider.notifier)
                                .refreshCheckoutCart()
                          : null,
                      child: const Text('Thử cập nhật báo giá'),
                    ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.products.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final product = state.products[index];
                        return FoodProductCard(
                          product: product,
                          quantity: state.quantities[product.selectionKey] ?? 0,
                          enabled: enabled,
                          onChange: (delta) => _change(ref, product, delta),
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          if (state.quote != null)
                            Text(
                              '${state.quoteNeedsRefresh ? 'Tổng trước cập nhật' : 'Tổng thanh toán'}: ${state.quote!.total.format()}',
                              style: AppTextStyles.cardTitle,
                            ),
                          TextButton(
                            onPressed: state.isBusy
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text('Hoàn tất • Kiểm tra đơn'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingCompletionProvider);
    if (state.booking?.id != widget.bookingId || state.products.isEmpty) {
      return const SizedBox.shrink();
    }
    final enabled = _editable(ref, state);
    final combos = state.products
        .where(
          (p) =>
              p.isCombo &&
              (p.isAvailable || (state.quantities[p.selectionKey] ?? 0) > 0),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('Thêm combo / bắp nước', style: AppTextStyles.cardTitle),
            TextButton(
              key: const ValueKey('checkout-all-food'),
              onPressed: _showAll,
              child: const Text('Xem tất cả'),
            ),
          ],
        ),
        const Text(
          'Không bắt buộc • Giá được xác nhận lại sau mỗi thay đổi.',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: 10),
        if (combos.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final product in combos)
                  Container(
                    key: ValueKey('checkout-combo-${product.id}'),
                    width: MediaQuery.sizeOf(context).width < 360 ? 240 : 270,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadii.card,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: product.imageUrl?.trim().isNotEmpty == true
                                  ? AppImage(
                                      asset: product.imageUrl!,
                                      fit: BoxFit.cover,
                                      semanticLabel: product.name,
                                    )
                                  : const Icon(
                                      Icons.fastfood_outlined,
                                      color: AppColors.gold,
                                    ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: AppTextStyles.cardTitle,
                                  ),
                                  Text(
                                    product.price.format(),
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.gold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (!product.isAvailable)
                          const Text(
                            'Không thể thêm • Có thể giảm để sửa giỏ',
                            style: AppTextStyles.caption,
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              key: ValueKey(
                                'checkout-minus-${product.selectionKey}',
                              ),
                              tooltip: 'Giảm ${product.name}',
                              onPressed:
                                  enabled &&
                                      (state.quantities[product.selectionKey] ??
                                              0) >
                                          0
                                  ? () => _change(ref, product, -1)
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text(
                              '${state.quantities[product.selectionKey] ?? 0}/8',
                              style: AppTextStyles.body,
                            ),
                            IconButton(
                              key: ValueKey(
                                'checkout-plus-${product.selectionKey}',
                              ),
                              tooltip: 'Thêm ${product.name}',
                              onPressed:
                                  enabled &&
                                      product.isAvailable &&
                                      (state.quantities[product.selectionKey] ??
                                              0) <
                                          8
                                  ? () => _change(ref, product, 1)
                                  : null,
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        if (state.isBusy)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Đang cập nhật báo giá…', style: AppTextStyles.body),
          ),
        if (state.quoteNeedsRefresh) ...[
          const Text(
            'Giỏ đã thay đổi. Tổng bên dưới chưa được xác nhận cho giỏ mới.',
            style: AppTextStyles.body,
          ),
          if (!state.isBusy)
            TextButton(
              key: const ValueKey('checkout-refresh-quote'),
              onPressed: enabled
                  ? () => ref
                        .read(bookingCompletionProvider.notifier)
                        .refreshCheckoutCart()
                  : null,
              child: const Text('Thử cập nhật báo giá'),
            ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}
