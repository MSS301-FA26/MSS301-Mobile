import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/money/vnd_money.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
import '../widgets/food_product_card.dart';
import '../widgets/food_cart_bar.dart';
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

  Future<void> _choosePickup(List<CinemaDto> cinemas) async {
    if (_busy || _uncertain || cinemas.isEmpty) return;
    final generation = _generation;
    final selected = await showModalBottomSheet<CinemaDto>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .65,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Chọn rạp nhận bắp nước',
                  style: AppTextStyles.sectionTitle,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: cinemas.length,
                  itemBuilder: (context, index) {
                    final cinema = cinemas[index];
                    return ListTile(
                      key: ValueKey('food-pickup-${cinema.id}'),
                      leading: const Icon(Icons.storefront_outlined),
                      title: Text(cinema.name),
                      subtitle: Text(cinema.address),
                      onTap: () => Navigator.pop(context, cinema),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || generation != _generation || selected == null) return;
    setState(() => _cinema = selected);
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
              skipError: catalog.hasValue,
              loading: () => const RepositoryStatePane.loading(
                layout: RepositorySkeleton.foods,
                title: 'Đang tải bắp nước…',
              ),
              error: (_, _) => RepositoryStatePane.error(
                title: 'Chưa tải được bắp nước',
                onRetry: () => ref.invalidate(standaloneFoodCatalogProvider),
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
                          if (catalog.hasError)
                            RepositoryStatePane.error(
                              compact: true,
                              message: 'Chưa cập nhật được sản phẩm. Giá và khả dụng sẽ được kiểm tra lại khi đặt.',
                              onRetry: () =>
                                  ref.invalidate(standaloneFoodCatalogProvider),
                            ),
                          DropdownButtonFormField<int>(
                            key: ValueKey(
                              'food-cinema-${ref.watch(authSessionProvider).session?.user.id}-${_cinema?.id}',
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
                          const SizedBox(height: 8),
                          if (_cinema != null)
                            Text(
                              '${_cinema!.name}\n${_cinema!.address}',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 13,
                              ),
                            ),
                          const SizedBox(height: 8),
                          const Text(
                            'Mua riêng, không cần đặt vé • Tối đa 8 mỗi loại',
                            style: AppTextStyles.caption,
                          ),
                          const SizedBox(height: 16),
                          if (products.isEmpty)
                            const RepositoryStatePane.empty(
                              compact: true,
                              title: 'Chưa có bắp nước',
                              message: 'Vui lòng quay lại sau.',
                              icon: Icons.fastfood_outlined,
                            ),
                          if (data.cinemas.isEmpty)
                            const RepositoryStatePane.empty(
                              compact: true,
                              title: 'Chưa có rạp nhận hàng',
                              message: 'Chưa thể tạo đơn lúc này.',
                              icon: Icons.storefront_outlined,
                            ),
                          for (final product in products)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: FoodProductCard(
                                product: product,
                                quantity:
                                    _quantities[product.selectionKey] ?? 0,
                                enabled: !_busy && !_uncertain,
                                onChange: (delta) => setState(() {
                                  final quantity =
                                      ((_quantities[product.selectionKey] ??
                                                  0) +
                                              delta)
                                          .clamp(0, 8);
                                  if (quantity == 0) {
                                    _quantities.remove(product.selectionKey);
                                  } else {
                                    _quantities[product.selectionKey] =
                                        quantity;
                                  }
                                }),
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
                    FoodCartBar(
                      total: estimate,
                      quantity: _quantities.values.fold(0, (a, b) => a + b),
                      detail: _cinema?.name ?? 'Chọn rạp nhận hàng',
                      label: _busy
                          ? 'Đang tạo đơn…'
                          : _cinema == null
                          ? 'Chọn rạp nhận'
                          : 'Xác nhận đơn',
                      buttonKey: const ValueKey('food-create-order'),
                      onContinue:
                          _busy ||
                              _uncertain ||
                              data.cinemas.isEmpty ||
                              _quantities.values.every((q) => q == 0)
                          ? null
                          : _cinema == null
                          ? () => _choosePickup(data.cinemas)
                          : () => _create(products, estimate),
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
