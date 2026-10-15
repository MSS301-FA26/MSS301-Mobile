import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/checkout_summary.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
import '../../../auth/application/auth_session.dart';
import '../../../movie/data/repositories/catalog_providers.dart';
import '../../../payment/application/payment_launcher.dart';
import '../../data/models/food_order_dto.dart';
import '../../data/repositories/standalone_food_repository.dart';
import '../../data/repositories/food_order_providers.dart';
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
      if (sync) _message = 'Đang kiểm tra kết quả với hệ thống…';
    });
    try {
      final repo = ref.read(standaloneFoodRepositoryProvider);
      final order = sync
          ? await repo.sync(widget.orderId, cancelToken: cancel)
          : await repo.get(widget.orderId, cancelToken: cancel);
      if (!mounted || generation != _generation) return;
      setState(() {
        _order = order;
        if (sync) {
          _message = order.status == FoodOrderStatus.paid
              ? 'Thanh toán đã được xác nhận. Mã nhận hàng đã sẵn sàng.'
              : order.status == FoodOrderStatus.pendingPayment
              ? 'Đơn vẫn chờ thanh toán. Nếu đã trả tiền, hãy kiểm tra lại sau.'
              : 'Trạng thái mới nhất: ${order.status.label}.';
        }
      });
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
      _message = 'Đang mở VNPay…';
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
          if (order?.status == FoodOrderStatus.pendingPayment &&
              seconds != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    color: AppColors.gold,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      seconds == 0
                          ? 'Hết thời gian • Hãy kiểm tra kết quả đơn'
                          : seconds <= 60
                          ? 'Sắp hết thời gian thanh toán'
                          : 'Thời gian thanh toán còn lại',
                      style: AppTextStyles.caption,
                    ),
                  ),
                  Text(
                    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
                    style: AppTextStyles.cardTitle.copyWith(
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: order == null
                ? _busy
                      ? const RepositoryStatePane.loading(
                          title: 'Đang tải đơn…',
                        )
                      : RepositoryStatePane.error(
                          title: 'Chưa tải được đơn',
                          message: _error,
                          onRetry: () => _refresh(),
                        )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      CheckoutSection(
                        title: 'Thông tin đơn',
                        children: [
                          CheckoutLine(
                            'Mã đơn',
                            order.orderCode.isEmpty
                                ? '#${order.id}'
                                : order.orderCode,
                            stacked: true,
                          ),
                          CheckoutLine(
                            'Trạng thái',
                            order.status.label,
                            emphasized: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CheckoutSection(
                        title: 'Bắp nước',
                        children: [
                          for (final item in order.items)
                            CheckoutLine(
                              '${item.productName} x ${item.quantity}',
                              item.lineTotal.format(),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (order.status == FoodOrderStatus.paid &&
                          order.qrCode?.isNotEmpty == true)
                        Center(
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.all(12),
                            child: QrImageView(data: order.qrCode!, size: 200),
                          ),
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
          if (order != null)
            PaymentActionBar(
              total: order.totalAmount,
              buttonKey: ValueKey(_pending ? 'food-pay' : 'food-refresh'),
              icon: _pending ? Icons.lock_outline : Icons.refresh,
              label: _busy
                  ? 'Đang xử lý…'
                  : !_pending
                  ? 'Kiểm tra kết quả đơn'
                  : changed
                  ? 'Xác nhận giá mới & thanh toán'
                  : 'Thanh toán VNPay',
              notice: [
                if (changed && _pending)
                  'Giá đã thay đổi. Kiểm tra tổng mới trước khi thanh toán.',
                ?_message,
                ?_error,
              ].where((message) => message.isNotEmpty).join('\n'),
              loading: _busy,
              onPressed: _busy
                  ? null
                  : _pending
                  ? _pay
                  : () => _refresh(sync: true),
            ),
        ],
      ),
    );
  }
}
