import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/cinema_info_sheet.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
import '../../../discover/presentation/widgets/format_filter_chips.dart';
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
  String _selectedFormat = 'Tất cả';

  static const _formats = [
    'Tất cả',
    'IMAX Laser',
    'Dolby Atmos',
    'VIP Suite',
    '2D Phụ đề',
  ];

  bool _roomMatches(ShowtimeRoom room) {
    if (_selectedFormat == 'Tất cả') return true;
    return room.formatBadge.toLowerCase().contains(
      _selectedFormat.toLowerCase().replaceAll('2d phụ đề', 'standard'),
    );
  }

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
        .where(_roomMatches)
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

  @override
  Widget build(BuildContext context) {
    final moviesState = ref.watch(moviesProvider);
    final showtimesState = ref.watch(showtimesProvider);
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
            ref.invalidate(showtimesProvider);
          },
        ),
      );
    }

    final movies = moviesState.requireValue;
    final allShowtimes = showtimesState.requireValue;
    final dates = _dates(ref.watch(appClockProvider).now());
    final showtimes = widget.movieId == null
        ? allShowtimes
        : allShowtimes
              .where((showtime) => showtime.movieId == widget.movieId)
              .toList(growable: false);

    return AppShell(
      currentIndex: 2,
      body: ListView(
        children: [
          CinemaStatusCard(
            onInfo: () => showModalBottomSheet<void>(
              context: context,
              backgroundColor: AppColors.surface,
              shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
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
                  color: AppColors.textDisabled,
                ),
                SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Chọn một ngày để lọc lịch chiếu. Chọn ghế sẽ được mở ở R4.',
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ),
          ),
          DateSelector(
            dates: dates,
            selectedIndex: _selectedDate,
            onSelected: (index) => setState(() => _selectedDate = index),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: FormatFilterChips(
              filters: _formats,
              selected: _selectedFormat,
              onSelected: (format) => setState(() => _selectedFormat = format),
            ),
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
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: ShowtimeMovieCard(
                          movie: movie,
                          rooms: rooms,
                          selectedSlotId: null,
                          onSlotSelected: null,
                        ),
                      );
                    },
                  ),
                if (showtimes.isEmpty)
                  const RepositoryStatePane.empty(
                    title: 'Chưa có lịch chiếu',
                    message: 'Phim này chưa có suất chiếu đang mở bán.',
                  ),
                if (showtimes.isNotEmpty &&
                    showtimes.every(
                      (item) => _visibleRooms(item, dates).isEmpty,
                    ))
                  const RepositoryStatePane.empty(
                    title: 'Không có suất phù hợp',
                    message: 'Hãy chọn ngày hoặc định dạng khác.',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

bool _sameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;
