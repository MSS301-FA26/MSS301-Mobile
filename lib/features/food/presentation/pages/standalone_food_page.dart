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
import '../widgets/food_catalog_groups.dart';
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
  FoodCatalogGroup _group = FoodCatalogGroup.all;
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
            _group = FoodCatalogGroup.all;
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
          Container(
            padding: const EdgeInsets.fromLTRB(8, 9, 12, 11),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Về Trang chủ',
                  onPressed: () => context.go(AppRoutes.home),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.goldSurface,
                              borderRadius: AppRadii.small,
                              border: Border.all(color: AppColors.goldBorder),
                            ),
                            child: Text(
                              'F&B',
                              style: AppTextStyles.meta.copyWith(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'ĐẶT BẮP NƯỚC',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.sectionTitle.copyWith(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Chọn món yêu thích • Nhận nhanh tại rạp',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: AppColors.goldSurface,
                  borderRadius: AppRadii.medium,
                  child: IconButton(
                    key: const ValueKey('food-order-history-header'),
                    tooltip: 'Lịch sử đơn bắp nước',
                    onPressed: () => context.push(AppRoutes.foodOrders),
                    icon: const Icon(
                      Icons.receipt_long_outlined,
                      color: AppColors.gold,
                      size: 21,
                    ),
                  ),
                ),
              ],
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
                final visibleProducts = foodProductsInGroup(products, _group);
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
                          const _FoodShopHero(),
                          const SizedBox(height: 16),
                          if (catalog.hasError)
                            RepositoryStatePane.error(
                              compact: true,
                              message: 'Chưa cập nhật được sản phẩm. Giá và khả dụng sẽ được kiểm tra lại khi đặt.',
                              onRetry: () =>
                                  ref.invalidate(standaloneFoodCatalogProvider),
                            ),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceRaised,
                              borderRadius: AppRadii.card,
                              border: Border.all(
                                color: _cinema == null
                                    ? AppColors.goldBorder
                                    : AppColors.border,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: const BoxDecoration(
                                        color: AppColors.goldSurface,
                                        borderRadius: AppRadii.small,
                                      ),
                                      child: const Icon(
                                        Icons.storefront_outlined,
                                        color: AppColors.gold,
                                        size: 21,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'NHẬN MÓN TẠI RẠP',
                                            style: AppTextStyles.label,
                                          ),
                                          Text(
                                            'Chọn địa điểm thuận tiện với bạn',
                                            style: AppTextStyles.caption,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<int>(
                                  key: ValueKey(
                                    'food-cinema-${ref.watch(authSessionProvider).session?.user.id}-${_cinema?.id}',
                                  ),
                                  initialValue: _cinema?.id,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Rạp nhận bắp nước',
                                    prefixIcon: Icon(
                                      Icons.location_on_outlined,
                                    ),
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
                                          () => _cinema = data.cinemas
                                              .firstWhere(
                                                (cinema) => cinema.id == id,
                                              ),
                                        ),
                                ),
                                if (_cinema != null) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    _cinema!.address,
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'THỰC ĐƠN HÔM NAY',
                                      style: TextStyle(
                                        color: AppColors.gold,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'Chọn món bạn yêu thích',
                                      style: AppTextStyles.sectionTitle,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: const BoxDecoration(
                                  color: AppColors.goldSurface,
                                  borderRadius: AppRadii.pill,
                                ),
                                child: Text(
                                  '${visibleProducts.length} món',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.gold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          FoodCatalogGroups(
                            products: products,
                            selected: _group,
                            onSelected: _busy
                                ? null
                                : (group) => setState(() => _group = group),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text(
                              'Mua riêng, không cần đặt vé • Tối đa 8 mỗi loại',
                              style: AppTextStyles.caption,
                            ),
                          ),
                          if (products.isEmpty)
                            const RepositoryStatePane.empty(
                              compact: true,
                              title: 'Chưa có bắp nước',
                              message: 'Vui lòng quay lại sau.',
                              icon: Icons.fastfood_outlined,
                            ),
                          if (products.isNotEmpty && visibleProducts.isEmpty)
                            const RepositoryStatePane.empty(
                              compact: true,
                              title: 'Chưa có sản phẩm trong nhóm này',
                              message: 'Bạn có thể chọn nhóm khác.',
                              icon: Icons.fastfood_outlined,
                            ),
                          if (data.cinemas.isEmpty)
                            const RepositoryStatePane.empty(
                              compact: true,
                              title: 'Chưa có rạp nhận hàng',
                              message: 'Chưa thể tạo đơn lúc này.',
                              icon: Icons.storefront_outlined,
                            ),
                          for (final product in visibleProducts)
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

class _FoodShopHero extends StatelessWidget {
  const _FoodShopHero();

  static const _image =
      'https://images.unsplash.com/photo-1586899028174-e7098604235b?auto=format&fit=crop&w=1200&q=82';

  @override
  Widget build(BuildContext context) => Container(
    height: 190,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: AppColors.goldSurface,
      borderRadius: AppRadii.card,
      border: Border.all(color: AppColors.goldBorder),
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          _image,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Center(
            child: Icon(
              Icons.fastfood_rounded,
              color: AppColors.gold,
              size: 56,
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xF2000000), Color(0xB3000000), Color(0x30000000)],
            ),
          ),
        ),
        const Positioned(
          left: 18,
          top: 18,
          right: 100,
          bottom: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'CINEPREMIER F&B',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'Hương vị làm nên\ntrọn vẹn bộ phim',
                style: AppTextStyles.screenTitle,
              ),
              SizedBox(height: 8),
              Text(
                'Đặt trước, nhận nhanh tại quầy.',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
