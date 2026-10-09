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
import '../widgets/showtime_selection_bar.dart';

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
            cinemaId: room.cinemaId,
            cinemaName: room.cinemaName,
          );
        })
        .where((room) => room.slots.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _openSeatSelection(int movieId, ShowtimeSlot slot) async {
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
    final dates = _dates(ref.watch(appClockProvider).now());
    final selectedDate = _selectedDate == null
        ? null
        : dates[_selectedDate!].date;
    final showtimesQuery = ShowtimeQuery(
      movieId: widget.movieId,
      date: selectedDate,
    );
    final showtimesState = ref.watch(showtimesProvider(showtimesQuery));
    if (moviesState.isLoading || showtimesState.isLoading) {
      return const AppShell(
        currentIndex: 2,
        body: RepositoryStatePane.loading(),
      );
    }
    if (moviesState.hasError || showtimesState.hasError) {
      return AppShell(
        currentIndex: 2,
        body: RepositoryStatePane.error(
          onRetry: () {
            ref.invalidate(moviesProvider);
            ref.invalidate(showtimesProvider(showtimesQuery));
          },
        ),
      );
    }

    final movies = moviesState.requireValue;
    final allShowtimes = showtimesState.requireValue;
    final showtimes = allShowtimes;
    final scheduleControls = <Widget>[
      const BookingProgress(currentStep: 0),
      CinemaStatusCard(
        selectedDate: _selectedDate == null ? null : dates[_selectedDate!],
        onInfo: () => showModalBottomSheet<void>(
          context: context,
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
          builder: (context) => const CinemaInfoSheet(),
        ),
      ),
      DateSelector(
        dates: dates,
        selectedIndex: _selectedDate,
        onSelected: (index) => setState(() => _selectedDate = index),
      ),
    ];

    return AppShell(
      currentIndex: 2,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
          final pinScheduleControls = constraints.maxHeight >= 480 * textScale;
          return Column(
            children: [
              if (pinScheduleControls) ...scheduleControls,
              Expanded(
                child: ListView(
                  children: [
                    if (!pinScheduleControls) ...scheduleControls,
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
                                final rooms = _visibleRooms(
                                  movieShowtime,
                                  dates,
                                );
                                if (rooms.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md,
                                  ),
                                  child: ShowtimeMovieCard(
                                    movie: movie,
                                    rooms: rooms,
                                    selectedSlotId:
                                        _selectedMovieId ==
                                            movieShowtime.movieId
                                        ? _selectedSlot?.id
                                        : null,
                                    onSlotSelected: (slot) => setState(() {
                                      _selectedMovieId = movieShowtime.movieId;
                                      _selectedSlot = slot;
                                    }),
                                  ),
                                );
                              },
                            ),
                          if (showtimes.isEmpty)
                            const RepositoryStatePane.empty(
                              title: 'Chưa có lịch chiếu',
                              message: 'Chưa có suất chiếu cho lựa chọn hiện tại. Hãy thử một ngày khác.',
                            ),
                          if (showtimes.isNotEmpty &&
                              showtimes.every(
                                (item) => _visibleRooms(item, dates).isEmpty,
                              ))
                            const RepositoryStatePane.empty(
                              title: 'Không có suất phù hợp',
                              message:
                                  'Hãy chọn một ngày khác để xem lịch chiếu.',
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedSlot != null && _selectedMovieId != null)
                ShowtimeSelectionBar(
                  slot: _selectedSlot!,
                  onContinue: () =>
                      _openSeatSelection(_selectedMovieId!, _selectedSlot!),
                ),
            ],
          );
        },
      ),
    );
  }
}

bool _sameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;
