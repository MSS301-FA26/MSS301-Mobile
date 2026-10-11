import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../movie/data/models/food_quote_dto.dart';
import '../../auth/application/auth_session.dart';
import '../../orders/presentation/providers/orders_provider.dart';
import '../../movie/data/repositories/catalog_providers.dart';
import '../../orders/data/models/booking_dto.dart';
import '../../orders/data/models/booking_enums.dart';
import '../../orders/data/repositories/booking_providers.dart';
import '../../payment/application/payment_launcher.dart';
import '../../payment/data/models/payment_dto.dart';
import '../../payment/data/models/payment_enums.dart';
import '../../payment/data/repositories/payment_providers.dart';
import '../../seat/application/booking_entry_session.dart';
import '../../seat/data/repositories/seat_hold_providers.dart';
import 'booking_checkpoint.dart';

enum BookingCompletionPhase {
  idle,
  loading,
  choosingFood,
  preparingCheckout,
  checkout,
  creatingPayment,
  openingPaymentGateway,
  paymentPending,
  paymentFailed,
  verifyingBooking,
  ticketReady,
  expired,
  error,
}

class BookingCompletionState {
  const BookingCompletionState({
    this.phase = BookingCompletionPhase.idle,
    this.booking,
    this.quote,
    this.payment,
    this.products = const [],
    this.quantities = const {},
    this.message,
  });

  final BookingCompletionPhase phase;
  final BookingDto? booking;
  final CheckoutQuoteDto? quote;
  final PaymentDto? payment;
  final List<FoodProductDto> products;
  final Map<String, int> quantities;
  final String? message;

  bool get isBusy => switch (phase) {
    BookingCompletionPhase.loading ||
    BookingCompletionPhase.preparingCheckout ||
    BookingCompletionPhase.creatingPayment ||
    BookingCompletionPhase.openingPaymentGateway => true,
    _ => false,
  };

  BookingCompletionState copyWith({
    BookingCompletionPhase? phase,
    BookingDto? booking,
    CheckoutQuoteDto? quote,
    PaymentDto? payment,
    List<FoodProductDto>? products,
    Map<String, int>? quantities,
    String? message,
    bool clearMessage = false,
  }) => BookingCompletionState(
    phase: phase ?? this.phase,
    booking: booking ?? this.booking,
    quote: quote ?? this.quote,
    payment: payment ?? this.payment,
    products: products ?? this.products,
    quantities: quantities ?? this.quantities,
    message: clearMessage ? null : message ?? this.message,
  );
}

class BookingCompletionController extends Notifier<BookingCompletionState> {
  @override
  BookingCompletionState build() {
    _generation++;
    ref.watch(authSessionProvider.select((auth) => auth.session?.user.id));
    return const BookingCompletionState();
  }

  bool _refreshing = false;
  int _generation = 0;

  bool get _expired =>
      state.booking?.status == BookingStatus.expired ||
      (state.booking?.holdExpiresAt != null &&
          !ref
              .read(appClockProvider)
              .now()
              .isBefore(state.booking!.holdExpiresAt!));

  void returnToFood() {
    if (!state.isBusy && state.booking != null && state.payment == null) {
      state = state.copyWith(phase: BookingCompletionPhase.choosingFood);
    }
  }

  Future<void> load(int bookingId) async {
    final generation = _generation;
    if (state.booking?.id == bookingId &&
        state.phase != BookingCompletionPhase.idle &&
        state.phase != BookingCompletionPhase.error) {
      return;
    }
    state = const BookingCompletionState(phase: BookingCompletionPhase.loading);
    try {
      final seatHold = ref.read(seatHoldRepositoryProvider);
      final booking = seatHold.canEnterMockCheckout
          ? await ref.read(bookingRepositoryProvider).getBooking(bookingId)
          : await seatHold.getBooking(bookingId);
      if (!ref.mounted || generation != _generation) return;
      if (booking == null) throw StateError('Không tìm thấy booking.');
      final userId = ref.read(authSessionProvider).session?.user.id;
      final checkpoint = userId == null
          ? null
          : await ref.read(bookingCheckpointStoreProvider).read(userId);
      if (!ref.mounted || generation != _generation) return;
      ref
          .read(bookingEntryProvider.notifier)
          .restoreBooking(
            booking,
            viewerAges: checkpoint?.bookingId == booking.id
                ? checkpoint!.viewerAges
                : const {},
          );
      if (booking.status == BookingStatus.expired ||
          booking.status == BookingStatus.cancelled ||
          (booking.holdExpiresAt != null &&
              !ref
                  .read(appClockProvider)
                  .now()
                  .isBefore(booking.holdExpiresAt!) &&
              booking.status != BookingStatus.paid &&
              booking.status != BookingStatus.used)) {
        state = BookingCompletionState(
          phase: BookingCompletionPhase.expired,
          booking: booking,
          message: 'Thời gian giữ ghế đã hết.',
        );
        return;
      }
      if (booking.status == BookingStatus.pendingPayment) {
        final payment = await findExistingPayment(booking.id);
        if (payment != null) return;
      }
      if (booking.status != BookingStatus.holding &&
          booking.status != BookingStatus.pendingPayment) {
        throw StateError(
          'Đơn không còn ở trạng thái có thể chỉnh sửa. Vui lòng xem trong Đơn của tôi.',
        );
      }
      final products = <FoodProductDto>[];
      final catalog = ref.read(catalogRepositoryProvider);
      final lists = await Future.wait([
        catalog.getFoodCombos(),
        catalog.getFoodItems(),
      ]);
      if (!ref.mounted || generation != _generation) return;
      products.addAll(lists.expand((items) => items));
      state = BookingCompletionState(
        phase: BookingCompletionPhase.choosingFood,
        booking: booking,
        products: products,
        quantities: {
          for (final food in booking.foods)
            '${food.isCombo ? 'combo' : 'item'}:${food.productId}':
                food.quantity,
        },
      );
    } catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = BookingCompletionState(
        phase: BookingCompletionPhase.error,
        message: error.toString(),
      );
    }
  }

  void changeQuantity(int productId, int delta, {bool isCombo = false}) {
    if (state.phase != BookingCompletionPhase.choosingFood) return;
    final product = state.products
        .where((p) => p.id == productId && p.isCombo == isCombo)
        .firstOrNull;
    if (product == null || (delta > 0 && !product.isAvailable)) {
      return;
    }
    final key = product.selectionKey;
    final next = Map<String, int>.from(state.quantities);
    final quantity = ((next[key] ?? 0) + delta).clamp(0, 8);
    if (quantity == 0) {
      next.remove(key);
    } else {
      next[key] = quantity;
    }
    state = state.copyWith(quantities: next, clearMessage: true);
  }

  List<FoodSelectionDto> get _foodSelections => state.products
      .where((product) => (state.quantities[product.selectionKey] ?? 0) > 0)
      .map(
        (product) => FoodSelectionDto(
          productId: product.id,
          isCombo: product.isCombo,
          quantity: state.quantities[product.selectionKey]!,
        ),
      )
      .toList(growable: false);

  List<TicketSelectionDto> get _ticketSelections =>
      (state.booking?.tickets ?? const [])
          .map(
            (ticket) => TicketSelectionDto(
              seatId: ticket.seatId,
              ticketType: ticket.ticketType,
              viewerAge:
                  ref
                      .read(bookingEntryProvider)
                      .assignments[ticket.seatId]
                      ?.viewerAge ??
                  ticket.viewerAge,
              quantity: ticket.quantity,
            ),
          )
          .toList(growable: false);

  Future<bool> prepareCheckout() async {
    final generation = _generation;
    final booking = state.booking;
    if (booking == null || state.isBusy || state.payment != null) return false;
    final expiry = booking.holdExpiresAt;
    if (expiry != null && !ref.read(appClockProvider).now().isBefore(expiry)) {
      state = state.copyWith(
        phase: BookingCompletionPhase.expired,
        message: 'Thời gian giữ ghế đã hết.',
      );
      return false;
    }
    state = state.copyWith(
      phase: BookingCompletionPhase.preparingCheckout,
      clearMessage: true,
    );
    try {
      final updated = await ref
          .read(bookingRepositoryProvider)
          .updateItems(
            booking.id,
            UpdateHoldingBookingRequestDto(
              tickets: _ticketSelections,
              foods: _foodSelections,
            ),
          );
      if (!ref.mounted || generation != _generation) return false;
      final quote = await ref
          .read(catalogRepositoryProvider)
          .createCheckoutQuote(
            CheckoutQuoteRequestDto(
              showtimeId: updated.showtimeId,
              seatIds: updated.seats
                  .map((seat) => seat.seatId)
                  .toList(growable: false),
              tickets: updated.tickets
                  .map(
                    (ticket) => QuoteTicketRequestDto(
                      seatId: ticket.seatId,
                      ticketType: ticket.ticketType,
                      viewerAge:
                          ref
                              .read(bookingEntryProvider)
                              .assignments[ticket.seatId]
                              ?.viewerAge ??
                          ticket.viewerAge ??
                          (throw StateError(
                            'Thiếu tuổi người xem. Hãy chọn lại vé.',
                          )),
                      quantity: ticket.quantity,
                    ),
                  )
                  .toList(growable: false),
              foods: _foodSelections
                  .map(
                    (food) => QuoteFoodRequestDto(
                      productId: food.productId,
                      isCombo: food.isCombo,
                      quantity: food.quantity,
                    ),
                  )
                  .toList(growable: false),
              bookingSessionId: updated.id,
            ),
          );
      if (!ref.mounted || generation != _generation) return false;
      if (updated.totalAmount != quote.total) {
        throw StateError(
          'Tổng tiền đơn và báo giá chưa khớp. Vui lòng thử lại.',
        );
      }
      state = state.copyWith(
        phase: BookingCompletionPhase.checkout,
        booking: updated,
        quote: quote,
      );
      return true;
    } catch (error) {
      if (ref.mounted && generation == _generation) {
        await _recoverBookingError(booking.id, error);
      }
      return false;
    }
  }

  Future<PaymentDto?> createPayment() async {
    final generation = _generation;
    final booking = state.booking;
    if (booking == null || state.isBusy || state.quote == null) return null;
    if (_expired) {
      state = state.copyWith(
        phase: BookingCompletionPhase.expired,
        message: 'Thời gian giữ ghế đã hết.',
      );
      return null;
    }
    if (!ref.read(appClockProvider).now().isBefore(state.quote!.validUntil)) {
      await prepareCheckout();
      state = state.copyWith(
        message: 'Báo giá đã được cập nhật. Vui lòng kiểm tra và xác nhận lại.',
      );
      return null;
    }
    state = state.copyWith(
      phase: BookingCompletionPhase.creatingPayment,
      clearMessage: true,
    );
    try {
      final existing = await ref
          .read(paymentRepositoryProvider)
          .getPaymentByBooking(booking.id);
      if (!ref.mounted || generation != _generation) return null;
      if (existing != null && existing.status != PaymentStatus.failed) {
        await _applyPayment(existing);
        return existing;
      }
      final checkedOut = await ref
          .read(bookingRepositoryProvider)
          .checkout(
            booking.id,
            UpdateHoldingBookingRequestDto(
              tickets: _ticketSelections,
              foods: _foodSelections,
            ),
          );
      if (!ref.mounted || generation != _generation) return null;
      state = state.copyWith(booking: checkedOut);
      if (checkedOut.totalAmount != state.quote!.total) {
        throw StateError(
          'Tổng tiền đã thay đổi. Vui lòng cập nhật đơn và xác nhận lại.',
        );
      }
      final payment = await ref
          .read(paymentRepositoryProvider)
          .createPayment(0, CreatePaymentRequestDto(bookingId: checkedOut.id));
      if (!ref.mounted || generation != _generation) return null;
      state = state.copyWith(
        phase: BookingCompletionPhase.paymentPending,
        booking: checkedOut,
        payment: payment,
      );
      await _applyPayment(payment);
      return payment;
    } catch (error) {
      if (ref.mounted && generation == _generation) {
        await _recoverBookingError(booking.id, error);
      }
      return null;
    }
  }

  Future<void> attachPayment(int paymentId) async {
    final generation = _generation;
    if (state.payment?.id == paymentId) {
      await refreshPaymentStatus();
      return;
    }
    try {
      final payment = await ref
          .read(paymentRepositoryProvider)
          .getPayment(paymentId);
      if (!ref.mounted || generation != _generation) return;
      if (payment == null) {
        throw StateError('Không tìm thấy giao dịch thanh toán.');
      }
      await _applyPayment(payment);
    } catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        phase: BookingCompletionPhase.error,
        message: error.toString(),
      );
    }
  }

  Future<bool> _applyPayment(PaymentDto payment) async {
    final generation = _generation;
    if (payment.bookingId == null) {
      throw StateError('Giao dịch không thuộc đơn vé.');
    }
    final booking = await ref
        .read(bookingRepositoryProvider)
        .getBooking(payment.bookingId!);
    if (!ref.mounted || generation != _generation) return false;
    if (booking == null) throw StateError('Không tìm thấy đơn vé.');
    final ready =
        payment.status == PaymentStatus.success &&
        (booking.status == BookingStatus.paid ||
            booking.status == BookingStatus.used);
    final expired =
        booking.status == BookingStatus.expired ||
        booking.status == BookingStatus.cancelled ||
        (payment.status != PaymentStatus.success &&
            booking.holdExpiresAt != null &&
            !ref.read(appClockProvider).now().isBefore(booking.holdExpiresAt!));
    state = state.copyWith(
      phase: ready
          ? BookingCompletionPhase.ticketReady
          : expired
          ? BookingCompletionPhase.expired
          : payment.status == PaymentStatus.failed
          ? BookingCompletionPhase.paymentFailed
          : payment.status == PaymentStatus.success
          ? BookingCompletionPhase.verifyingBooking
          : BookingCompletionPhase.paymentPending,
      payment: payment,
      booking: booking,
      message: !ready && payment.status == PaymentStatus.success
          ? 'Đã ghi nhận thanh toán. Đang chờ phát hành vé; bạn có thể kiểm tra lại.'
          : null,
      clearMessage: ready || payment.status != PaymentStatus.success,
    );
    if (ready) {
      ref.invalidate(bookingEntryProvider);
      ref.invalidate(ordersProvider);
      ref.invalidate(ticketBookingProvider(booking.id));
    }
    final userId = ref.read(authSessionProvider).session?.user.id;
    if (userId != null) {
      final store = ref.read(bookingCheckpointStoreProvider);
      if (ready || expired) {
        await store.clear(userId);
      } else {
        final saved = await store.read(userId);
        await store.save(
          userId,
          BookingCheckpoint(
            bookingId: booking.id,
            paymentId: payment.id,
            viewerAges: saved?.bookingId == booking.id
                ? saved!.viewerAges
                : const {},
          ),
        );
      }
      ref.invalidate(resumableBookingProvider);
    }
    return ready;
  }

  Future<PaymentDto?> findExistingPayment(int bookingId) async {
    final generation = _generation;
    try {
      final payment = await ref
          .read(paymentRepositoryProvider)
          .getPaymentByBooking(bookingId);
      if (!ref.mounted || generation != _generation) return null;
      if (payment != null) await _applyPayment(payment);
      return payment;
    } catch (error) {
      if (!ref.mounted || generation != _generation) return null;
      state = state.copyWith(message: error.toString());
      rethrow;
    }
  }

  Future<bool> openPaymentGateway({
    PaymentLaunchMode mode = PaymentLaunchMode.inAppWebView,
  }) async {
    final generation = _generation;
    final payment = state.payment;
    if (payment == null || state.isBusy) return false;

    state = state.copyWith(
      phase: BookingCompletionPhase.openingPaymentGateway,
      clearMessage: true,
    );

    try {
      final result = await ref
          .read(paymentLauncherProvider)
          .open(payment, mode: mode);
      if (!ref.mounted || generation != _generation) return false;
      state = state.copyWith(
        phase: BookingCompletionPhase.paymentPending,
        message: result.message,
      );
      return result.isUsable;
    } catch (error) {
      if (ref.mounted && generation == _generation) {
        state = state.copyWith(
          phase: BookingCompletionPhase.paymentPending,
          message: 'Không thể mở thanh toán. Vui lòng thử lại.',
        );
      }
      return false;
    }
  }

  Future<bool> refreshPaymentStatus() async {
    final generation = _generation;
    final payment = state.payment;
    if (payment == null || _refreshing) return false;
    _refreshing = true;
    try {
      final refreshed = await ref
          .read(paymentRepositoryProvider)
          .getPayment(payment.id);
      if (!ref.mounted || generation != _generation) return false;
      if (refreshed == null) {
        throw StateError('Không tìm thấy giao dịch thanh toán.');
      }
      return await _applyPayment(refreshed);
    } catch (error) {
      if (!ref.mounted || generation != _generation) return false;
      state = state.copyWith(message: 'Không thể kiểm tra thanh toán: $error');
      return false;
    } finally {
      _refreshing = false;
    }
  }

  Future<bool> simulateSuccess() async {
    final payment = state.payment;
    if (payment == null) return false;
    try {
      final succeeded = payment.status == PaymentStatus.success
          ? payment
          : await ref.read(paymentRepositoryProvider).markSuccess(payment.id);
      state = state.copyWith(
        phase: BookingCompletionPhase.verifyingBooking,
        payment: succeeded,
        message: 'Thanh toán đã thành công. Đang xác minh booking…',
      );
      await ref
          .read(paymentRepositoryProvider)
          .confirmSuccessfulBooking(succeeded.id);
      final booking = await ref
          .read(bookingRepositoryProvider)
          .getBooking(succeeded.bookingId!);
      if (booking?.status != BookingStatus.paid) {
        throw StateError('Booking chưa được xác nhận PAID.');
      }
      ref.invalidate(bookingEntryProvider);
      state = state.copyWith(
        phase: BookingCompletionPhase.ticketReady,
        booking: booking,
        clearMessage: true,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        phase: BookingCompletionPhase.error,
        message: error.toString(),
      );
      return false;
    }
  }

  Future<void> simulateFailure() async {
    final payment = state.payment;
    if (payment == null || payment.status != PaymentStatus.pending) return;
    final failed = await ref
        .read(paymentRepositoryProvider)
        .markFailed(payment.id);
    state = state.copyWith(
      phase: BookingCompletionPhase.paymentFailed,
      payment: failed,
      message: 'Giao dịch bị từ chối. Ghế vẫn được giữ nếu phiên chưa hết hạn.',
    );
  }

  Future<PaymentDto?> retryPayment() async {
    final generation = _generation;
    final booking = state.booking;
    if (booking == null || state.isBusy) return null;
    state = state.copyWith(
      phase: BookingCompletionPhase.creatingPayment,
      clearMessage: true,
    );
    try {
      final refreshed = await ref
          .read(bookingRepositoryProvider)
          .getBooking(booking.id);
      if (!ref.mounted || generation != _generation) return null;
      if (refreshed == null || refreshed.status == BookingStatus.expired) {
        state = state.copyWith(
          phase: BookingCompletionPhase.expired,
          booking: refreshed ?? booking,
          message: 'Phiên giữ ghế đã hết. Vui lòng chọn lại ghế.',
        );
        return null;
      }
      final existing = await ref
          .read(paymentRepositoryProvider)
          .getPaymentByBooking(booking.id);
      if (!ref.mounted || generation != _generation) return null;
      if (existing != null && existing.status != PaymentStatus.failed) {
        await _applyPayment(existing);
        return existing;
      }
      if (refreshed.status != BookingStatus.pendingPayment) {
        throw StateError(
          'Đơn chưa sẵn sàng thanh toán. Vui lòng quay lại xác nhận đơn.',
        );
      }
      final payment = await ref
          .read(paymentRepositoryProvider)
          .createPayment(0, CreatePaymentRequestDto(bookingId: booking.id));
      if (!ref.mounted || generation != _generation) return null;
      state = state.copyWith(
        phase: BookingCompletionPhase.paymentPending,
        payment: payment,
        booking: refreshed,
        clearMessage: true,
      );
      return payment;
    } catch (error) {
      if (!ref.mounted || generation != _generation) return null;
      state = state.copyWith(
        phase: BookingCompletionPhase.error,
        message: error.toString(),
      );
      return null;
    }
  }

  Future<void> _recoverBookingError(int bookingId, Object error) async {
    final generation = _generation;
    BookingDto? booking;
    try {
      booking = await ref.read(bookingRepositoryProvider).getBooking(bookingId);
    } catch (_) {
      // Preserve the original failure if the follow-up request is also offline.
    }
    if (!ref.mounted || generation != _generation) return;
    state = state.copyWith(
      phase: booking?.status == BookingStatus.expired
          ? BookingCompletionPhase.expired
          : BookingCompletionPhase.error,
      booking: booking,
      message: booking?.status == BookingStatus.expired
          ? 'Thời gian giữ ghế đã hết.'
          : error.toString(),
    );
  }
}

final bookingCompletionProvider =
    NotifierProvider<BookingCompletionController, BookingCompletionState>(
      BookingCompletionController.new,
    );

final ticketBookingProvider = FutureProvider.family<BookingDto?, int>((
  ref,
  id,
) {
  return ref.watch(seatHoldRepositoryProvider).getBooking(id);
});
