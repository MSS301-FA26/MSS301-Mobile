import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/money/vnd_money.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/application/auth_session.dart';
import '../../../movie/data/models/cinema_dto.dart';
import '../../../movie/data/models/food_quote_dto.dart';
import '../../../movie/data/repositories/catalog_providers.dart';
import '../../data/repositories/standalone_food_repository.dart';
import '../../data/repositories/food_order_providers.dart';

final standaloneFoodCatalogProvider =
    FutureProvider.autoDispose<
      ({List<FoodProductDto> products, List<CinemaDto> cinemas})
    >((ref) async {
      final repository = ref.watch(catalogRepositoryProvider);
      final results = await Future.wait<Object>([
        repository.getFoodItems(),
        repository.getFoodCombos(),
        repository.getCinemas(),
      ]);
      return (
        products: [
          ...results[0] as List<FoodProductDto>,
          ...results[1] as List<FoodProductDto>,
        ],
        cinemas: (results[2] as List<CinemaDto>)
            .where((cinema) => cinema.active)
            .toList(),
      );
    });

String foodActionError(Object error) {
  final mapped = error is DioException ? error.error : error;
  if (mapped is ApiException &&
      [
        ApiErrorType.badRequest,
        ApiErrorType.validation,
      ].contains(mapped.type)) {
    return mapped.message;
  }
  return 'Không thể xử lý đơn lúc này. Vui lòng kiểm tra kết nối và thử lại.';
}

class StandaloneFoodPage extends ConsumerStatefulWidget {
  const StandaloneFoodPage({super.key});
  @override
  ConsumerState<StandaloneFoodPage> createState() => _StandaloneFoodPageState();
}

class _StandaloneFoodPageState extends ConsumerState<StandaloneFoodPage> {
  final _quantities = <String, int>{};
  CinemaDto? _cinema;
  bool _busy = false, _uncertain = false;
  String? _error;
  int _generation = 0;
  CancelToken? _cancel;
  @override
  void dispose() {
    _cancel?.cancel();
    super.dispose();
  }

  Future<void> _create(List<FoodProductDto> products, VndMoney estimate) async {
    if (_busy || _uncertain || _cinema == null) return;
    final cart = products
        .where((product) => (_quantities[product.selectionKey] ?? 0) > 0)
        .map(
          (product) =>
              (product: product, quantity: _quantities[product.selectionKey]!),
        )
        .toList();
    if (cart.isEmpty) return;
    final generation = _generation;
    final cancel = CancelToken();
    _cancel = cancel;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final order = await ref
          .read(standaloneFoodRepositoryProvider)
          .create(_cinema!, cart, cancelToken: cancel);
      if (!mounted || generation != _generation) return;
      ref.invalidate(myFoodOrdersProvider);
      // Replace the cart: returning from checkout cannot resubmit the same draft.
      context.pushReplacement(
        AppRoutes.foodOrderDetail(order.id),
        extra: estimate.amount,
      );
    } catch (error) {
      if (!mounted || generation != _generation) return;
      final status = error is DioException ? error.response?.statusCode : null;
      final mapped = error is DioException ? error.error : error;
      final rejected =
          [400, 401, 403, 404, 409, 422].contains(status) ||
          mapped is ApiException &&
              [
                ApiErrorType.badRequest,
                ApiErrorType.validation,
                ApiErrorType.unauthorized,
                ApiErrorType.forbidden,
              ].contains(mapped.type);
      setState(() {
        _uncertain = !rejected;
        _error = _uncertain
            ? 'Chưa xác minh được đơn đã tạo hay chưa. Hãy kiểm tra lịch sử đơn trước khi đặt lại.'
            : foodActionError(error);
      });
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int?>(
      authSessionProvider.select((auth) => auth.session?.user.id),
      (old, next) {
        if (old != next) {
          _cancel?.cancel();
          _generation++;
          setState(() {
            _quantities.clear();
            _cinema = null;
            _error = null;
            _busy = false;
            _uncertain = false;
          });
        }
      },
    );
    final catalog = ref.watch(standaloneFoodCatalogProvider);
    return AppShell(
      currentIndex: 0,
      showBottomNavigation: false,
      body: Column(
        children: [
          ListTile(
            leading: IconButton(
              tooltip: 'Về Trang chủ',
              onPressed: () => context.go(AppRoutes.home),
              icon: const Icon(Icons.arrow_back),
            ),
            title: const Text(
              'Đặt bắp nước',
              style: AppTextStyles.sectionTitle,
            ),
            trailing: IconButton(
              tooltip: 'Lịch sử đơn bắp nước',
              onPressed: () => context.push(AppRoutes.foodOrders),
              icon: const Icon(Icons.receipt_long),
            ),
          ),
          Expanded(
            child: catalog.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Không thể tải danh mục bắp nước.',
                      style: AppTextStyles.caption,
                    ),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(standaloneFoodCatalogProvider),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
              data: (data) {
                final products = data.products;
                final estimate = products.fold<VndMoney>(
                  VndMoney.zero,
                  (total, product) =>
                      total +
                      product.price.multiply(
                        _quantities[product.selectionKey] ?? 0,
                      ),
                );
                return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          DropdownButtonFormField<int>(
                            key: ValueKey(
                              'food-cinema-${ref.watch(authSessionProvider).session?.user.id}',
                            ),
                            initialValue: _cinema?.id,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Rạp nhận bắp nước',
                            ),
                            items: data.cinemas
                                .map(
                                  (cinema) => DropdownMenuItem(
                                    value: cinema.id,
                                    child: Text(
                                      cinema.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: _busy || _uncertain
                                ? null
                                : (id) => setState(
                                    () => _cinema = data.cinemas.firstWhere(
                                      (cinema) => cinema.id == id,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          if (products.isEmpty)
                            const Text(
                              'Chưa có sản phẩm bắp nước.',
                              style: AppTextStyles.caption,
                            ),
                          if (data.cinemas.isEmpty)
                            const Text(
                              'Chưa có rạp nhận hàng.',
                              style: AppTextStyles.caption,
                            ),
                          for (final product in products)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: AppTextStyles.cardTitle,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${product.isCombo ? 'Combo' : 'Sản phẩm'} · ${product.price.format()}',
                                      style: AppTextStyles.caption,
                                    ),
                                    if (!product.isAvailable)
                                      const Text(
                                        'Hiện không thể đặt sản phẩm này.',
                                        style: AppTextStyles.caption,
                                      ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          key: ValueKey(
                                            'food-minus-${product.selectionKey}',
                                          ),
                                          onPressed:
                                              _busy ||
                                                  _uncertain ||
                                                  (_quantities[product
                                                              .selectionKey] ??
                                                          0) ==
                                                      0
                                              ? null
                                              : () => setState(
                                                  () =>
                                                      _quantities[product
                                                              .selectionKey] =
                                                          (_quantities[product
                                                                  .selectionKey] ??
                                                              0) -
                                                          1,
                                                ),
                                          icon: const Icon(Icons.remove),
                                        ),
                                        Text(
                                          '${_quantities[product.selectionKey] ?? 0}',
                                        ),
                                        IconButton(
                                          key: ValueKey(
                                            'food-plus-${product.selectionKey}',
                                          ),
                                          onPressed:
                                              _busy ||
                                                  _uncertain ||
                                                  !product.isAvailable ||
                                                  (_quantities[product
                                                              .selectionKey] ??
                                                          0) >=
                                                      8
                                              ? null
                                              : () => setState(
                                                  () =>
                                                      _quantities[product
                                                              .selectionKey] =
                                                          (_quantities[product
                                                                  .selectionKey] ??
                                                              0) +
                                                          1,
                                                ),
                                          icon: const Icon(Icons.add),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (_error != null)
                            Text(_error!, style: AppTextStyles.caption),
                          if (_uncertain)
                            TextButton(
                              onPressed: () =>
                                  context.push(AppRoutes.foodOrders),
                              child: const Text('Kiểm tra lịch sử đơn'),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Tạm tính: ${estimate.format()}',
                            style: AppTextStyles.cardTitle,
                          ),
                          const SizedBox(height: 10),
                          AppButton(
                            key: const ValueKey('food-create-order'),
                            label: _busy ? 'Đang tạo đơn…' : 'Xác nhận đơn',
                            onPressed:
                                _busy ||
                                    _uncertain ||
                                    _cinema == null ||
                                    _quantities.values.every((q) => q == 0)
                                ? null
                                : () => _create(products, estimate),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
