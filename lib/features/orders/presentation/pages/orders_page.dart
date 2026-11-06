import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
import '../../../booking/presentation/widgets/resume_booking_banner.dart';
import '../../../food/data/models/food_order_dto.dart';
import '../../../food/data/repositories/food_order_providers.dart';
import '../../../food/presentation/widgets/food_order_card.dart';
import '../../data/models/booking_enums.dart';
import '../models/ticket_order.dart';
import '../providers/orders_provider.dart';
import '../widgets/order_card.dart';
import '../widgets/orders_segmented_tabs.dart';

enum _OutcomeFilter { all, successful, unsuccessful }

class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  OrdersTab _tab = OrdersTab.tickets;
  _OutcomeFilter _filter = _OutcomeFilter.all;

  @override
  Widget build(BuildContext context) {
    final ticketsState = ref.watch(ordersProvider);
    final foodOrdersState = ref.watch(myFoodOrdersProvider);
    final tickets = ticketsState.value ?? const <TicketOrder>[];
    final List<FoodOrderDto> foodOrders = [...?foodOrdersState.value]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final ticketSuccessCount = tickets.where(_isSuccessfulTicket).length;
    final foodSuccessCount = foodOrders.where(_isSuccessfulFoodOrder).length;
    final selectedState = _tab == OrdersTab.tickets
        ? ticketsState
        : foodOrdersState;

    return AppShell(
      currentIndex: 3,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ordersProvider);
          ref.invalidate(myFoodOrdersProvider);
          try {
            if (_tab == OrdersTab.tickets) {
              await ref.read(ordersProvider.future);
            } else {
              await ref.read(myFoodOrdersProvider.future);
            }
          } catch (_) {
            // Keep the loaded history visible and let the inline error offer retry.
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            OrdersSegmentedTabs(
              selected: _tab,
              ticketsCount: ticketsState.hasValue ? tickets.length : null,
              foodOrdersCount: foodOrdersState.hasValue
                  ? foodOrders.length
                  : null,
              onSelected: (tab) => setState(() {
                _tab = tab;
                _filter = _OutcomeFilter.all;
              }),
            ),
            const SizedBox(height: AppSpacing.sm),
            _OutcomeFilters(
              selected: _filter,
              allCount: _tab == OrdersTab.tickets
                  ? (ticketsState.hasValue ? tickets.length : null)
                  : (foodOrdersState.hasValue ? foodOrders.length : null),
              successCount: _tab == OrdersTab.tickets
                  ? (ticketsState.hasValue ? ticketSuccessCount : null)
                  : (foodOrdersState.hasValue ? foodSuccessCount : null),
              unsuccessfulCount: _tab == OrdersTab.tickets
                  ? (ticketsState.hasValue
                        ? tickets.length - ticketSuccessCount
                        : null)
                  : (foodOrdersState.hasValue
                        ? foodOrders.length - foodSuccessCount
                        : null),
              onSelected: (filter) => setState(() => _filter = filter),
            ),
            const SizedBox(height: AppSpacing.md),
            if (selectedState.hasError && selectedState.hasValue)
              SizedBox(
                height: 110,
                child: RepositoryStatePane.error(
                  compact: true,
                  message: 'Chưa cập nhật được đơn. Các đơn đã tải vẫn được giữ lại.',
                  onRetry: () => _invalidateSelectedHistory(),
                ),
              ),
            if (!selectedState.hasValue && selectedState.isLoading)
              const SizedBox(
                height: 240,
                child: RepositoryStatePane.loading(
                  layout: RepositorySkeleton.orders,
                  title: 'Đang tải lịch sử đơn…',
                ),
              )
            else if (!selectedState.hasValue && selectedState.hasError)
              SizedBox(
                height: 240,
                child: RepositoryStatePane.error(
                  onRetry: () => _invalidateSelectedHistory(),
                  title: _tab == OrdersTab.tickets
                      ? 'Chưa tải được lịch sử vé'
                      : 'Chưa tải được đơn bắp nước',
                ),
              )
            else if (_tab == OrdersTab.tickets)
              _buildTicketList(
                context,
                ref,
                _filterTickets(tickets),
                tickets.isEmpty,
              )
            else
              _buildFoodOrderList(
                context,
                _filterFoodOrders(foodOrders),
                foodOrders.isEmpty,
              ),
          ],
        ),
      ),
    );
  }

  void _invalidateSelectedHistory() {
    if (_tab == OrdersTab.tickets) {
      ref.invalidate(ordersProvider);
    } else {
      ref.invalidate(myFoodOrdersProvider);
    }
  }

  List<TicketOrder> _filterTickets(List<TicketOrder> tickets) => tickets
      .where((ticket) {
        return switch (_filter) {
          _OutcomeFilter.all => true,
          _OutcomeFilter.successful => _isSuccessfulTicket(ticket),
          _OutcomeFilter.unsuccessful => !_isSuccessfulTicket(ticket),
        };
      })
      .toList(growable: false);

  List<FoodOrderDto> _filterFoodOrders(List<FoodOrderDto> orders) => orders
      .where((order) {
        return switch (_filter) {
          _OutcomeFilter.all => true,
          _OutcomeFilter.successful => _isSuccessfulFoodOrder(order),
          _OutcomeFilter.unsuccessful => !_isSuccessfulFoodOrder(order),
        };
      })
      .toList(growable: false);

  Widget _buildTicketList(
    BuildContext context,
    WidgetRef ref,
    List<TicketOrder> visible,
    bool noTickets,
  ) {
    if (visible.isEmpty) {
      return _EmptyHistory(
        title: noTickets
            ? 'Chưa có vé phim'
            : _emptyFilterTitle('vé phim', _filter),
        message: noTickets
            ? 'Vé phim đã đặt sẽ xuất hiện ở đây.'
            : 'Không có vé nào thuộc trạng thái này.',
        onAction: () => context.go(AppRoutes.discover),
      );
    }

    return Column(
      children: [
        for (final order in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: InkWell(
              onTap: () => context.go(AppRoutes.ticket(order.id)),
              child: order.isUpcoming
                  ? UpcomingOrderCard(
                      order: order,
                      onCancel:
                          FeatureFlags.refundPreview &&
                              order.status == BookingStatus.paid
                          ? () => context.go(AppRoutes.previewRefund(order.id))
                          : null,
                      onOpenTicket: () => order.status == BookingStatus.paid
                          ? context.go(AppRoutes.ticket(order.id))
                          : resumeBooking(context, ref, order.id),
                    )
                  : Column(
                      children: [
                        CompletedOrderCard(
                          order: order,
                          onBookAgain: () => context.go(
                            AppRoutes.showtimesForMovie(order.movieId),
                          ),
                          onRate: order.status == BookingStatus.used
                              ? () => context.push(
                                  AppRoutes.movieReviews(order.movieId),
                                )
                              : null,
                        ),
                        if (order.status == BookingStatus.used)
                          TextButton(
                            onPressed: () =>
                                context.go(AppRoutes.ticket(order.id)),
                            child: const Text('Xem vé đã sử dụng'),
                          ),
                      ],
                    ),
            ),
          ),
      ],
    );
  }

  Widget _buildFoodOrderList(
    BuildContext context,
    List<FoodOrderDto> visible,
    bool noOrders,
  ) {
    if (visible.isEmpty) {
      return _EmptyHistory(
        title: noOrders
            ? 'Chưa có đơn bắp nước'
            : _emptyFilterTitle('đơn bắp nước', _filter),
        message: noOrders
            ? 'Các đơn bắp nước của bạn sẽ xuất hiện ở đây.'
            : 'Không có đơn nào thuộc trạng thái này.',
        onAction: () => context.push(AppRoutes.foodShop),
        actionLabel: 'Đặt bắp nước',
      );
    }

    return Column(
      children: [
        for (final order in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: InkWell(
              onTap: () => context.push(AppRoutes.foodOrderDetail(order.id)),
              child: FoodOrderCard(order: order),
            ),
          ),
      ],
    );
  }
}

bool _isSuccessfulTicket(TicketOrder order) =>
    order.status == BookingStatus.paid || order.status == BookingStatus.used;

bool _isSuccessfulFoodOrder(FoodOrderDto order) =>
    order.status == FoodOrderStatus.paid ||
    order.status == FoodOrderStatus.pickedUp;

String _emptyFilterTitle(String type, _OutcomeFilter filter) =>
    switch (filter) {
      _OutcomeFilter.all => 'Không có $type',
      _OutcomeFilter.successful => 'Chưa có $type thành công',
      _OutcomeFilter.unsuccessful => 'Chưa có $type không thành công',
    };

class _OutcomeFilters extends StatelessWidget {
  const _OutcomeFilters({
    required this.selected,
    required this.allCount,
    required this.successCount,
    required this.unsuccessfulCount,
    required this.onSelected,
  });

  final _OutcomeFilter selected;
  final int? allCount;
  final int? successCount;
  final int? unsuccessfulCount;
  final ValueChanged<_OutcomeFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _OutcomeFilterButton(
          key: const ValueKey('orders-filter-all'),
          label: 'Tất cả',
          count: allCount,
          selected: selected == _OutcomeFilter.all,
          onTap: () => onSelected(_OutcomeFilter.all),
        ),
        const SizedBox(width: AppSpacing.xs),
        _OutcomeFilterButton(
          key: const ValueKey('orders-filter-successful'),
          label: 'Thành công',
          count: successCount,
          selected: selected == _OutcomeFilter.successful,
          onTap: () => onSelected(_OutcomeFilter.successful),
        ),
        const SizedBox(width: AppSpacing.xs),
        _OutcomeFilterButton(
          key: const ValueKey('orders-filter-unsuccessful'),
          label: 'Không thành công',
          count: unsuccessfulCount,
          selected: selected == _OutcomeFilter.unsuccessful,
          onTap: () => onSelected(_OutcomeFilter.unsuccessful),
        ),
      ],
    );
  }
}

class _OutcomeFilterButton extends StatelessWidget {
  const _OutcomeFilterButton({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        foregroundColor: selected ? Colors.black : AppColors.textMuted,
        backgroundColor: selected ? AppColors.gold : AppColors.surfaceRaised,
        side: BorderSide(color: selected ? AppColors.gold : AppColors.border),
        minimumSize: const Size(0, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          count == null ? label : '$label ($count)',
          maxLines: 1,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ),
    ),
  );
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({
    required this.title,
    required this.message,
    required this.onAction,
    this.actionLabel = 'Khám phá phim',
  });

  final String title;
  final String message;
  final VoidCallback onAction;
  final String actionLabel;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
    child: Column(
      children: [
        const Icon(
          Icons.receipt_long_outlined,
          size: 40,
          color: AppColors.textMuted,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          title,
          style: AppTextStyles.cardTitle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          message,
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    ),
  );
}
