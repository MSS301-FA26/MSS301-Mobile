import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/money/vnd_money.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
import '../../../food/presentation/widgets/food_product_card.dart';
import '../../../food/presentation/widgets/food_cart_bar.dart';
import '../../application/booking_completion_controller.dart';
import '../widgets/booking_hold_countdown.dart';
import '../../../seat/application/booking_entry_session.dart';
import '../widgets/booking_progress.dart';

class ConcessionsPage extends ConsumerStatefulWidget {
  const ConcessionsPage({super.key, required this.bookingId});

  final int bookingId;

  @override
  ConsumerState<ConcessionsPage> createState() => _ConcessionsPageState();
}

class _ConcessionsPageState extends ConsumerState<ConcessionsPage> {
  var _requested = false;
  var _redirectingPayment = false;

  void _backToSeats(BookingCompletionState state) {
    if (state.isBusy) return;
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
    if (state.payment != null && !_redirectingPayment) {
      _redirectingPayment = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.payment(state.payment!.id));
      });
    }
    if (!_requested) {
      _requested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final controller = ref.read(bookingCompletionProvider.notifier);
        controller.returnToFood();
        controller.load(widget.bookingId);
      });
    }
    final total = state.products.fold(
      VndMoney.zero,
      (sum, product) =>
          sum +
          product.price.multiply(state.quantities[product.selectionKey] ?? 0),
    );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _backToSeats(state);
      },
      child: AppShell(
        currentIndex: 2,
        showBottomNavigation: false,
        bookingTitle: 'Bắp nước',
        bookingSubtitle: 'Bước 3/4',
        onBookingBack: state.isBusy ? null : () => _backToSeats(state),
        body: Column(
          children: [
            const BookingProgress(currentStep: 2),
            BookingHoldCountdown(booking: state.booking),
            if (state.message != null &&
                state.phase == BookingCompletionPhase.choosingFood)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(
                  state.message!,
                  key: const ValueKey('concessions-message'),
                  style: const TextStyle(color: AppColors.adultBadge),
                ),
              ),
            Expanded(
              child: state.phase == BookingCompletionPhase.loading
                  ? const RepositoryStatePane.loading(
                      layout: RepositorySkeleton.foods,
                      title: 'Đang tải bắp nước…',
                    )
                  : state.phase == BookingCompletionPhase.expired ||
                        state.phase == BookingCompletionPhase.error
                  ? _BookingProblem(
                      message: state.message ?? 'Không thể tải bắp nước.',
                      actionLabel: state.phase == BookingCompletionPhase.expired
                          ? 'Chọn lại ghế'
                          : 'Thử lại',
                      onAction: () {
                        if (state.phase == BookingCompletionPhase.expired) {
                          ref
                              .read(bookingEntryProvider.notifier)
                              .restartSelection();
                          _backToSeats(state);
                          ref.invalidate(bookingCompletionProvider);
                        } else {
                          ref
                              .read(bookingCompletionProvider.notifier)
                              .load(widget.bookingId);
                        }
                      },
                    )
                  : state.products.isEmpty
                  ? const RepositoryStatePane.empty(
                      title: 'Chưa có bắp nước',
                      message: 'Bạn có thể bỏ qua để tiếp tục đặt vé.',
                      icon: Icons.fastfood_outlined,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: state.products.length + 1,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Text(
                              'Bắp nước không bắt buộc • Tối đa 8 mỗi loại',
                              style: AppTextStyles.caption,
                            ),
                          );
                        }
                        final product = state.products[index - 1];
                        final quantity =
                            state.quantities[product.selectionKey] ?? 0;
                        return FoodProductCard(
                          product: product,
                          quantity: quantity,
                          enabled:
                              state.phase ==
                              BookingCompletionPhase.choosingFood,
                          onChange: (delta) => ref
                              .read(bookingCompletionProvider.notifier)
                              .changeQuantity(
                                product.id,
                                delta,
                                isCombo: product.isCombo,
                              ),
                        );
                      },
                    ),
            ),
            FoodCartBar(
              total: total,
              quantity: state.quantities.values.fold(0, (a, b) => a + b),
              label: state.isBusy
                  ? 'Đang cập nhật…'
                  : state.quantities.isEmpty
                  ? 'Bỏ qua · Tiếp tục'
                  : 'Tiếp tục',
              buttonKey: const ValueKey('concessions-continue'),
              onContinue:
                  state.isBusy ||
                      state.booking == null ||
                      state.phase != BookingCompletionPhase.choosingFood
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
}

class _BookingProblem extends StatelessWidget {
  const _BookingProblem({
    required this.message,
    required this.onAction,
    required this.actionLabel,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => RepositoryStatePane.empty(
    title: 'Chưa thể tiếp tục',
    message: message,
    icon: Icons.info_outline,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}
