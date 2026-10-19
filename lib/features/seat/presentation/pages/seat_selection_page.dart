import '../../../../core/time/vietnam_time.dart';

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
import '../../../movie/data/repositories/catalog_providers.dart';
import '../../../auth/application/auth_session.dart';
import '../../../showtime/data/models/showtime_dto.dart';
import '../../../booking/presentation/widgets/booking_progress.dart';
import '../../../booking/presentation/widgets/booking_hold_countdown.dart';
import '../../application/booking_entry_session.dart';
import '../../application/seat_quote_provider.dart';
import '../../../booking/application/booking_completion_controller.dart';
import '../providers/seat_map_provider.dart';

class SeatSelectionPage extends ConsumerStatefulWidget {
  const SeatSelectionPage({super.key, required this.showtimeId});

  final int showtimeId;

  @override
  ConsumerState<SeatSelectionPage> createState() => _SeatSelectionPageState();
}

class _SeatSelectionPageState extends ConsumerState<SeatSelectionPage>
    with WidgetsBindingObserver {
  final TransformationController _seatTransformation =
      TransformationController();
  double _seatViewportWidth = 0;
  Timer? _timer;
  Timer? _seatRefreshTimer;
  Timer? _seatStaleTimer;
  ShowtimeSeatMapDto? _lastSeatMap;
  DateTime? _lastSeatMapAt;
  bool _refreshingSeats = false;
  bool _refreshAgain = false;
  bool _seatMapFailed = false;
  bool _initialRefreshStarted = false;
  bool _expiryCheckRunning = false;
  int _refreshGeneration = 0;
  static const _seatRefreshInterval = Duration(seconds: 8);
  static const _seatMapMaxAge = Duration(seconds: 20);
  bool _expiryDialogOpen = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _seatRefreshTimer = Timer.periodic(_seatRefreshInterval, (_) {
      if (mounted &&
          ModalRoute.of(context)?.isCurrent == true &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _refreshSeatMap();
      }
    });
  }

  @override
  void didUpdateWidget(covariant SeatSelectionPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showtimeId != widget.showtimeId) {
      _seatStaleTimer?.cancel();
      _refreshGeneration++;
      _lastSeatMap = null;
      _lastSeatMapAt = null;
      _refreshingSeats = false;
      _refreshAgain = false;
      _seatMapFailed = false;
      _initialRefreshStarted = false;
      _initialized = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        mounted &&
        ModalRoute.of(context)?.isCurrent == true) {
      _refreshSeatMap();
    } else if (mounted) {
      setState(() => _lastSeatMapAt = null);
    }
  }

  Future<void> _refreshSeatMap() async {
    if (!mounted) return;
    if (_refreshingSeats) {
      _refreshAgain = true;
      return;
    }
    final showtimeId = widget.showtimeId;
    final generation = ++_refreshGeneration;
    setState(() => _refreshingSeats = true);
    try {
      final map = await ref.refresh(seatMapProvider(showtimeId).future);
      if (!mounted ||
          generation != _refreshGeneration ||
          widget.showtimeId != showtimeId) {
        return;
      }
      if (map.showtime.id != showtimeId) {
        throw StateError('Seat map does not match showtime');
      }
      if (!_initialized) _beginForMap(map);
      ref.read(bookingEntryProvider.notifier).reconcileSeatMap(map);
      setState(() {
        _lastSeatMap = map;
        _lastSeatMapAt = ref.read(appClockProvider).now();
        _seatMapFailed = false;
      });
      _seatStaleTimer?.cancel();
      _seatStaleTimer = Timer(_seatMapMaxAge, () {
        if (mounted) setState(() {});
      });
    } catch (_) {
      if (!mounted || generation != _refreshGeneration) return;
      final firstFailure = !_seatMapFailed;
      setState(() => _seatMapFailed = true);
      if (firstFailure && _lastSeatMap != null) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: const Text(
              'Không tải được trạng thái ghế mới. Vui lòng thử lại.',
            ),
            action: SnackBarAction(
              label: 'Thử lại',
              onPressed: _refreshSeatMap,
            ),
          ),
        );
      }
    } finally {
      if (mounted && generation == _refreshGeneration) {
        setState(() => _refreshingSeats = false);
        if (_refreshAgain) {
          _refreshAgain = false;
          _refreshSeatMap();
        }
      }
    }
  }

  void _beginForMap(ShowtimeSeatMapDto map) {
    if (_initialized || map.showtime.id != widget.showtimeId) return;
    _initialized = true;
    ref
        .read(bookingEntryProvider.notifier)
        .begin(
          movieId: map.showtime.movieId,
          movieAgeRating: map.showtime.movieAgeRating,
          showtimeId: widget.showtimeId,
          couplePairs: {
            for (final seat in map.seats)
              if (seat.seatType.normalized == CatalogSeatType.couple)
                for (final partner in _seatGroup(seat, map.seats))
                  if (partner != seat.seatId) seat.seatId: partner,
          },
        );
  }

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
          'Giảm số lượng vé sẽ bỏ các ghế vượt quá của loại vé này. Nếu có ghế đôi, cả cặp ghế sẽ được bỏ.',
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
    if (edited && mounted) {
      _timer?.cancel();
      ref.invalidate(bookingCompletionProvider);
      setState(() => _lastSeatMapAt = null);
      await _refreshSeatMap();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _seatRefreshTimer?.cancel();
    _seatStaleTimer?.cancel();
    _refreshGeneration++;
    _timer?.cancel();
    _seatTransformation.dispose();
    super.dispose();
  }

  void _changeSeatZoom(double nextScale) {
    final current = _seatTransformation.value.getMaxScaleOnAxis();
    final target = nextScale.clamp(1.0, 2.5);
    if ((target - current).abs() < 0.01) return;
    final center = _seatViewportWidth / 2;
    final ratio = target / current;
    _seatTransformation.value = Matrix4.translationValues(center, 0, 0)
      ..multiply(Matrix4.diagonal3Values(ratio, ratio, 1))
      ..multiply(Matrix4.translationValues(-center, 0, 0))
      ..multiply(_seatTransformation.value);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted || _expiryCheckRunning) return;
      _expiryCheckRunning = true;
      try {
        final expired = await ref
            .read(bookingEntryProvider.notifier)
            .refreshExpiry();
        if (expired && mounted) await _showExpiredDialog();
      } catch (_) {
        // Retry on the next tick; local expiry still prevents submitting.
      } finally {
        _expiryCheckRunning = false;
      }
    });
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
          'Phiên giữ ghế đã hết. Hãy tải lại sơ đồ ghế trước khi chọn lại.',
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
      _refreshSeatMap();
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
    final left = await ref.read(bookingEntryProvider.notifier).abandon();
    if (!left) return;
    ref.invalidate(bookingCompletionProvider);
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
    final row =
        allSeats
            .where(
              (item) =>
                  item.rowLabel == seat.rowLabel &&
                  item.seatType.normalized == CatalogSeatType.couple,
            )
            .toList()
          ..sort((a, b) => a.seatNumber.compareTo(b.seatNumber));
    final index = row.indexWhere((item) => item.seatId == seat.seatId);
    final start = (index ~/ 2) * 2;
    final pair = row.skip(start).take(2).toList();
    return pair.length == 2 ? pair.map((item) => item.seatId).toSet() : {};
  }

  Widget _pendingShell(Widget body) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _handleBack();
    },
    child: AppShell(
      currentIndex: 2,
      showBottomNavigation: false,
      bookingTitle: 'Vé & Ghế',
      bookingSubtitle: 'Bước 2/4',
      onBookingBack: _handleBack,
      body: body,
    ),
  );

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
    final candidateMap = _lastSeatMap ?? seatMapState.asData?.value;
    final seatMap = candidateMap?.showtime.id == widget.showtimeId
        ? candidateMap
        : null;
    if (!_initialRefreshStarted && candidateMap != null) {
      _initialRefreshStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (seatMap != null) {
          _lastSeatMap = seatMap;
          _beginForMap(seatMap);
        }
        _refreshSeatMap();
      });
    }
    if (seatMap == null && (seatMapState.hasError || _seatMapFailed)) {
      return _pendingShell(RepositoryStatePane.error(onRetry: _refreshSeatMap));
    }
    if (seatMap == null) {
      return _pendingShell(
        const RepositoryStatePane.loading(
          layout: RepositorySkeleton.poster,
          title: 'Đang tải sơ đồ ghế…',
        ),
      );
    }
    final mapFresh =
        _lastSeatMapAt != null &&
        ref.read(appClockProvider).now().difference(_lastSeatMapAt!) <
            _seatMapMaxAge &&
        !_seatMapFailed;

    final selectedSeats = seatMap.seats
        .where((seat) => session.selectedSeatIds.contains(seat.seatId))
        .toList(growable: false);
    final quoteState = ref.watch(seatQuoteProvider);
    final quote = quoteState.isLoading || quoteState.hasError
        ? null
        : quoteState.asData?.value;
    final total = session.hasActiveHold
        ? session.booking!.tickets.fold(
            VndMoney.zero,
            (value, ticket) => value + ticket.lineTotal,
          )
        : selectedSeats.isEmpty
        ? VndMoney.zero
        : quote?.ticketSubtotal;
    if (session.hasActiveHold && _timer == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _timer == null) _startTimer();
      });
    }
    final holding = session.phase == BookingEntryPhase.holding;
    final submitting = session.phase == BookingEntryPhase.submittingHold;
    final currentUserId = ref.watch(authSessionProvider).session?.user.id;
    final ownHoldSeatIds =
        holding &&
            session.booking?.userId == currentUserId &&
            currentUserId != null &&
            session.booking?.showtimeId == widget.showtimeId &&
            ref.read(bookingEntryProvider.notifier).remainingHold() >
                Duration.zero
        ? {
            ...session.booking!.seats.map((seat) => seat.seatId),
            ...session.booking!.tickets.map((ticket) => ticket.seatId),
          }
        : <int>{};

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: AppShell(
        currentIndex: 2,
        showBottomNavigation: false,
        bookingTitle: 'Vé & Ghế',
        bookingSubtitle: 'Bước 2/4',
        onBookingBack: submitting ? null : _handleBack,
        body: Column(
          children: [
            const BookingProgress(currentStep: 1),
            if (holding)
              BookingHoldCountdown(
                key: const ValueKey('seat-hold-timer'),
                booking: session.booking,
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShowtimeSummary(
                      seatMap: seatMap,
                      statusControl: !holding && !mapFresh
                          ? _refreshingSeats && !_seatMapFailed
                                ? const Tooltip(
                                    message: 'Đang cập nhật trạng thái ghế',
                                    child: Center(
                                      child: SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.gold,
                                        ),
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    key: const ValueKey(
                                      'seat-map-stale-warning',
                                    ),
                                    tooltip: _seatMapFailed
                                        ? 'Tải lại sơ đồ ghế'
                                        : 'Sơ đồ ghế quá cũ. Tải lại',
                                    onPressed: _refreshSeatMap,
                                    icon: const Icon(
                                      Icons.sync_problem,
                                      color: AppColors.gold,
                                    ),
                                  )
                          : null,
                    ),
                    if ((seatMap.showtime.surchargeAmount?.amount ?? 0) >
                        0) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Phụ thu suất chiếu: ${seatMap.showtime.surchargeAmount!.format()}/vé. Báo giá đã bao gồm phụ thu.',
                        style: AppTextStyles.caption,
                      ),
                    ],
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
                    const SizedBox(height: AppSpacing.md),
                    _SeatZoomToolbar(
                      controller: _seatTransformation,
                      onZoomIn: () => _changeSeatZoom(
                        _seatTransformation.value.getMaxScaleOnAxis() + 0.25,
                      ),
                      onZoomOut: () => _changeSeatZoom(
                        _seatTransformation.value.getMaxScaleOnAxis() - 0.25,
                      ),
                      onReset: () =>
                          _seatTransformation.value = Matrix4.identity(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const _ScreenIndicator(),
                    const SizedBox(height: AppSpacing.md),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        _seatViewportWidth = constraints.maxWidth;
                        return InteractiveViewer(
                          key: const ValueKey('seat-map-interactive'),
                          transformationController: _seatTransformation,
                          minScale: 1,
                          maxScale: 2.5,
                          boundaryMargin: const EdgeInsets.all(24),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: _SeatGrid(
                              seatMap: seatMap,
                              assignments: session.assignments,
                              unavailableSeatIds: session.unavailableSeatIds,
                              ownHoldSeatIds: ownHoldSeatIds,
                              enabled: mapFresh && !holding && !submitting,
                              onSeat: (seat) => ref
                                  .read(bookingEntryProvider.notifier)
                                  .toggleSeatIds(
                                    _seatGroup(seat, seatMap.seats),
                                    unavailableSeatIds: seatMap.seats
                                        .where((item) => !item.selectable)
                                        .map((item) => item.seatId)
                                        .toSet(),
                                  ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SeatLegend(ageRating: seatMap.showtime.movieAgeRating),
                    if (session.assignments.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      _AssignmentSummary(
                        assignments: session.assignments,
                        seats: seatMap.seats,
                      ),
                    ],
                    if (session.message != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        session.message!,
                        key: const ValueKey('booking-entry-message'),
                        style: const TextStyle(color: AppColors.adultBadge),
                      ),
                    ],
                    if (!holding && quoteState.hasError)
                      TextButton.icon(
                        key: const ValueKey('seat-quote-retry'),
                        onPressed: () => ref.invalidate(seatQuoteProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Chưa lấy được giá vé. Thử lại'),
                      ),
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
                  submitting ||
                      (!holding && !mapFresh) ||
                      !session.assignmentComplete ||
                      (!holding && quote == null)
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
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
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            BookingTicketPolicy.restriction(
                                  type,
                                  session.movieAgeRating,
                                ) ??
                                'Đã gán ${session.assignedFor(type)}/${session.quantityFor(type)} ghế',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    if (BookingTicketPolicy.restriction(
                          type,
                          session.movieAgeRating,
                        ) ==
                        null) ...[
                      IconButton(
                        tooltip: 'Giảm vé ${_ticketLabel(type)}',
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        key: ValueKey(
                          'ticket-minus-${type.wireValue.toLowerCase()}',
                        ),
                        onPressed: !editable || session.quantityFor(type) == 0
                            ? null
                            : () =>
                                  onChange(type, session.quantityFor(type) - 1),
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      Text(
                        '${session.quantityFor(type)}',
                        style: AppTextStyles.sectionTitle,
                      ),
                      IconButton(
                        tooltip: 'Thêm vé ${_ticketLabel(type)}',
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        key: ValueKey(
                          'ticket-plus-${type.wireValue.toLowerCase()}',
                        ),
                        onPressed:
                            !editable ||
                                session.ticketCount >=
                                    BookingTicketPolicy.maxTickets
                            ? null
                            : () =>
                                  onChange(type, session.quantityFor(type) + 1),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
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
  const _ShowtimeSummary({required this.seatMap, this.statusControl});
  final ShowtimeSeatMapDto seatMap;
  final Widget? statusControl;
  @override
  Widget build(BuildContext context) {
    final showtime = seatMap.showtime;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadii.control,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  showtime.movieTitle ?? 'Chọn ghế',
                  style: AppTextStyles.cardTitle,
                ),
              ),
              SizedBox.square(dimension: 48, child: statusControl),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${showtime.cinemaName} · ${showtime.roomName}',
            style: AppTextStyles.caption,
          ),
          Text(_dateTime(showtime.startTime), style: AppTextStyles.caption),
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

class _SeatZoomToolbar extends StatelessWidget {
  const _SeatZoomToolbar({
    required this.controller,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  final TransformationController controller;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Matrix4>(
    valueListenable: controller,
    builder: (context, matrix, _) {
      final scale = matrix.getMaxScaleOnAxis();
      final atOrigin =
          scale <= 1.01 &&
          matrix.storage[12].abs() < 0.5 &&
          matrix.storage[13].abs() < 0.5;
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: AppRadii.control,
          border: Border.all(color: AppColors.borderStrong),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.event_seat_outlined,
                  color: AppColors.gold,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Sơ đồ ghế', style: AppTextStyles.cardTitle),
                ),
                Text(
                  '${(scale * 100).round()}%',
                  key: const ValueKey('seat-zoom-level'),
                  style: AppTextStyles.emphasis.copyWith(color: AppColors.gold),
                ),
                const SizedBox(width: 8),
              ],
            ),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Chụm hai ngón hoặc dùng nút để phóng to',
                    style: AppTextStyles.caption,
                  ),
                ),
                IconButton(
                  key: const ValueKey('seat-zoom-out'),
                  tooltip: 'Thu nhỏ sơ đồ',
                  onPressed: scale <= 1.01 ? null : onZoomOut,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                IconButton(
                  key: const ValueKey('seat-zoom-in'),
                  tooltip: 'Phóng to sơ đồ',
                  onPressed: scale >= 2.49 ? null : onZoomIn,
                  icon: const Icon(Icons.add_circle_outline),
                ),
                IconButton(
                  key: const ValueKey('seat-zoom-reset'),
                  tooltip: 'Đặt lại sơ đồ',
                  onPressed: atOrigin ? null : onReset,
                  icon: const Icon(Icons.center_focus_strong_outlined),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

class _SeatGrid extends StatelessWidget {
  const _SeatGrid({
    required this.seatMap,
    required this.assignments,
    required this.unavailableSeatIds,
    required this.ownHoldSeatIds,
    required this.enabled,
    required this.onSeat,
  });

  final ShowtimeSeatMapDto seatMap;
  final Map<int, SeatTicketAssignment> assignments;
  final Set<int> unavailableSeatIds;
  final Set<int> ownHoldSeatIds;
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
              mainAxisSize: MainAxisSize.min,
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
                      ownHold: ownHoldSeatIds.contains(seat.seatId),
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
    required this.ownHold,
    required this.enabled,
    required this.onTap,
  });

  final ShowtimeSeatDto seat;
  final SeatTicketAssignment? assignment;
  final bool forcedUnavailable;
  final bool ownHold;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected =
        assignment != null &&
        (seat.selectable ||
            (ownHold && seat.runtimeStatus == SeatRuntimeStatus.holding));
    final available = seat.selectable && !forcedUnavailable;
    final occupied = !available && !ownHold;
    final unavailableReason = switch (seat.runtimeStatus) {
      SeatRuntimeStatus.holding => 'đang được giữ',
      SeatRuntimeStatus.booked || SeatRuntimeStatus.checkedIn => 'đã bán',
      _ => 'không khả dụng',
    };
    const availableStandard = Color(0xFF32343A);
    const unavailable = Color(0xFF101114);
    final color = selected
        ? _ticketColor(assignment!.ticketType)
        : !available
        ? unavailable
        : switch (seat.seatType.normalized) {
            CatalogSeatType.vip => AppColors.purple,
            CatalogSeatType.couple => AppColors.adultBadge,
            _ => availableStandard,
          };
    final label = '${seat.rowLabel}${seat.seatNumber}';
    return Semantics(
      button: available && enabled,
      enabled: available && enabled,
      selected: selected,
      label:
          'Ghế $label, ${seat.seatType.normalized.wireValue}, ${ownHold
              ? 'bạn đang giữ'
              : available
              ? 'có thể chọn'
              : unavailableReason}',
      child: InkWell(
        key: ValueKey('seat-${seat.seatId}'),
        onTap: available && enabled ? onTap : null,
        borderRadius: AppRadii.small,
        child: Container(
          width: seat.seatType.normalized == CatalogSeatType.couple ? 56 : 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppRadii.small,
            border: Border.all(
              color: selected
                  ? AppColors.text
                  : available
                  ? const Color(0xFF9A9CA4)
                  : const Color(0xFF303137),
              width: selected
                  ? 2.5
                  : available
                  ? 1.5
                  : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: occupied
                ? Icon(
                    switch (seat.runtimeStatus) {
                      SeatRuntimeStatus.holding => Icons.hourglass_top_rounded,
                      SeatRuntimeStatus.booked ||
                      SeatRuntimeStatus.checkedIn => Icons.lock_outline_rounded,
                      _ => Icons.block_rounded,
                    },
                    size: 18,
                    color: AppColors.textDisabled,
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: AppTextStyles.meta.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SeatLegend extends StatelessWidget {
  const _SeatLegend({required this.ageRating});

  final String? ageRating;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: AppColors.surfaceRaised,
      borderRadius: AppRadii.control,
      border: Border.all(color: AppColors.borderStrong),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Chú giải ghế', style: AppTextStyles.cardTitle),
        const SizedBox(height: AppSpacing.sm),
        const Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            _LegendItem(label: 'Thường', color: Color(0xFF32343A)),
            _LegendItem(label: 'VIP', color: AppColors.purple),
            _LegendItem(label: 'Ghế đôi', color: AppColors.adultBadge),
            _LegendItem(label: 'Đang chọn', color: AppColors.gold),
            _LegendItem(
              label: 'Đang giữ',
              color: Color(0xFF101114),
              icon: Icons.hourglass_top_rounded,
            ),
            _LegendItem(
              label: 'Đã bán',
              color: Color(0xFF101114),
              icon: Icons.lock_outline_rounded,
            ),
            _LegendItem(
              label: 'Không khả dụng',
              color: Color(0xFF101114),
              icon: Icons.block_rounded,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        const Divider(color: AppColors.borderStrong, height: 1),
        const SizedBox(height: AppSpacing.sm),
        const _SeatInfoRow(
          icon: Icons.event_seat_outlined,
          text: 'Ghế đôi cần 2 vé cùng loại. Vuốt ngang để xem hết sơ đồ.',
        ),
        const SizedBox(height: AppSpacing.xs),
        _SeatInfoRow(
          icon: Icons.local_movies_outlined,
          text:
              'Phân loại phim: ${ageRating ?? "P"}${ageRating == "K" ? " • Trẻ dưới 13 tuổi cần người lớn đi cùng." : ""}',
        ),
      ],
    ),
  );
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color, this.icon});
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.surfaceHigh,
      borderRadius: AppRadii.pill,
      border: Border.all(color: AppColors.borderStrong),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Icon(icon, size: 16, color: AppColors.textMuted)
        else
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppRadii.small,
              border: Border.all(color: AppColors.textMuted),
            ),
          ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SeatInfoRow extends StatelessWidget {
  const _SeatInfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: AppColors.gold),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: AppTextStyles.body)),
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
  final VndMoney? total;
  final bool holding, submitting;
  final VoidCallback? onContinue;
  @override
  Widget build(BuildContext context) {
    final summary = Column(
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
          total?.format() ?? 'Đang cập nhật giá',
          style: AppTextStyles.sectionTitle.copyWith(
            color: AppColors.gold,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
    final button = AppButton(
      key: const ValueKey('seat-continue'),
      label: holding
          ? 'Tiếp tục • Bắp nước'
          : submitting
          ? 'Đang giữ ghế...'
          : 'Tiếp tục',
      onPressed: onContinue,
    );
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.surfaceRaised,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked =
                constraints.maxWidth < 330 &&
                MediaQuery.textScalerOf(context).scale(14) > 18;
            return stacked
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [summary, const SizedBox(height: 8), button],
                  )
                : Row(
                    children: [
                      Expanded(child: summary),
                      const SizedBox(width: 12),
                      Flexible(child: SizedBox(width: 170, child: button)),
                    ],
                  );
          },
        ),
      ),
    );
  }
}

String _dateTime(DateTime value) => formatVietnamDateTime(value);

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
