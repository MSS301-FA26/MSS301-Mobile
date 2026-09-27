import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/money/vnd_money.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../movie/data/models/catalog_enums.dart';
import '../../application/booking_completion_controller.dart';
import '../widgets/booking_progress.dart';

class ConcessionsPage extends ConsumerStatefulWidget {
  const ConcessionsPage({super.key, required this.bookingId});

  final int bookingId;

  @override
  ConsumerState<ConcessionsPage> createState() => _ConcessionsPageState();
}

class _ConcessionsPageState extends ConsumerState<ConcessionsPage> {
  var _requested = false;

  void _backToSeats(BookingCompletionState state) {
    final showtimeId = state.booking?.showtimeId;
    context.go(
      showtimeId == null
          ? AppRoutes.showtimes
          : AppRoutes.seatSelection(showtimeId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingCompletionProvider);
    if (!_requested) {
      _requested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(bookingCompletionProvider.notifier).load(widget.bookingId);
      });
    }
    final total = state.products.fold(
      VndMoney.zero,
      (sum, product) =>
          sum + product.price.multiply(state.quantities[product.id] ?? 0),
    );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _backToSeats(state);
      },
      child: AppShell(
        currentIndex: 2,
        showBottomNavigation: false,
        body: Column(
          children: [
            _BookingHeader(
              title: 'Bắp nước',
              subtitle: 'Không bắt buộc • Có thể bỏ qua',
              onBack: () => _backToSeats(state),
            ),
            const BookingProgress(currentStep: 2),
            Expanded(
              child: state.phase == BookingCompletionPhase.loading
                  ? const Center(child: CircularProgressIndicator())
                  : state.phase == BookingCompletionPhase.expired ||
                        state.phase == BookingCompletionPhase.error
                  ? _BookingProblem(
                      message: state.message ?? 'Không thể tải bắp nước.',
                      onAction: () => context.go(AppRoutes.showtimes),
                    )
                  : state.products.isEmpty
                  ? const Center(child: Text('Hiện chưa có sản phẩm bắp nước.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: state.products.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final product = state.products[index];
                        final quantity = state.quantities[product.id] ?? 0;
                        final available =
                            product.status != FoodItemStatus.inactive &&
                            product.status != FoodItemStatus.outOfStock;
                        return Semantics(
                          label:
                              '${product.name}, ${product.price.format()}, số lượng $quantity',
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: AppRadii.card,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: AppColors.goldSurface,
                                    borderRadius: AppRadii.control,
                                  ),
                                  child: Icon(
                                    product.isCombo
                                        ? Icons.fastfood_rounded
                                        : Icons.local_drink_rounded,
                                    color: AppColors.gold,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: AppTextStyles.cardTitle,
                                      ),
                                      if (product.description != null)
                                        Text(
                                          product.description!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.caption,
                                        ),
                                      Text(
                                        available
                                            ? product.price.format()
                                            : 'Tạm hết hàng',
                                        style: TextStyle(
                                          color: available
                                              ? AppColors.gold
                                              : AppColors.textDisabled,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  key: ValueKey('food-minus-${product.id}'),
                                  tooltip: 'Giảm ${product.name}',
                                  onPressed: quantity > 0
                                      ? () => ref
                                            .read(
                                              bookingCompletionProvider
                                                  .notifier,
                                            )
                                            .changeQuantity(product.id, -1)
                                      : null,
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text(
                                  '$quantity',
                                  style: AppTextStyles.cardTitle,
                                ),
                                IconButton(
                                  key: ValueKey('food-plus-${product.id}'),
                                  tooltip: 'Tăng ${product.name}',
                                  onPressed: available && quantity < 8
                                      ? () => ref
                                            .read(
                                              bookingCompletionProvider
                                                  .notifier,
                                            )
                                            .changeQuantity(product.id, 1)
                                      : null,
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.quantities.isEmpty
                                ? 'Bỏ qua bắp nước'
                                : 'Tạm tính',
                            style: AppTextStyles.caption,
                          ),
                          Text(total.format(), style: AppTextStyles.cardTitle),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 170,
                      child: AppButton(
                        key: const ValueKey('concessions-continue'),
                        label: state.isBusy ? 'Đang cập nhật…' : 'Tiếp tục',
                        onPressed: state.isBusy || state.booking == null
                            ? null
                            : () async {
                                final ready = await ref
                                    .read(bookingCompletionProvider.notifier)
                                    .prepareCheckout();
                                if (ready && context.mounted) {
                                  context.go(
                                    AppRoutes.checkout(widget.bookingId),
                                  );
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingHeader extends StatelessWidget {
  const _BookingHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: ListTile(
      leading: IconButton(
        tooltip: 'Quay lại',
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: Text(title, style: AppTextStyles.sectionTitle),
      subtitle: Text(subtitle, style: AppTextStyles.caption),
    ),
  );
}

class _BookingProblem extends StatelessWidget {
  const _BookingProblem({required this.message, required this.onAction});

  final String message;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_off_outlined, size: 48),
          const SizedBox(height: AppSpacing.sm),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          AppButton(label: 'Về lịch chiếu', onPressed: onAction),
        ],
      ),
    ),
  );
}
