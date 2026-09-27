import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_scenario.dart';
import '../../movie/data/models/catalog_enums.dart';
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

abstract final class BookingTicketPolicy {
  static const maxTickets = 8;
  static const supportedTypes = [
    TicketType.adult,
    TicketType.student,
    TicketType.child,
  ];

  static int defaultViewerAge(TicketType type) => switch (type) {
    TicketType.child => 10,
    TicketType.student => 20,
    _ => 30,
  };
}

class SeatTicketAssignment {
  const SeatTicketAssignment({required this.seatId, required this.ticketType});
  final int seatId;
  final TicketType ticketType;
}

class BookingEntryState {
  const BookingEntryState({
    required this.phase,
    this.movieId,
    this.showtimeId,
    this.ticketQuantities = const {},
    this.activeTicketType,
    this.assignments = const {},
    this.unavailableSeatIds = const {},
    this.booking,
    this.message,
  });

  const BookingEntryState.idle() : this(phase: BookingEntryPhase.idle);

  final BookingEntryPhase phase;
  final int? movieId;
  final int? showtimeId;
  final Map<TicketType, int> ticketQuantities;
  final TicketType? activeTicketType;
  final Map<int, SeatTicketAssignment> assignments;
  final Set<int> unavailableSeatIds;
  final BookingDto? booking;
  final String? message;

  Set<int> get selectedSeatIds => assignments.keys.toSet();
  int get ticketCount => ticketQuantities.values.fold(0, (a, b) => a + b);
  int get assignedCount => assignments.length;
  bool get assignmentComplete =>
      ticketCount > 0 && ticketCount == assignedCount;
  int quantityFor(TicketType type) => ticketQuantities[type] ?? 0;
  int assignedFor(TicketType type) =>
      assignments.values.where((item) => item.ticketType == type).length;
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

  bool setTicketQuantity(
    TicketType type,
    int quantity, {
    bool removeExcessAssignments = false,
  }) {
    if (state.phase != BookingEntryPhase.selectingSeats ||
        !BookingTicketPolicy.supportedTypes.contains(type)) {
      return false;
    }
    final nextQuantity = quantity.clamp(0, BookingTicketPolicy.maxTickets);
    final totalWithoutType = state.ticketCount - state.quantityFor(type);
    if (totalWithoutType + nextQuantity > BookingTicketPolicy.maxTickets) {
      state = _copy(message: 'Mỗi giao dịch chỉ được đặt tối đa 8 vé.');
      return false;
    }
    final assigned = state.assignments.values
        .where((item) => item.ticketType == type)
        .toList(growable: false);
    if (assigned.length > nextQuantity && !removeExcessAssignments) {
      return false;
    }
    final nextAssignments = Map<int, SeatTicketAssignment>.from(
      state.assignments,
    );
    if (assigned.length > nextQuantity) {
      for (final item in assigned.skip(nextQuantity)) {
        nextAssignments.remove(item.seatId);
      }
    }
    final quantities = Map<TicketType, int>.from(state.ticketQuantities);
    if (nextQuantity == 0) {
      quantities.remove(type);
    } else {
      quantities[type] = nextQuantity;
    }
    final TicketType? active = nextQuantity > 0
        ? type
        : (quantities.isEmpty ? null : quantities.keys.first);
    state = _copy(
      ticketQuantities: quantities,
      assignments: nextAssignments,
      activeTicketType: active,
      clearActiveTicketType: active == null,
      clearMessage: true,
    );
    return true;
  }

  void setActiveTicketType(TicketType type) {
    if (state.quantityFor(type) == 0 ||
        state.phase != BookingEntryPhase.selectingSeats) {
      return;
    }
    state = _copy(activeTicketType: type, clearMessage: true);
  }

  void toggleSeatIds(Set<int> seatIds) {
    if (state.phase != BookingEntryPhase.selectingSeats) return;
    final next = Map<int, SeatTicketAssignment>.from(state.assignments);
    if (seatIds.every(next.containsKey)) {
      for (final id in seatIds) {
        next.remove(id);
      }
      state = _copy(assignments: next, clearMessage: true);
      return;
    }
    final type = state.activeTicketType;
    if (type == null) {
      state = _copy(
        message: 'Hãy chọn số lượng và loại vé trước khi chọn ghế.',
      );
      return;
    }
    final newIds = seatIds.where((id) => !next.containsKey(id)).toList();
    final remaining = state.quantityFor(type) - state.assignedFor(type);
    if (newIds.length > remaining) {
      state = _copy(
        message: 'Loại vé đang chọn chỉ còn $remaining ghế cần gán.',
      );
      return;
    }
    for (final id in newIds) {
      next[id] = SeatTicketAssignment(seatId: id, ticketType: type);
    }
    state = _copy(assignments: next, clearMessage: true);
  }

  Future<BookingDto?> holdSelectedSeats() async {
    final showtimeId = state.showtimeId;
    if (showtimeId == null || !state.assignmentComplete) {
      state = _copy(
        message: 'Hãy gán đủ ghế cho tất cả vé trước khi tiếp tục.',
      );
      return null;
    }
    state = _copy(phase: BookingEntryPhase.submittingHold, clearMessage: true);
    try {
      final tickets = state.assignments.values
          .map(
            (assignment) => TicketSelectionDto(
              seatId: assignment.seatId,
              ticketType: assignment.ticketType,
              viewerAge: BookingTicketPolicy.defaultViewerAge(
                assignment.ticketType,
              ),
            ),
          )
          .toList(growable: false);
      final booking = await ref
          .read(bookingRepositoryProvider)
          .holdSeats(
            DemoIds.user,
            HoldSeatsRequestDto(
              showtimeId: showtimeId,
              seatIds: state.selectedSeatIds.toList(growable: false),
              tickets: tickets,
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
        assignments: const {},
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
        /* Already expired. */
      }
    }
    state = const BookingEntryState.idle();
  }

  Future<bool> editHeldSelection() async {
    final booking = state.booking;
    if (booking == null || !state.hasActiveHold) return true;
    try {
      await ref.read(bookingRepositoryProvider).cancel(booking.id);
      state = _copy(
        phase: BookingEntryPhase.selectingSeats,
        clearBooking: true,
        clearMessage: true,
      );
      return true;
    } on BookingConflictException catch (error) {
      state = _copy(message: error.message);
      return false;
    }
  }

  void restartSelection() {
    state = BookingEntryState(
      phase: BookingEntryPhase.selectingSeats,
      movieId: state.movieId,
      showtimeId: state.showtimeId,
      ticketQuantities: state.ticketQuantities,
      activeTicketType: state.activeTicketType,
    );
  }

  BookingEntryState _copy({
    BookingEntryPhase? phase,
    Map<TicketType, int>? ticketQuantities,
    TicketType? activeTicketType,
    bool clearActiveTicketType = false,
    Map<int, SeatTicketAssignment>? assignments,
    Set<int>? unavailableSeatIds,
    BookingDto? booking,
    bool clearBooking = false,
    String? message,
    bool clearMessage = false,
  }) => BookingEntryState(
    phase: phase ?? state.phase,
    movieId: state.movieId,
    showtimeId: state.showtimeId,
    ticketQuantities: ticketQuantities ?? state.ticketQuantities,
    activeTicketType: clearActiveTicketType
        ? null
        : activeTicketType ?? state.activeTicketType,
    assignments: assignments ?? state.assignments,
    unavailableSeatIds: unavailableSeatIds ?? state.unavailableSeatIds,
    booking: clearBooking ? null : booking ?? state.booking,
    message: clearMessage ? null : message ?? state.message,
  );
}

final bookingEntryProvider =
    NotifierProvider<BookingEntryController, BookingEntryState>(
      BookingEntryController.new,
    );
