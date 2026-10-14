import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/application/auth_session.dart';
import '../../../movie/data/repositories/catalog_providers.dart';
import '../../../payment/application/payment_launcher.dart';
import '../../data/models/food_order_dto.dart';
import '../../data/repositories/standalone_food_repository.dart';
import '../../data/repositories/food_order_providers.dart';
import '../widgets/food_order_card.dart';
import 'standalone_food_page.dart';

class FoodCheckoutPage extends ConsumerStatefulWidget {
  const FoodCheckoutPage({
    super.key,
    required this.orderId,
    this.expectedTotal,
  });
  final int orderId;
  final int? expectedTotal;
  @override
  ConsumerState<FoodCheckoutPage> createState() => _FoodCheckoutPageState();
}

class _FoodCheckoutPageState extends ConsumerState<FoodCheckoutPage>
    with WidgetsBindingObserver {
  FoodOrderDto? _order;
  String? _error, _message;
  bool _busy = false;
  int _generation = 0;
  CancelToken? _cancel;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _order?.status == FoodOrderStatus.pendingPayment) {
        setState(() {});
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) _refresh(sync: true);
  }

  @override
  void dispose() {
    _cancel?.cancel();
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool get _pending =>
      _order?.status == FoodOrderStatus.pendingPayment &&
      (_order!.expiresAt == null ||
          ref
              .read(appClockProvider)
              .now()
              .toUtc()
              .isBefore(_order!.expiresAt!));
  Future<void> _refresh({bool sync = false}) async {
    if (_busy || !mounted) return;
    final generation = _generation;
    final cancel = CancelToken();
    _cancel = cancel;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(standaloneFoodRepositoryProvider);
      final order = sync
          ? await repo.sync(widget.orderId, cancelToken: cancel)
          : await repo.get(widget.orderId, cancelToken: cancel);
      if (!mounted || generation != _generation) return;
      setState(() => _order = order);
      ref.invalidate(myFoodOrdersProvider);
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() => _error = foodActionError(error));
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  Future<void> _pay() async {
    if (_busy || !_pending) return;
    final user = ref.read(authSessionProvider).session?.user;
    if (user == null) return;
    final generation = _generation;
    setState(() {
      _busy = true;
      _error = null;
      _message = null;
    });
    try {
      final payment = await ref
          .read(standaloneFoodRepositoryProvider)
          .payment(widget.orderId, user.id);
      if (!mounted || generation != _generation) return;
      if (payment.userId != user.id || payment.foodOrderId != widget.orderId) {
        throw StateError('Payment ownership mismatch');
      }
      if (payment.status.wireValue == 'SUCCESS') {
        setState(() => _busy = false);
        await _refresh(sync: true);
        return;
      }
      if (!_pending) {
        setState(() => _message = 'Thời gian thanh toán đơn đã hết.');
        return;
      }
      final result = await ref.read(paymentLauncherProvider).open(payment);
      if (!mounted || generation != _generation) return;
      setState(() => _message = result.message);
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() => _error = foodActionError(error));
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  Future<void> _cancelOrder() async {
    if (_busy || !_pending) return;
    final generation = _generation;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đơn bắp nước?'),
        content: const Text('Hủy đơn đang chờ thanh toán này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Quay lại'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );
    if (confirmed != true ||
        !mounted ||
        _busy ||
        generation != _generation ||
        !_pending) {
      return;
    }
    final cancel = CancelToken();
    _cancel = cancel;
    setState(() => _busy = true);
    try {
      final order = await ref
          .read(standaloneFoodRepositoryProvider)
          .cancel(widget.orderId, cancelToken: cancel);
      if (mounted && generation == _generation) {
        setState(() => _order = order);
        ref.invalidate(myFoodOrdersProvider);
      }
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() => _error = foodActionError(error));
      }
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
            _order = null;
            _error = null;
            _message = null;
            _busy = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _refresh();
          });
        }
      },
    );
    final order = _order;
    final remaining = order?.expiresAt?.difference(
      ref.watch(appClockProvider).now().toUtc(),
    );
    final seconds = remaining?.inSeconds.clamp(0, 86400);
    final changed =
        order != null &&
        widget.expectedTotal != null &&
        order.totalAmount.amount != widget.expectedTotal;
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
              'Đơn bắp nước',
              style: AppTextStyles.sectionTitle,
            ),
          ),
          Expanded(
            child: order == null
                ? Center(
                    child: _busy
                        ? const CircularProgressIndicator()
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _error ?? 'Chưa tải được đơn.',
                                textAlign: TextAlign.center,
                              ),
                              TextButton(
                                onPressed: () => _refresh(),
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      FoodOrderCard(order: order),
                      const SizedBox(height: 16),
                      if (changed)
                        const Text(
                          'Giá đã được cập nhật. Hãy kiểm tra tổng tiền mới trước khi xác nhận thanh toán.',
                          style: AppTextStyles.body,
                        ),
                      if (order.status == FoodOrderStatus.pendingPayment &&
                          seconds != null)
                        Text(
                          'Thời gian thanh toán còn lại: ${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
                          style: AppTextStyles.caption,
                        ),
                      if (order.status == FoodOrderStatus.pendingPayment &&
                          !_pending)
                        const Text(
                          'Thời gian thanh toán đơn đã hết.',
                          style: AppTextStyles.caption,
                        ),
                      if (order.status == FoodOrderStatus.paid &&
                          order.qrCode?.isNotEmpty == true)
                        Center(
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.all(12),
                            child: QrImageView(data: order.qrCode!, size: 200),
                          ),
                        ),
                      if (_message != null)
                        Text(_message!, style: AppTextStyles.caption),
                      if (_error != null)
                        Text(_error!, style: AppTextStyles.caption),
                      const SizedBox(height: 16),
                      if (_pending)
                        AppButton(
                          key: const ValueKey('food-pay'),
                          label: _busy
                              ? 'Đang xử lý…'
                              : changed
                              ? 'Xác nhận giá mới & thanh toán'
                              : 'Thanh toán VNPay',
                          onPressed: _busy ? null : _pay,
                        ),
                      TextButton(
                        onPressed: _busy ? null : () => _refresh(sync: true),
                        child: const Text('Kiểm tra trạng thái thanh toán'),
                      ),
                      if (_pending)
                        TextButton(
                          onPressed: _busy ? null : _cancelOrder,
                          child: const Text('Hủy đơn'),
                        ),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.foodOrders),
                        child: const Text('Lịch sử đơn bắp nước'),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
