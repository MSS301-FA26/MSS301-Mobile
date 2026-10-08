import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      body: orders.when(
        loading: () => const RepositoryStatePane.loading(),
        error: (error, _) => RepositoryStatePane.error(
          onRetry: () => ref.invalidate(myFoodOrdersProvider),
        ),
        data: (items) => items.isEmpty
            ? const RepositoryStatePane.empty(
                title: 'Chưa có đơn bắp nước',
                message: 'Các đơn bắp nước độc lập của bạn sẽ xuất hiện ở đây.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, index) => FoodOrderCard(order: items[index]),
              ),
      ),
    );
  }
}
