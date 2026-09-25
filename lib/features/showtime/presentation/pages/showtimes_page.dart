import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/cinema_info_sheet.dart';
import '../../../discover/presentation/widgets/format_filter_chips.dart';
import '../../../movie/presentation/providers/mock_movies_provider.dart';
import '../models/showtime_models.dart';
import '../providers/mock_showtimes_provider.dart';
import '../widgets/cinema_status_card.dart';
import '../widgets/date_selector.dart';
import '../widgets/showtime_movie_card.dart';

class ShowtimesPage extends ConsumerStatefulWidget {
  const ShowtimesPage({super.key, this.movieId});

  final String? movieId;

  @override
  ConsumerState<ShowtimesPage> createState() => _ShowtimesPageState();
}

class _ShowtimesPageState extends ConsumerState<ShowtimesPage> {
  int _selectedDate = 0;
  String _selectedFormat = 'Tất cả';

  static const _dates = [
    DateOption(label: 'Hôm nay', sub: '14/09'),
    DateOption(label: 'T.Ba', sub: '15/09'),
    DateOption(label: 'T.Tư', sub: '16/09'),
    DateOption(label: 'T.Năm', sub: '17/09'),
    DateOption(label: 'T.Sáu', sub: '18/09'),
    DateOption(label: 'T.Bảy', sub: '19/09'),
    DateOption(label: 'Chủ Nhật', sub: '20/09'),
  ];

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

  @override
  Widget build(BuildContext context) {
    final movies = ref.watch(mockMoviesProvider);
    final allShowtimes = ref.watch(mockShowtimesProvider);
    final showtimes = widget.movieId == null
        ? allShowtimes
        : allShowtimes
              .where((showtime) => showtime.movieId == widget.movieId)
              .toList();

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
                    'Chọn ghế đang tạm khóa trong bản mock hiện tại.',
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ),
          ),
          DateSelector(
            dates: _dates,
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
                      final rooms = movieShowtime.rooms
                          .where(_roomMatches)
                          .toList();
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
