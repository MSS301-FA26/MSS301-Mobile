import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../models/ticket_order.dart';
import '../providers/mock_orders_provider.dart';
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
    final orders = ref.watch(mockOrdersProvider);
    final upcoming = orders
        .where((order) => order.status == TicketOrderStatus.upcoming)
        .toList();
    final completed = orders
        .where((order) => order.status == TicketOrderStatus.completed)
        .toList();
    final visible = _tab == OrdersTab.upcoming ? upcoming : completed;

    return AppShell(
      currentIndex: 3,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          OrdersSegmentedTabs(
            selected: _tab,
            upcomingCount: upcoming.length,
            completedCount: completed.length,
            onSelected: (tab) => setState(() => _tab = tab),
          ),
          const SizedBox(height: AppSpacing.md),
          if (visible.isEmpty)
            const _EmptyOrders()
          else
            for (final order in visible)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: order.status == TicketOrderStatus.upcoming
                    ? UpcomingOrderCard(
                        order: order,
                        onCancel: null,
                        onOpenTicket: null,
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
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 48,
            color: AppColors.textDisabled,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Chưa có vé sắp chiếu nào',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Hãy chọn một bộ phim yêu thích và đặt chỗ ngay hôm nay!',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}
