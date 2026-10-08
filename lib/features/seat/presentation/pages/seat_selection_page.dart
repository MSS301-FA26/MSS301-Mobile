import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/money/vnd_money.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
import '../../../movie/data/models/catalog_enums.dart';
import '../../../showtime/data/models/showtime_dto.dart';
import '../../../booking/presentation/widgets/booking_progress.dart';
import '../../application/booking_entry_session.dart';
import '../providers/seat_map_provider.dart';

class SeatSelectionPage extends ConsumerStatefulWidget {
  const SeatSelectionPage({super.key, required this.showtimeId});

  final int showtimeId;

  @override
  ConsumerState<SeatSelectionPage> createState() => _SeatSelectionPageState();
}

class _SeatSelectionPageState extends ConsumerState<SeatSelectionPage> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _expiryDialogOpen = false;
  bool _initialized = false;

  Future<void> _changeTicket(TicketType type, int next) async {
    final controller = ref.read(bookingEntryProvider.notifier);
    if (controller.setTicketQuantity(type, next)) return;
    final session = ref.read(bookingEntryProvider);
    if (next >= session.assignedFor(type)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bỏ ghế đã gán?'),
        content: const Text(
          'Giảm số lượng vé sẽ bỏ các ghế vượt quá của loại vé này.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Có, giảm vé'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      controller.setTicketQuantity(type, next, removeExcessAssignments: true);
    }
  }

  Future<void> _editHold() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sửa vé và ghế?'),
        content: const Text(
          'Phiên giữ ghế hiện tại sẽ được hủy. Các lựa chọn được giữ lại để bạn chỉnh sửa và tạo phiên giữ mới.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          OutlinedButton(
            key: const ValueKey('confirm-edit-held-seats'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Có, sửa lựa chọn'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final edited = await ref
        .read(bookingEntryProvider.notifier)
        .editHeldSelection();
    if (edited) _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      _updateRemaining();
      final expired = await ref
          .read(bookingEntryProvider.notifier)
          .refreshExpiry();
      if (expired && mounted) await _showExpiredDialog();
    });
  }

  void _updateRemaining() {
    final remaining = ref.read(bookingEntryProvider.notifier).remainingHold();
    if (mounted) setState(() => _remaining = remaining);
  }

  Future<void> _showExpiredDialog() async {
    if (_expiryDialogOpen) return;
    _expiryDialogOpen = true;
    _timer?.cancel();
    final retry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Đã hết thời gian giữ ghế'),
        content: const Text(
          'Ghế đã được giải phóng. Bạn có thể chọn lại hoặc quay về lịch chiếu.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Về lịch chiếu'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Chọn lại'),
          ),
        ],
      ),
    );
    _expiryDialogOpen = false;
    if (!mounted) return;
    if (retry == true) {
      ref.read(bookingEntryProvider.notifier).restartSelection();
    } else {
      await ref.read(bookingEntryProvider.notifier).abandon();
      if (mounted) context.go(AppRoutes.showtimes);
    }
  }

  Future<void> _handleBack() async {
    final session = ref.read(bookingEntryProvider);
    if (!session.hasActiveDraft ||
        (session.selectedSeatIds.isEmpty && !session.hasActiveHold)) {
      await ref.read(bookingEntryProvider.notifier).abandon();
      if (mounted) {
        context.go(AppRoutes.showtimesForMovie(session.movieId ?? 1));
      }
      return;
    }
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dừng chọn ghế?'),
        content: Text(
          session.hasActiveHold
              ? 'Ghế đang được giữ sẽ được giải phóng nếu bạn rời màn hình.'
              : 'Các ghế đang chọn sẽ không được lưu.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Rời đi'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Ở lại'),
          ),
        ],
      ),
    );
    if (shouldLeave != true || !mounted) return;
    final movieId = session.movieId;
    await ref.read(bookingEntryProvider.notifier).abandon();
    if (mounted) {
      context.go(
        movieId == null
            ? AppRoutes.showtimes
            : AppRoutes.showtimesForMovie(movieId),
      );
    }
  }

  Set<int> _seatGroup(ShowtimeSeatDto seat, List<ShowtimeSeatDto> allSeats) {
    if (seat.seatType.normalized != CatalogSeatType.couple) {
      return {seat.seatId};
    }
    return allSeats
        .where(
          (item) =>
              item.rowLabel == seat.rowLabel &&
              item.seatType.normalized == CatalogSeatType.couple,
        )
        .map((item) => item.seatId)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(bookingEntryProvider, (previous, next) {
      if (previous?.phase != BookingEntryPhase.holding &&
          next.phase == BookingEntryPhase.holding) {
        _startTimer();
      }
    });
    final seatMapState = ref.watch(seatMapProvider(widget.showtimeId));
    final session = ref.watch(bookingEntryProvider);
    if (seatMapState.isLoading) {
      return const AppShell(
        currentIndex: 2,
        showBottomNavigation: false,
        body: RepositoryStatePane.loading(),
      );
    }
    if (seatMapState.hasError) {
      return AppShell(
        currentIndex: 2,
        showBottomNavigation: false,
        body: RepositoryStatePane.error(
          onRetry: () => ref.invalidate(seatMapProvider(widget.showtimeId)),
        ),
      );
    }
    final seatMap = seatMapState.requireValue;
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(bookingEntryProvider.notifier)
            .begin(
              movieId: seatMap.showtime.movieId,
              showtimeId: widget.showtimeId,
            );
      });
    }

    final selectedSeats = seatMap.seats
        .where((seat) => session.selectedSeatIds.contains(seat.seatId))
        .toList(growable: false);
    final total = selectedSeats.fold(VndMoney.zero, (value, seat) {
      final type =
          session.assignments[seat.seatId]?.ticketType ?? TicketType.adult;
      return value + _ticketPrice(seatMap.showtime, seat, type);
    });
    final holding = session.phase == BookingEntryPhase.holding;
    final submitting = session.phase == BookingEntryPhase.submittingHold;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: AppShell(
        currentIndex: 2,
        showBottomNavigation: false,
        body: Column(
          children: [
            const BookingProgress(currentStep: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShowtimeSummary(
                      seatMap: seatMap,
                      remaining: holding ? _remaining : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _TicketSelector(
                      session: session,
                      onChange: _changeTicket,
                      onActivate: (type) => ref
                          .read(bookingEntryProvider.notifier)
                          .setActiveTicketType(type),
                    ),
                    if (holding) ...[
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        key: const ValueKey('edit-held-seats'),
                        onPressed: _editHold,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Sửa số lượng vé hoặc ghế'),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    const _ScreenIndicator(),
                    const SizedBox(height: AppSpacing.lg),
                    InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 2.2,
                      boundaryMargin: const EdgeInsets.all(24),
                      child: _SeatGrid(
                        seatMap: seatMap,
                        assignments: session.assignments,
                        unavailableSeatIds: session.unavailableSeatIds,
                        enabled: !holding && !submitting,
                        onSeat: (seat) => ref
                            .read(bookingEntryProvider.notifier)
                            .toggleSeatIds(_seatGroup(seat, seatMap.seats)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _SeatLegend(),
                    if (session.assignments.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      _AssignmentSummary(
                        assignments: session.assignments,
                        seats: seatMap.seats,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Loại vé: Người lớn • Vui lòng kiểm tra phân loại độ tuổi của phim.',
                      style: AppTextStyles.caption,
                    ),
                    if (session.message != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        session.message!,
                        key: const ValueKey('booking-entry-message'),
                        style: const TextStyle(color: AppColors.adultBadge),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _SeatActionBar(
              selectedSeats: selectedSeats,
              total: total,
              holding: holding,
              submitting: submitting,
              onContinue: submitting || !session.assignmentComplete
                  ? null
                  : () async {
                      if (holding && session.booking != null) {
                        context.go(AppRoutes.concessions(session.booking!.id));
                        return;
                      }
                      final booking = await ref
                          .read(bookingEntryProvider.notifier)
                          .holdSelectedSeats();
                      if (booking == null || !context.mounted) return;
                      _startTimer();
                      context.go(AppRoutes.concessions(booking.id));
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketSelector extends StatelessWidget {
  const _TicketSelector({
    required this.session,
    required this.onChange,
    required this.onActivate,
  });

  final BookingEntryState session;
  final Future<void> Function(TicketType type, int quantity) onChange;
  final ValueChanged<TicketType> onActivate;

  @override
  Widget build(BuildContext context) {
    final editable = session.phase == BookingEntryPhase.selectingSeats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '1. CHỌN SỐ LƯỢNG VÉ',
                style: AppTextStyles.cardTitle,
              ),
            ),
            Text(
              '${session.ticketCount}/${BookingTicketPolicy.maxTickets} vé',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final type in BookingTicketPolicy.supportedTypes)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: InkWell(
              key: ValueKey('ticket-type-${type.wireValue.toLowerCase()}'),
              onTap: editable && session.quantityFor(type) > 0
                  ? () => onActivate(type)
                  : null,
              borderRadius: AppRadii.control,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: session.activeTicketType == type
                      ? _ticketColor(type).withValues(alpha: 0.14)
                      : AppColors.surface,
                  borderRadius: AppRadii.control,
                  border: Border.all(
                    color: session.activeTicketType == type
                        ? _ticketColor(type)
                        : AppColors.border,
                    width: session.activeTicketType == type ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _ticketColor(type),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _ticketLabel(type),
                            style: AppTextStyles.cardTitle,
                          ),
                          Text(
                            'Đã gán ${session.assignedFor(type)}/${session.quantityFor(type)} ghế',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: ValueKey(
                        'ticket-minus-${type.wireValue.toLowerCase()}',
                      ),
                      onPressed: !editable || session.quantityFor(type) == 0
                          ? null
                          : () => onChange(type, session.quantityFor(type) - 1),
                      icon: const Icon(Icons.remove_rounded),
                    ),
                    Text(
                      '${session.quantityFor(type)}',
                      style: AppTextStyles.sectionTitle,
                    ),
                    IconButton(
                      key: ValueKey(
                        'ticket-plus-${type.wireValue.toLowerCase()}',
                      ),
                      onPressed:
                          !editable ||
                              session.ticketCount >=
                                  BookingTicketPolicy.maxTickets
                          ? null
                          : () => onChange(type, session.quantityFor(type) + 1),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (session.activeTicketType != null)
          Text(
            'Đang gán ghế cho: ${_ticketLabel(session.activeTicketType!)}',
            style: TextStyle(
              color: _ticketColor(session.activeTicketType!),
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
  }
}

class _AssignmentSummary extends StatelessWidget {
  const _AssignmentSummary({required this.assignments, required this.seats});

  final Map<int, SeatTicketAssignment> assignments;
  final List<ShowtimeSeatDto> seats;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surfaceRaised,
      borderRadius: AppRadii.card,
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '2. GHẾ ĐÃ GÁN THEO LOẠI VÉ',
          style: AppTextStyles.cardTitle,
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final type in BookingTicketPolicy.supportedTypes)
          if (assignments.values.any((item) => item.ticketType == type))
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${_ticketLabel(type)}: ${assignments.values.where((item) => item.ticketType == type).map((item) {
                  final seat = seats.firstWhere((seat) => seat.seatId == item.seatId);
                  return '${seat.rowLabel}${seat.seatNumber}';
                }).join(', ')}',
                style: TextStyle(
                  color: _ticketColor(type),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
      ],
    ),
  );
}

class _ShowtimeSummary extends StatelessWidget {
  const _ShowtimeSummary({required this.seatMap, required this.remaining});

  final ShowtimeSeatMapDto seatMap;
  final Duration? remaining;

  @override
  Widget build(BuildContext context) {
    final showtime = seatMap.showtime;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showtime.movieTitle ?? 'Chọn ghế',
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: 4),
                Text(
                  '${showtime.cinemaName} • ${showtime.roomName} • ${_dateTime(showtime.startTime)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          if (remaining != null)
            Container(
              key: const ValueKey('seat-hold-timer'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.goldSurface,
                borderRadius: AppRadii.control,
                border: Border.all(color: AppColors.goldBorder),
              ),
              child: Text(
                '${remaining!.inMinutes.toString().padLeft(2, '0')}:${(remaining!.inSeconds % 60).toString().padLeft(2, '0')}',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScreenIndicator extends StatelessWidget {
  const _ScreenIndicator();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.gold, AppColors.textMuted],
          ),
          borderRadius: AppRadii.control,
          boxShadow: const [BoxShadow(color: AppColors.gold, blurRadius: 12)],
        ),
      ),
      const SizedBox(height: 6),
      const Text('MÀN CHIẾU', style: AppTextStyles.caption),
    ],
  );
}

class _SeatGrid extends StatelessWidget {
  const _SeatGrid({
    required this.seatMap,
    required this.assignments,
    required this.unavailableSeatIds,
    required this.enabled,
    required this.onSeat,
  });

  final ShowtimeSeatMapDto seatMap;
  final Map<int, SeatTicketAssignment> assignments;
  final Set<int> unavailableSeatIds;
  final bool enabled;
  final ValueChanged<ShowtimeSeatDto> onSeat;

  @override
  Widget build(BuildContext context) {
    final rows = <String, List<ShowtimeSeatDto>>{};
    for (final seat in seatMap.seats) {
      rows.putIfAbsent(seat.rowLabel, () => []).add(seat);
    }
    for (final row in rows.values) {
      row.sort((a, b) => a.displayColumn.compareTo(b.displayColumn));
    }
    return Column(
      children: [
        for (final row in rows.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  child: Text(row.key, style: AppTextStyles.caption),
                ),
                for (final seat in row.value)
                  Padding(
                    padding: EdgeInsets.only(
                      left:
                          seat.displayColumn > 1 &&
                              !row.value.any(
                                (other) =>
                                    other.displayColumn ==
                                    seat.displayColumn - 1,
                              )
                          ? 18
                          : 3,
                      right: 3,
                    ),
                    child: _SeatButton(
                      seat: seat,
                      assignment: assignments[seat.seatId],
                      forcedUnavailable: unavailableSeatIds.contains(
                        seat.seatId,
                      ),
                      enabled: enabled,
                      onTap: () => onSeat(seat),
                    ),
                  ),
                SizedBox(
                  width: 24,
                  child: Text(
                    row.key,
                    textAlign: TextAlign.end,
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SeatButton extends StatelessWidget {
  const _SeatButton({
    required this.seat,
    required this.assignment,
    required this.forcedUnavailable,
    required this.enabled,
    required this.onTap,
  });

  final ShowtimeSeatDto seat;
  final SeatTicketAssignment? assignment;
  final bool forcedUnavailable;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = assignment != null;
    final available = seat.selectable && !forcedUnavailable;
    final color = selected
        ? _ticketColor(assignment!.ticketType)
        : !available
        ? AppColors.border
        : switch (seat.seatType.normalized) {
            CatalogSeatType.vip => AppColors.purple,
            CatalogSeatType.couple => AppColors.adultBadge,
            _ => AppColors.surfaceRaised,
          };
    final label = '${seat.rowLabel}${seat.seatNumber}';
    return Semantics(
      button: true,
      enabled: available && enabled,
      selected: selected,
      label:
          'Ghế $label, ${seat.seatType.normalized.wireValue}, ${available ? 'có thể chọn' : 'không khả dụng'}',
      child: InkWell(
        key: ValueKey('seat-${seat.seatId}'),
        onTap: available && enabled ? onTap : null,
        borderRadius: AppRadii.small,
        child: Container(
          width: seat.seatType.normalized == CatalogSeatType.couple ? 48 : 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppRadii.small,
            border: Border.all(
              color: selected ? AppColors.text : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.meta.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _SeatLegend extends StatelessWidget {
  const _SeatLegend();

  @override
  Widget build(BuildContext context) => const Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.xs,
    children: [
      _LegendItem(label: 'Thường', color: AppColors.surfaceRaised),
      _LegendItem(label: 'VIP', color: AppColors.purple),
      _LegendItem(label: 'Ghế đôi', color: AppColors.adultBadge),
      _LegendItem(label: 'Đang chọn', color: AppColors.gold),
      _LegendItem(label: 'Đã giữ/đặt/bảo trì', color: AppColors.border),
    ],
  );
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          borderRadius: AppRadii.small,
          border: Border.all(color: AppColors.textMuted),
        ),
      ),
      const SizedBox(width: 4),
      Text(label, style: AppTextStyles.caption),
    ],
  );
}

class _SeatActionBar extends StatelessWidget {
  const _SeatActionBar({
    required this.selectedSeats,
    required this.total,
    required this.holding,
    required this.submitting,
    required this.onContinue,
  });

  final List<ShowtimeSeatDto> selectedSeats;
  final VndMoney total;
  final bool holding;
  final bool submitting;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedSeats.isEmpty
                      ? 'Chưa chọn ghế'
                      : selectedSeats
                            .map((seat) => '${seat.rowLabel}${seat.seatNumber}')
                            .join(', '),
                  style: AppTextStyles.caption,
                ),
                Text(
                  total.format(),
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 170,
            child: AppButton(
              key: const ValueKey('seat-continue'),
              label: holding
                  ? 'Tiếp tục • Bắp nước'
                  : submitting
                  ? 'Đang giữ ghế...'
                  : 'Tiếp tục',
              onPressed: onContinue,
            ),
          ),
        ],
      ),
    ),
  );
}

String _dateTime(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')} • '
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _ticketLabel(TicketType type) => switch (type) {
  TicketType.student => 'Sinh viên',
  TicketType.child => 'Trẻ em',
  _ => 'Người lớn',
};

Color _ticketColor(TicketType type) => switch (type) {
  TicketType.student => const Color(0xFF777BFF),
  TicketType.child => const Color(0xFF22C99A),
  _ => AppColors.gold,
};

VndMoney _ticketPrice(
  ShowtimeDto showtime,
  ShowtimeSeatDto seat,
  TicketType ticketType,
) {
  final value = switch ((ticketType, seat.seatType.normalized)) {
    (TicketType.adult, CatalogSeatType.standard) => showtime.adultStandardPrice,
    (TicketType.student, CatalogSeatType.standard) =>
      showtime.studentStandardPrice,
    (TicketType.child, CatalogSeatType.standard) => showtime.childStandardPrice,
    (TicketType.adult, CatalogSeatType.vip) => showtime.adultVipPrice,
    (TicketType.student, CatalogSeatType.vip) => showtime.studentVipPrice,
    (TicketType.child, CatalogSeatType.vip) => showtime.childVipPrice,
    (TicketType.adult, CatalogSeatType.couple) => showtime.adultCouplePrice,
    (TicketType.student, CatalogSeatType.couple) => showtime.studentCouplePrice,
    (TicketType.child, CatalogSeatType.couple) => showtime.childCouplePrice,
    _ => null,
  };
  return value ?? seat.unitPrice ?? VndMoney.zero;
}
