import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/money/vnd_money.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
import '../../../movie/data/models/catalog_enums.dart';
import '../../application/booking_completion_controller.dart';
import '../widgets/concession_booking_header.dart';
import '../widgets/concession_food_card.dart';
import '../widgets/concession_selection_bar.dart';

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
    final selectedProducts = state.products.where(
      (product) => (state.quantities[product.id] ?? 0) > 0,
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
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final textScale =
                      MediaQuery.textScalerOf(context).scale(14) / 14;
                  final columns =
                      constraints.maxWidth - 2 * AppSpacing.md >=
                          640 * textScale
                      ? 2
                      : 1;
                  final hasMenu =
                      state.phase != BookingCompletionPhase.loading &&
                      state.phase != BookingCompletionPhase.expired &&
                      state.phase != BookingCompletionPhase.error &&
                      state.products.isNotEmpty;
                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                    itemCount: hasMenu
                        ? 1 + (state.products.length + columns - 1) ~/ columns
                        : 2,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return ConcessionBookingHeader(
                          booking: state.booking,
                          onBack: () => _backToSeats(state),
                        );
                      }
                      if (state.phase == BookingCompletionPhase.loading) {
                        return const RepositoryStatePane.loading();
                      }
                      if (state.phase == BookingCompletionPhase.expired ||
                          state.phase == BookingCompletionPhase.error) {
                        return _BookingProblem(
                          message: state.message ?? 'Không thể tải bắp nước.',
                          onAction: () => context.go(AppRoutes.showtimes),
                        );
                      }
                      if (state.products.isEmpty) {
                        return const RepositoryStatePane.empty(
                          title: 'Hiện chưa có sản phẩm bắp nước.',
                          icon: Icons.fastfood_outlined,
                        );
                      }
                      final firstProduct = (index - 1) * columns;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (
                              var column = 0;
                              column < columns;
                              column++
                            ) ...[
                              if (column > 0)
                                const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child:
                                    firstProduct + column <
                                        state.products.length
                                    ? _foodCard(state, firstProduct + column)
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            ConcessionSelectionBar(
              subtotal: total,
              hasSelection: state.quantities.isNotEmpty,
              selectedProductCount: selectedProducts.length,
              selectedQuantity: selectedProducts.fold(
                0,
                (count, product) => count + state.quantities[product.id]!,
              ),
              isBusy: state.isBusy,
              onContinue: state.isBusy || state.booking == null
                  ? null
                  : () async {
                      final ready = await ref
                          .read(bookingCompletionProvider.notifier)
                          .prepareCheckout();
                      if (ready && context.mounted) {
                        context.go(AppRoutes.checkout(widget.bookingId));
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _foodCard(BookingCompletionState state, int index) {
    final product = state.products[index];
    final quantity = state.quantities[product.id] ?? 0;
    final available =
        product.status != FoodItemStatus.inactive &&
        product.status != FoodItemStatus.outOfStock;
    return ConcessionFoodCard(
      product: product,
      quantity: quantity,
      onDecrease: quantity > 0
          ? () => ref
                .read(bookingCompletionProvider.notifier)
                .changeQuantity(product.id, -1)
          : null,
      onIncrease: available && quantity < 8
          ? () => ref
                .read(bookingCompletionProvider.notifier)
                .changeQuantity(product.id, 1)
          : null,
    );
  }
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
