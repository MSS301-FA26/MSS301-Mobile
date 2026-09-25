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
    final total = selectedSeats.fold(
      VndMoney.zero,
      (value, seat) => value + (seat.unitPrice ?? VndMoney.zero),
    );
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
                    const SizedBox(height: AppSpacing.lg),
                    const _ScreenIndicator(),
                    const SizedBox(height: AppSpacing.lg),
                    InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 2.2,
                      boundaryMargin: const EdgeInsets.all(24),
                      child: _SeatGrid(
                        seatMap: seatMap,
                        selectedSeatIds: session.selectedSeatIds,
                        unavailableSeatIds: session.unavailableSeatIds,
                        enabled: !holding && !submitting,
                        onSeat: (seat) => ref
                            .read(bookingEntryProvider.notifier)
                            .toggleSeatIds(_seatGroup(seat, seatMap.seats)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _SeatLegend(),
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
              onContinue:
                  session.selectedSeatIds.isEmpty || holding || submitting
                  ? null
                  : () async {
                      final booking = await ref
                          .read(bookingEntryProvider.notifier)
                          .holdSelectedSeats();
                      if (booking == null || !mounted) return;
                      _startTimer();
                    },
            ),
          ],
        ),
      ),
    );
  }
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
        color: AppColors.surface,
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
                style: const TextStyle(
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
        height: 6,
        margin: const EdgeInsets.symmetric(horizontal: 36),
        decoration: BoxDecoration(
          color: AppColors.textMuted,
          borderRadius: BorderRadius.circular(999),
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
    required this.selectedSeatIds,
    required this.unavailableSeatIds,
    required this.enabled,
    required this.onSeat,
  });

  final ShowtimeSeatMapDto seatMap;
  final Set<int> selectedSeatIds;
  final Set<int> unavailableSeatIds;
  final bool enabled;
  final ValueChanged<ShowtimeSeatDto> onSeat;

  @override
  Widget build(BuildContext context) {
    final rows = <String, List<ShowtimeSeatDto>>{};
    for (final seat in seatMap.seats) {
      rows.putIfAbsent(seat.rowLabel, () => []).add(seat);
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
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _SeatButton(
                      seat: seat,
                      selected: selectedSeatIds.contains(seat.seatId),
                      forcedUnavailable: unavailableSeatIds.contains(
                        seat.seatId,
                      ),
                      enabled: enabled,
                      onTap: () => onSeat(seat),
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
    required this.selected,
    required this.forcedUnavailable,
    required this.enabled,
    required this.onTap,
  });

  final ShowtimeSeatDto seat;
  final bool selected;
  final bool forcedUnavailable;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final available = seat.selectable && !forcedUnavailable;
    final color = selected
        ? AppColors.gold
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
          width: seat.seatType.normalized == CatalogSeatType.couple ? 52 : 38,
          height: 38,
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
            style: TextStyle(
              color: selected ? Colors.black : AppColors.text,
              fontSize: 11,
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
    spacing: 12,
    runSpacing: 8,
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
        color: AppColors.surface,
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
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 18,
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
                  ? 'Đã giữ ghế • R5'
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
