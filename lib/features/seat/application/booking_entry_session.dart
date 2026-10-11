import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/application/auth_session.dart';
import '../../booking/application/booking_checkpoint.dart';
import '../../movie/data/models/catalog_enums.dart';
import '../../movie/data/repositories/catalog_providers.dart';
import '../../orders/data/models/booking_dto.dart';
import '../../orders/data/models/booking_enums.dart';
import '../../showtime/data/models/showtime_dto.dart';
import '../data/repositories/seat_hold_providers.dart';
import '../presentation/providers/seat_map_provider.dart';

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

  static int minimumMovieAge(String? rating) =>
      switch (rating?.trim().toUpperCase().replaceAll(' ', '')) {
        'T13' || '13+' => 13,
        'T16' || '16+' => 16,
        'T18' || '18+' => 18,
        _ => 0,
      };

  static String? restriction(TicketType type, String? rating) {
    final minimum = minimumMovieAge(rating);
    if (type == TicketType.child && minimum > 12) {
      return 'Phim dành cho người từ $minimum tuổi. Vé trẻ em chỉ áp dụng cho người từ 0–12 tuổi nên không thể mua cho phim này.';
    }
    return null;
  }

  static int defaultViewerAge(TicketType type) => switch (type) {
    TicketType.child => 10,
    TicketType.student => 20,
    _ => 30,
  };
}

class SeatTicketAssignment {
  const SeatTicketAssignment({
    required this.seatId,
    required this.ticketType,
    this.viewerAge,
  });
  final int seatId;
  final TicketType ticketType;
  final int? viewerAge;
}

class BookingEntryState {
  const BookingEntryState({
    required this.phase,
    this.movieId,
    this.movieAgeRating,
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
  final String? movieAgeRating;
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
  BookingEntryState build() {
    _generation++;
    ref.watch(authSessionProvider.select((auth) => auth.session?.user.id));
    return const BookingEntryState.idle();
  }

  bool _leaving = false;
  int _generation = 0;

  void restoreBooking(
    BookingDto booking, {
    Map<int, int> viewerAges = const {},
  }) {
    final quantities = <TicketType, int>{};
    for (final ticket in booking.tickets) {
      quantities.update(
        ticket.ticketType,
        (value) => value + ticket.quantity,
        ifAbsent: () => ticket.quantity,
      );
    }
    state = BookingEntryState(
      phase: BookingEntryPhase.holding,
      movieId: booking.movieId,
      movieAgeRating: state.showtimeId == booking.showtimeId
          ? state.movieAgeRating
          : null,
      showtimeId: booking.showtimeId,
      booking: booking,
      ticketQuantities: quantities,
      activeTicketType: quantities.keys.firstOrNull,
      assignments: {
        for (final ticket in booking.tickets)
          ticket.seatId: SeatTicketAssignment(
            seatId: ticket.seatId,
            ticketType: ticket.ticketType,
            viewerAge:
                viewerAges[ticket.seatId] ??
                BookingTicketPolicy.defaultViewerAge(ticket.ticketType),
          ),
      },
    );
  }

  void begin({
    required int movieId,
    required int showtimeId,
    String? movieAgeRating,
  }) {
    if (state.showtimeId == showtimeId && state.hasActiveDraft) {
      if (movieAgeRating != null) state = _copy(movieAgeRating: movieAgeRating);
      return;
    }
    state = BookingEntryState(
      phase: BookingEntryPhase.selectingSeats,
      movieId: movieId,
      movieAgeRating: movieAgeRating,
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
    final restriction = BookingTicketPolicy.restriction(
      type,
      state.movieAgeRating,
    );
    if (quantity > 0 && restriction != null) {
      state = _copy(message: restriction);
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
      next[id] = SeatTicketAssignment(
        seatId: id,
        ticketType: type,
        viewerAge: BookingTicketPolicy.defaultViewerAge(type),
      );
    }
    state = _copy(assignments: next, clearMessage: true);
  }

  Future<BookingDto?> holdSelectedSeats() async {
    final generation = _generation;
    if (state.phase == BookingEntryPhase.expired) return null;
    if (state.hasActiveHold) {
      if (remainingHold() == Duration.zero) {
        state = _copy(
          phase: BookingEntryPhase.expired,
          message: 'Thời gian giữ ghế đã hết.',
        );
        return null;
      }
      return state.booking;
    }
    if (state.phase == BookingEntryPhase.submittingHold) return null;
    final showtimeId = state.showtimeId;
    if (showtimeId == null || !state.assignmentComplete) {
      state = _copy(
        message: 'Hãy gán đủ ghế cho tất cả vé trước khi tiếp tục.',
      );
      return null;
    }
    final mock = ref.read(seatHoldRepositoryProvider).canEnterMockCheckout;
    state = _copy(phase: BookingEntryPhase.submittingHold, clearMessage: true);
    try {
      final tickets = state.assignments.values
          .map(
            (assignment) => TicketSelectionDto(
              seatId: assignment.seatId,
              ticketType: assignment.ticketType,
              viewerAge:
                  assignment.viewerAge ??
                  BookingTicketPolicy.defaultViewerAge(assignment.ticketType),
            ),
          )
          .toList(growable: false);
      final booking = await ref
          .read(seatHoldRepositoryProvider)
          .hold(
            HoldSeatsRequestDto(
              showtimeId: showtimeId,
              seatIds: state.selectedSeatIds.toList(growable: false),
              tickets: tickets,
            ),
          );
      if (!ref.mounted || generation != _generation) return null;
      state = _copy(phase: BookingEntryPhase.holding, booking: booking);
      final userId = ref.read(authSessionProvider).session?.user.id;
      if (userId != null && !mock) {
        await ref
            .read(bookingCheckpointStoreProvider)
            .save(
              userId,
              BookingCheckpoint(
                bookingId: booking.id,
                viewerAges: {
                  for (final ticket in tickets)
                    if (ticket.viewerAge != null)
                      ticket.seatId: ticket.viewerAge!,
                },
              ),
            );
        ref.invalidate(resumableBookingProvider);
      }
      return booking;
    } on ApiException catch (error) {
      if (!ref.mounted || generation != _generation) return null;
      ShowtimeSeatMapDto? freshMap;
      if (error.type == ApiErrorType.conflict) {
        try {
          freshMap = await ref.refresh(seatMapProvider(showtimeId).future);
        } catch (_) {
          // Report the original hold failure when refreshing is also offline.
        }
      }
      if (!ref.mounted || generation != _generation) return null;
      final availableIds = freshMap?.seats
          .where((seat) => seat.selectable)
          .map((seat) => seat.seatId)
          .toSet();
      final assignments = availableIds == null
          ? state.assignments
          : Map<int, SeatTicketAssignment>.fromEntries(
              state.assignments.entries.where(
                (entry) => availableIds.contains(entry.key),
              ),
            );
      state = _copy(
        phase: BookingEntryPhase.selectingSeats,
        unavailableSeatIds: availableIds == null
            ? state.unavailableSeatIds
            : {
                ...state.unavailableSeatIds,
                ...state.selectedSeatIds.where(
                  (id) => !availableIds.contains(id),
                ),
              },
        assignments: assignments,
        message: error.type == ApiErrorType.conflict
            ? 'Ghế đã thay đổi trạng thái. Hãy chọn lại ghế còn trống.'
            : error.message,
      );
      return null;
    } catch (error) {
      if (!ref.mounted || generation != _generation) return null;
      state = _copy(
        phase: BookingEntryPhase.selectingSeats,
        message: error.toString(),
      );
      return null;
    }
  }

  Future<bool> refreshExpiry() async {
    final booking = state.booking;
    if (booking == null || !state.hasActiveHold) return false;
    if (remainingHold() == Duration.zero) {
      state = _copy(
        phase: BookingEntryPhase.expired,
        message: 'Thời gian giữ ghế đã hết.',
      );
      return true;
    }
    final refreshed = await ref
        .read(seatHoldRepositoryProvider)
        .getBooking(booking.id);
    if (refreshed.status != BookingStatus.expired) return false;
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

  Future<bool> abandon() async {
    final generation = _generation;
    final userId = ref.read(authSessionProvider).session?.user.id;
    if (_leaving || state.phase == BookingEntryPhase.submittingHold) {
      return false;
    }
    _leaving = true;
    try {
      final booking = state.booking;
      if (booking != null && state.hasActiveHold) {
        try {
          await ref.read(seatHoldRepositoryProvider).cancel(booking.id);
          if (!ref.mounted || generation != _generation) return false;
        } catch (error) {
          state = _copy(
            message: error is ApiException ? error.message : error.toString(),
          );
          return false;
        }
      }
      state = const BookingEntryState.idle();
      if (userId != null) {
        await ref.read(bookingCheckpointStoreProvider).clear(userId);
      }
      ref.invalidate(resumableBookingProvider);
      return true;
    } finally {
      _leaving = false;
    }
  }

  Future<bool> editHeldSelection() async {
    final booking = state.booking;
    if (booking == null || !state.hasActiveHold) return true;
    try {
      await ref.read(seatHoldRepositoryProvider).cancel(booking.id);
      state = _copy(
        phase: BookingEntryPhase.selectingSeats,
        clearBooking: true,
        clearMessage: true,
      );
      return true;
    } on ApiException catch (error) {
      state = _copy(message: error.message);
      return false;
    }
  }

  void restartSelection() {
    state = BookingEntryState(
      phase: BookingEntryPhase.selectingSeats,
      movieId: state.movieId,
      movieAgeRating: state.movieAgeRating,
      showtimeId: state.showtimeId,
      ticketQuantities: state.ticketQuantities,
      activeTicketType: state.activeTicketType,
    );
  }

  BookingEntryState _copy({
    String? movieAgeRating,
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
    movieAgeRating: movieAgeRating ?? state.movieAgeRating,
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
