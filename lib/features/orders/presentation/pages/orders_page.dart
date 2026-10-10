import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
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
    if (ordersState.isLoading) {
      return const AppShell(
        currentIndex: 3,
        body: RepositoryStatePane.loading(),
      );
    }
    if (ordersState.hasError) {
      return AppShell(
        currentIndex: 3,
        body: RepositoryStatePane.error(
          onRetry: () => ref.invalidate(ordersProvider),
        ),
      );
    }
    final orders = ordersState.requireValue;
    final upcoming = orders.where((order) => order.isUpcoming).toList();
    final completed = orders.where((order) => !order.isUpcoming).toList();
    final visible = _tab == OrdersTab.upcoming ? upcoming : completed;

    return AppShell(
      currentIndex: 3,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const AppSectionHeader(title: 'Vé của tôi'),
          const SizedBox(height: AppSpacing.md),
          OrdersSegmentedTabs(
            selected: _tab,
            upcomingCount: upcoming.length,
            completedCount: completed.length,
            onSelected: (tab) => setState(() => _tab = tab),
          ),
          const SizedBox(height: AppSpacing.md),
          if (visible.isEmpty)
            _EmptyOrders(tab: _tab)
          else
            for (final order in visible)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: order.isUpcoming
                    ? UpcomingOrderCard(
                        order: order,
                        onCancel: FeatureFlags.refundPreview
                            ? () =>
                                  context.go(AppRoutes.previewRefund(order.id))
                            : null,
                        onOpenTicket: () =>
                            context.go(AppRoutes.ticket(order.id)),
                      )
                    : CompletedOrderCard(
                        order: order,
                        onBookAgain: () => context.go(
                          AppRoutes.showtimesForMovie(order.movieId),
                        ),
                        onRate: null,
                      ),
              ),
        ],
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders({required this.tab});

  final OrdersTab tab;

  @override
  Widget build(BuildContext context) {
    return RepositoryStatePane.empty(
      title: tab == OrdersTab.upcoming
          ? 'Chưa có vé sắp chiếu nào'
          : 'Chưa có lịch sử đã xem',
      message: 'Hãy chọn một bộ phim yêu thích và đặt chỗ ngay hôm nay!',
      icon: Icons.confirmation_number_outlined,
    );
  }
}
