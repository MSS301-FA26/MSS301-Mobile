import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
import '../../data/models/booking_enums.dart';
import '../../../booking/presentation/widgets/resume_booking_banner.dart';
import '../providers/orders_provider.dart';
import '../widgets/order_card.dart';
import '../widgets/orders_segmented_tabs.dart';

class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  OrdersTab _tab = OrdersTab.upcoming;

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);
    Widget pending(Widget content) => AppShell(
      currentIndex: 3,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: OrdersSegmentedTabs(
              selected: _tab,
              upcomingCount: null,
              completedCount: null,
              onSelected: (tab) => setState(() => _tab = tab),
            ),
          ),
          Expanded(child: content),
        ],
      ),
    );
    if (ordersState.isLoading && !ordersState.hasValue) {
      return pending(
        const RepositoryStatePane.loading(
          layout: RepositorySkeleton.orders,
          title: 'Đang tải đơn của bạn…',
        ),
      );
    }
    if (ordersState.hasError && !ordersState.hasValue) {
      return pending(
        RepositoryStatePane.error(
          onRetry: () => ref.invalidate(ordersProvider),
          title: 'Chưa tải được đơn của bạn',
        ),
      );
    }
    final orders = ordersState.requireValue;
    final upcoming = orders.where((order) => order.isUpcoming).toList();
    final completed = orders.where((order) => !order.isUpcoming).toList();
    final visible = _tab == OrdersTab.upcoming ? upcoming : completed;

    return AppShell(
      currentIndex: 3,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ordersProvider);
          try {
            await ref.read(ordersProvider.future);
          } catch (_) {
            /* Inline retry preserves previous orders. */
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            if (ordersState.hasError)
              RepositoryStatePane.error(
                compact: true,
                message:
                    'Chưa cập nhật được đơn. Các đơn đã tải vẫn được giữ lại.',
                onRetry: () => ref.invalidate(ordersProvider),
              ),
            OrdersSegmentedTabs(
              selected: _tab,
              upcomingCount: upcoming.length,
              completedCount: completed.length,
              onSelected: (tab) => setState(() => _tab = tab),
            ),
            const SizedBox(height: AppSpacing.md),
            if (visible.isEmpty)
              _EmptyOrders(history: _tab == OrdersTab.completed)
            else
              for (final order in visible)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: InkWell(
                    onTap: () => context.go(AppRoutes.ticket(order.id)),
                    child: order.isUpcoming
                        ? UpcomingOrderCard(
                            order: order,
                            onCancel: FeatureFlags.refundPreview
                                ? () => context.go(
                                    AppRoutes.previewRefund(order.id),
                                  )
                                : null,
                            onOpenTicket: () =>
                                order.status == BookingStatus.paid
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
        ),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders({required this.history});
  final bool history;

  @override
  Widget build(BuildContext context) {
    return RepositoryStatePane.empty(
      compact: true,
      title: history ? 'Chưa có lịch sử đơn' : 'Chưa có vé sắp chiếu nào',
      message: 'Hãy chọn một bộ phim yêu thích và đặt chỗ ngay hôm nay!',
      icon: Icons.confirmation_number_outlined,
      onAction: () => context.go(AppRoutes.discover),
    );
  }
}
