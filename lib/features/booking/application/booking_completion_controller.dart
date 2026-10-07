import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_scenario.dart';
import '../../movie/data/models/food_quote_dto.dart';
import '../../movie/data/repositories/catalog_providers.dart';
import '../../orders/data/models/booking_dto.dart';
import '../../orders/data/models/booking_enums.dart';
import '../../orders/data/repositories/booking_providers.dart';
import '../../payment/data/models/payment_dto.dart';
import '../../payment/data/models/payment_enums.dart';
import '../../payment/data/repositories/payment_providers.dart';
import '../../seat/application/booking_entry_session.dart';
import '../../seat/data/repositories/seat_hold_providers.dart';

enum BookingCompletionPhase {
  idle,
  loading,
  choosingFood,
  preparingCheckout,
  checkout,
  creatingPayment,
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
  final Map<int, int> quantities;
  final String? message;

  bool get isBusy => switch (phase) {
    BookingCompletionPhase.loading ||
    BookingCompletionPhase.preparingCheckout ||
    BookingCompletionPhase.creatingPayment ||
    BookingCompletionPhase.verifyingBooking => true,
    _ => false,
  };

  BookingCompletionState copyWith({
    BookingCompletionPhase? phase,
    BookingDto? booking,
    CheckoutQuoteDto? quote,
    PaymentDto? payment,
    List<FoodProductDto>? products,
    Map<int, int>? quantities,
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
  BookingCompletionState build() => const BookingCompletionState();

  Future<void> load(int bookingId) async {
    if (state.booking?.id == bookingId &&
        state.phase != BookingCompletionPhase.idle) {
      return;
    }
    state = const BookingCompletionState(phase: BookingCompletionPhase.loading);
    try {
      final seatHold = ref.read(seatHoldRepositoryProvider);
      final booking = seatHold.canEnterMockCheckout
          ? await ref.read(bookingRepositoryProvider).getBooking(bookingId)
          : await seatHold.getBooking(bookingId);
      if (booking == null) throw StateError('Không tìm thấy booking.');
      if (booking.status == BookingStatus.expired) {
        state = BookingCompletionState(
          phase: BookingCompletionPhase.expired,
          booking: booking,
          message: 'Thời gian giữ ghế đã hết.',
        );
        return;
      }
      final products = <FoodProductDto>[];
      if (seatHold.canEnterMockCheckout) {
        final catalog = ref.read(mockCatalogRepositoryProvider);
        products.addAll(await catalog.getFoodCombos());
        products.addAll(await catalog.getFoodItems());
      }
      state = BookingCompletionState(
        phase: BookingCompletionPhase.choosingFood,
        booking: booking,
        products: products,
        quantities: {
          for (final food in booking.foods) food.productId: food.quantity,
        },
      );
    } catch (error) {
      state = BookingCompletionState(
        phase: BookingCompletionPhase.error,
        message: error.toString(),
      );
    }
  }

  void changeQuantity(int productId, int delta) {
    if (state.phase != BookingCompletionPhase.choosingFood) return;
    final next = Map<int, int>.from(state.quantities);
    final quantity = ((next[productId] ?? 0) + delta).clamp(0, 8);
    if (quantity == 0) {
      next.remove(productId);
    } else {
      next[productId] = quantity;
    }
    state = state.copyWith(quantities: next, clearMessage: true);
  }

  List<FoodSelectionDto> get _foodSelections => state.products
      .where((product) => (state.quantities[product.id] ?? 0) > 0)
      .map(
        (product) => FoodSelectionDto(
          productId: product.id,
          isCombo: product.isCombo,
          quantity: state.quantities[product.id]!,
        ),
      )
      .toList(growable: false);

  List<TicketSelectionDto> get _ticketSelections =>
      (state.booking?.tickets ?? const [])
          .map(
            (ticket) => TicketSelectionDto(
              seatId: ticket.seatId,
              ticketType: ticket.ticketType,
              viewerAge: ticket.viewerAge,
              quantity: ticket.quantity,
            ),
          )
          .toList(growable: false);

  Future<bool> prepareCheckout() async {
    final booking = state.booking;
    if (booking == null) return false;
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
      final seatHold = ref.read(seatHoldRepositoryProvider);
      final updated = seatHold.canEnterMockCheckout
          ? await ref
                .read(bookingRepositoryProvider)
                .updateItems(
                  booking.id,
                  UpdateHoldingBookingRequestDto(
                    tickets: _ticketSelections,
                    foods: _foodSelections,
                  ),
                )
          : booking;
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
                      viewerAge: ticket.viewerAge ?? 30,
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
      state = state.copyWith(
        phase: BookingCompletionPhase.checkout,
        booking: updated,
        quote: quote,
      );
      return true;
    } catch (error) {
      await _recoverBookingError(booking.id, error);
      return false;
    }
  }

  Future<PaymentDto?> createPayment() async {
    final booking = state.booking;
    if (booking == null) return null;
    state = state.copyWith(
      phase: BookingCompletionPhase.creatingPayment,
      clearMessage: true,
    );
    try {
      final checkedOut = await ref
          .read(bookingRepositoryProvider)
          .checkout(
            booking.id,
            UpdateHoldingBookingRequestDto(
              tickets: _ticketSelections,
              foods: _foodSelections,
            ),
          );
      final payment = await ref
          .read(paymentRepositoryProvider)
          .createPayment(
            DemoIds.user,
            CreatePaymentRequestDto(bookingId: checkedOut.id),
          );
      state = state.copyWith(
        phase: BookingCompletionPhase.paymentPending,
        booking: checkedOut,
        payment: payment,
      );
      return payment;
    } catch (error) {
      await _recoverBookingError(booking.id, error);
      return null;
    }
  }

  Future<void> attachPayment(int paymentId) async {
    if (state.payment?.id == paymentId) return;
    final payment = await ref
        .read(paymentRepositoryProvider)
        .getPayment(paymentId);
    if (payment == null) {
      state = state.copyWith(
        phase: BookingCompletionPhase.error,
        message: 'Không tìm thấy giao dịch thanh toán.',
      );
      return;
    }
    final booking = payment.bookingId == null
        ? null
        : await ref
              .read(bookingRepositoryProvider)
              .getBooking(payment.bookingId!);
    state = state.copyWith(
      phase: payment.status == PaymentStatus.failed
          ? BookingCompletionPhase.paymentFailed
          : BookingCompletionPhase.paymentPending,
      payment: payment,
      booking: booking,
    );
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
    final booking = state.booking;
    if (booking == null) return null;
    try {
      final refreshed = await ref
          .read(bookingRepositoryProvider)
          .getBooking(booking.id);
      if (refreshed == null || refreshed.status == BookingStatus.expired) {
        state = state.copyWith(
          phase: BookingCompletionPhase.expired,
          booking: refreshed ?? booking,
          message: 'Phiên giữ ghế đã hết. Vui lòng chọn lại ghế.',
        );
        return null;
      }
      final payment = await ref
          .read(paymentRepositoryProvider)
          .createPayment(
            DemoIds.user,
            CreatePaymentRequestDto(bookingId: booking.id),
          );
      state = state.copyWith(
        phase: BookingCompletionPhase.paymentPending,
        payment: payment,
        booking: refreshed,
        clearMessage: true,
      );
      return payment;
    } catch (error) {
      state = state.copyWith(
        phase: BookingCompletionPhase.error,
        message: error.toString(),
      );
      return null;
    }
  }

  Future<void> _recoverBookingError(int bookingId, Object error) async {
    final booking = await ref
        .read(bookingRepositoryProvider)
        .getBooking(bookingId);
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
  return ref.watch(bookingRepositoryProvider).getBooking(id);
});
