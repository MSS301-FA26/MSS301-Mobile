import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_scenario.dart';
import '../../movie/data/repositories/catalog_providers.dart';
import '../../orders/data/models/booking_dto.dart';
import '../../orders/data/models/booking_enums.dart';
import '../../orders/data/repositories/booking_providers.dart';
import '../../orders/data/repositories/booking_repository.dart';

enum BookingEntryPhase {
  idle,
  selectingSeats,
  submittingHold,
  holding,
  expired,
}

class BookingEntryState {
  const BookingEntryState({
    required this.phase,
    this.movieId,
    this.showtimeId,
    this.selectedSeatIds = const {},
    this.unavailableSeatIds = const {},
    this.booking,
    this.message,
  });

  const BookingEntryState.idle() : this(phase: BookingEntryPhase.idle);

  final BookingEntryPhase phase;
  final int? movieId;
  final int? showtimeId;
  final Set<int> selectedSeatIds;
  final Set<int> unavailableSeatIds;
  final BookingDto? booking;
  final String? message;

  bool get hasActiveDraft => phase != BookingEntryPhase.idle;
  bool get hasActiveHold =>
      booking?.status == BookingStatus.holding ||
      booking?.status == BookingStatus.pendingPayment;
}

class BookingEntryController extends Notifier<BookingEntryState> {
  @override
  BookingEntryState build() => const BookingEntryState.idle();

  void begin({required int movieId, required int showtimeId}) {
    if (state.showtimeId == showtimeId && state.hasActiveDraft) return;
    state = BookingEntryState(
      phase: BookingEntryPhase.selectingSeats,
      movieId: movieId,
      showtimeId: showtimeId,
    );
  }

  void toggleSeatIds(Set<int> seatIds) {
    if (state.phase != BookingEntryPhase.selectingSeats) return;
    final next = {...state.selectedSeatIds};
    final allSelected = seatIds.every(next.contains);
    if (allSelected) {
      next.removeAll(seatIds);
    } else {
      if (next.length + seatIds.where((id) => !next.contains(id)).length > 6) {
        state = _copy(message: 'Bạn chỉ có thể chọn tối đa 6 ghế.');
        return;
      }
      next.addAll(seatIds);
    }
    state = _copy(selectedSeatIds: next, clearMessage: true);
  }

  Future<BookingDto?> holdSelectedSeats() async {
    final showtimeId = state.showtimeId;
    if (showtimeId == null || state.selectedSeatIds.isEmpty) return null;
    state = _copy(phase: BookingEntryPhase.submittingHold, clearMessage: true);
    try {
      final booking = await ref
          .read(bookingRepositoryProvider)
          .holdSeats(
            DemoIds.user,
            HoldSeatsRequestDto(
              showtimeId: showtimeId,
              seatIds: state.selectedSeatIds.toList(growable: false),
            ),
          );
      state = _copy(phase: BookingEntryPhase.holding, booking: booking);
      return booking;
    } on BookingConflictException catch (error) {
      state = _copy(
        phase: BookingEntryPhase.selectingSeats,
        unavailableSeatIds: {
          ...state.unavailableSeatIds,
          ...state.selectedSeatIds,
        },
        selectedSeatIds: const {},
        message: error.message,
      );
      return null;
    }
  }

  Future<bool> refreshExpiry() async {
    final booking = state.booking;
    if (booking == null || !state.hasActiveHold) return false;
    final refreshed = await ref
        .read(bookingRepositoryProvider)
        .getBooking(booking.id);
    if (refreshed?.status != BookingStatus.expired) return false;
    state = _copy(
      phase: BookingEntryPhase.expired,
      booking: refreshed,
      message: 'Thời gian giữ ghế đã hết.',
    );
    return true;
  }

  Duration remainingHold() {
    final expiry = state.booking?.holdExpiresAt;
    if (expiry == null) return Duration.zero;
    final remaining = expiry.difference(ref.read(appClockProvider).now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Future<void> abandon() async {
    final booking = state.booking;
    if (booking != null && state.hasActiveHold) {
      try {
        await ref.read(bookingRepositoryProvider).cancel(booking.id);
      } on BookingConflictException {
        // The mock may already have expired the hold; clearing local state is safe.
      }
    }
    state = const BookingEntryState.idle();
  }

  void restartSelection() {
    state = BookingEntryState(
      phase: BookingEntryPhase.selectingSeats,
      movieId: state.movieId,
      showtimeId: state.showtimeId,
    );
  }

  BookingEntryState _copy({
    BookingEntryPhase? phase,
    Set<int>? selectedSeatIds,
    Set<int>? unavailableSeatIds,
    BookingDto? booking,
    String? message,
    bool clearMessage = false,
  }) => BookingEntryState(
    phase: phase ?? state.phase,
    movieId: state.movieId,
    showtimeId: state.showtimeId,
    selectedSeatIds: selectedSeatIds ?? state.selectedSeatIds,
    unavailableSeatIds: unavailableSeatIds ?? state.unavailableSeatIds,
    booking: booking ?? state.booking,
    message: clearMessage ? null : message ?? state.message,
  );
}

final bookingEntryProvider =
    NotifierProvider<BookingEntryController, BookingEntryState>(
      BookingEntryController.new,
    );
