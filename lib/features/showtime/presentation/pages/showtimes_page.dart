import '../../../../core/time/vietnam_time.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/cinema_info_sheet.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
import '../../../auth/application/auth_session.dart';
import '../../../booking/presentation/widgets/booking_progress.dart';
import '../../../movie/data/repositories/catalog_providers.dart';
import '../../../movie/presentation/providers/movies_provider.dart';
import '../models/showtime_models.dart';
import '../providers/showtimes_provider.dart';
import '../widgets/cinema_status_card.dart';
import '../widgets/date_selector.dart';
import '../widgets/showtime_movie_card.dart';

class ShowtimesPage extends ConsumerStatefulWidget {
  const ShowtimesPage({super.key, this.movieId});

  final int? movieId;

  @override
  ConsumerState<ShowtimesPage> createState() => _ShowtimesPageState();
}

class _ShowtimesPageState extends ConsumerState<ShowtimesPage> {
  int? _selectedDate;
  int? _selectedMovieId;
  ShowtimeSlot? _selectedSlot;
  void _selectDate(int index) => setState(() {
    if (_selectedDate == index) return;
    _selectedDate = index;
    _selectedSlot = null;
    _selectedMovieId = null;
  });
  List<DateOption> _dates(DateTime now) => List.generate(7, (index) {
    final date = DateTime(now.year, now.month, now.day + index);
    const weekdays = [
      'T.Hai',
      'T.Ba',
      'T.Tư',
      'T.Năm',
      'T.Sáu',
      'T.Bảy',
      'Chủ Nhật',
    ];
    return DateOption(
      date: date,
      label: index == 0 ? 'Hôm nay' : weekdays[date.weekday - 1],
      sub:
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}',
    );
  });

  List<ShowtimeRoom> _visibleRooms(
    MovieShowtime movieShowtime,
    List<DateOption> dates,
  ) {
    final selected = _selectedDate == null ? null : dates[_selectedDate!].date;
    return movieShowtime.rooms
        .map((room) {
          final slots = selected == null
              ? room.slots
              : room.slots
                    .where((slot) => _sameDay(slot.startAt, selected))
                    .toList(growable: false);
          return ShowtimeRoom(
            id: room.id,
            name: room.name,
            formatBadge: room.formatBadge,
            screenDetail: room.screenDetail,
            slots: slots,
          );
        })
        .where((room) => room.slots.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _openSeatSelection(int movieId, ShowtimeSlot slot) async {
    if (!slot.isBookableAt(ref.read(appClockProvider).now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Suất chiếu không còn mở bán. Vui lòng chọn suất khác.',
          ),
        ),
      );
      setState(() {
        _selectedSlot = null;
        _selectedMovieId = null;
      });
      return;
    }
    final auth = ref.read(authSessionProvider);
    if (auth.isAuthenticated) {
      context.push(AppRoutes.seatSelection(slot.id));
      return;
    }
    context.go(AppRoutes.loginWithRedirect(AppRoutes.seatSelection(slot.id)));
  }

  @override
  Widget build(BuildContext context) {
    final moviesState = ref.watch(moviesProvider);
    final now = ref.watch(appClockProvider).now();
    final dates = _dates(vietnamCalendar(now));
    final selectedDate = _selectedDate == null
        ? null
        : dates[_selectedDate!].date;
    final showtimesQuery = ShowtimeQuery(
      movieId: widget.movieId,
      date: selectedDate,
    );
    final showtimesState = ref.watch(showtimesProvider(showtimesQuery));
    Widget pending(Widget content) => AppShell(
      currentIndex: 2,
      body: Column(
        children: [
          const BookingProgress(currentStep: 0),
          DateSelector(
            dates: dates,
            selectedIndex: _selectedDate,
            onSelected: _selectDate,
          ),
          Expanded(child: content),
        ],
      ),
    );
    if ((moviesState.isLoading || showtimesState.isLoading) &&
        !(moviesState.hasValue && showtimesState.hasValue)) {
      return pending(
        const RepositoryStatePane.loading(
          layout: RepositorySkeleton.showtimes,
          title: 'Đang tải lịch chiếu…',
        ),
      );
    }
    if ((moviesState.hasError || showtimesState.hasError) &&
        !(moviesState.hasValue && showtimesState.hasValue)) {
      return pending(
        RepositoryStatePane.error(
          onRetry: () {
            ref.invalidate(moviesProvider);
            ref.invalidate(showtimesProvider(showtimesQuery));
          },
          title: 'Chưa tải được lịch chiếu',
        ),
      );
    }

    final movies = moviesState.requireValue;
    final allShowtimes = showtimesState.requireValue;
    final showtimes = allShowtimes;
    ShowtimeSlot? validSelection;
    for (final item in showtimes.where(
      (item) => item.movieId == _selectedMovieId,
    )) {
      for (final room in _visibleRooms(item, dates)) {
        for (final slot in room.slots) {
          if (slot.id == _selectedSlot?.id && slot.isBookableAt(now)) {
            validSelection = slot;
          }
        }
      }
    }

    return AppShell(
      currentIndex: 2,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                if (moviesState.hasError || showtimesState.hasError)
                  RepositoryStatePane.error(
                    compact: true,
                    message: 'Chưa cập nhật được lịch chiếu. Kiểm tra lại trước khi chọn suất.',
                    onRetry: () {
                      ref.invalidate(moviesProvider);
                      ref.invalidate(showtimesProvider(showtimesQuery));
                    },
                  ),
                const BookingProgress(currentStep: 0),
                CinemaStatusCard(
                  onInfo: () => showModalBottomSheet<void>(
                    context: context,
                    backgroundColor: AppColors.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadii.card,
                    ),
                    builder: (context) => const CinemaInfoSheet(),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    0,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_clock_outlined,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Chọn ngày để lọc lịch chiếu, sau đó chọn một suất còn mở bán.',
                          style: AppTextStyles.caption,
                        ),
                      ),
                    ],
                  ),
                ),
                DateSelector(
                  dates: dates,
                  selectedIndex: _selectedDate,
                  onSelected: _selectDate,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    children: [
                      for (final movieShowtime in showtimes)
                        Builder(
                          builder: (context) {
                            final movie = movies.firstWhere(
                              (movie) => movie.id == movieShowtime.movieId,
                            );
                            final rooms = _visibleRooms(movieShowtime, dates);
                            if (rooms.isEmpty) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: ShowtimeMovieCard(
                                now: now,
                                movie: movie,
                                rooms: rooms,
                                selectedSlotId:
                                    _selectedMovieId == movieShowtime.movieId
                                    ? _selectedSlot?.id
                                    : null,
                                onSlotSelected:
                                    moviesState.hasError ||
                                        showtimesState.hasError
                                    ? null
                                    : (slot) => setState(() {
                                        _selectedMovieId =
                                            movieShowtime.movieId;
                                        _selectedSlot = slot;
                                      }),
                              ),
                            );
                          },
                        ),
                      if (showtimes.isEmpty)
                        RepositoryStatePane.empty(
                          title: 'Chưa có lịch chiếu',
                          message: widget.movieId == null
                              ? 'Chưa có suất chiếu phù hợp. Hãy thử ngày khác.'
                              : 'Phim này chưa có suất chiếu phù hợp. Hãy thử ngày khác.',
                        ),
                      if (showtimes.isNotEmpty &&
                          showtimes.every(
                            (item) => _visibleRooms(item, dates).isEmpty,
                          ))
                        const RepositoryStatePane.empty(
                          title: 'Không có suất phù hợp',
                          message: 'Hãy chọn ngày khác để xem lịch chiếu.',
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (validSelection != null && _selectedMovieId != null)
            SafeArea(
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
                      child: Text(
                        'Đã chọn ${validSelection.time} • ${validSelection.priceDisplay}',
                        style: AppTextStyles.cardTitle,
                      ),
                    ),
                    FilledButton.icon(
                      key: const ValueKey('showtime-continue'),
                      onPressed: moviesState.hasError || showtimesState.hasError
                          ? null
                          : () => _openSeatSelection(
                              _selectedMovieId!,
                              validSelection!,
                            ),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Vé & Ghế'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

bool _sameDay(DateTime first, DateTime second) => isVietnamDate(first, second);
