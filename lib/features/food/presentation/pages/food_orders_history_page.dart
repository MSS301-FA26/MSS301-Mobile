import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
import '../../data/repositories/food_order_providers.dart';
import '../widgets/food_order_card.dart';

class FoodOrdersHistoryPage extends ConsumerWidget {
  const FoodOrdersHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myFoodOrdersProvider);
    return AppShell(
      currentIndex: 4,
      body: Column(
        children: [
          if (orders.hasError && orders.hasValue)
            RepositoryStatePane.error(
              compact: true,
              message:
                  'Chưa cập nhật được đơn. Các đơn đã tải vẫn được giữ lại.',
              onRetry: () => ref.invalidate(myFoodOrdersProvider),
            ),
          Expanded(
            child: orders.when(
              skipError: orders.hasValue,
              loading: () => const RepositoryStatePane.loading(
                layout: RepositorySkeleton.orders,
                title: 'Đang tải đơn bắp nước…',
              ),
              error: (error, _) => RepositoryStatePane.error(
                onRetry: () => ref.invalidate(myFoodOrdersProvider),
              ),
              data: (items) => items.isEmpty
                  ? RepositoryStatePane.empty(
                      title: 'Chưa có đơn bắp nước',
                      message: 'Các đơn bắp nước độc lập của bạn sẽ xuất hiện ở đây.',
                      onAction: () => context.push(AppRoutes.foodShop),
                      actionLabel: 'Đặt bắp nước',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, index) => InkWell(
                        onTap: () => context.push(
                          AppRoutes.foodOrderDetail(items[index].id),
                        ),
                        child: FoodOrderCard(order: items[index]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
