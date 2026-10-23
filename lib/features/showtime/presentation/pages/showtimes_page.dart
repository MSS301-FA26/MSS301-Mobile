import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/time/vietnam_time.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
import '../../../auth/application/auth_session.dart';
import '../../../booking/presentation/widgets/booking_progress.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../../movie/data/models/catalog_enums.dart';
import '../../../movie/data/models/cinema_dto.dart';
import '../../../movie/data/repositories/catalog_providers.dart';
import '../../../movie/presentation/models/movie.dart';
import '../../../movie/presentation/providers/movies_provider.dart';
import '../models/showtime_models.dart';
import '../providers/showtimes_provider.dart';
import '../widgets/date_selector.dart';
import '../widgets/showtime_movie_card.dart';

class ShowtimesPage extends ConsumerStatefulWidget {
  const ShowtimesPage({super.key, this.movieId, this.cinemaId, this.date});
  final int? movieId;
  final int? cinemaId;
  final String? date;

  @override
  ConsumerState<ShowtimesPage> createState() => _ShowtimesPageState();
}

class _ShowtimesPageState extends ConsumerState<ShowtimesPage> {
  ShowtimeSlot? _selectedSlot;
  int? _selectedMovieId;

  @override
  void didUpdateWidget(covariant ShowtimesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.movieId != widget.movieId ||
        oldWidget.cinemaId != widget.cinemaId ||
        oldWidget.date != widget.date) {
      _selectedSlot = null;
      _selectedMovieId = null;
    }
  }

  DateTime _today(DateTime now) {
    final local = vietnamCalendar(now);
    return DateTime(local.year, local.month, local.day);
  }

  DateTime _date(DateTime today) {
    final raw = widget.date;
    if (raw == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
      return today;
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null ||
        parsed.year != int.parse(raw.substring(0, 4)) ||
        parsed.month != int.parse(raw.substring(5, 7)) ||
        parsed.day != int.parse(raw.substring(8, 10)) ||
        parsed.isBefore(today) ||
        parsed.isAfter(today.add(const Duration(days: 30)))) {
      return today;
    }
    return parsed;
  }

  void _setFilters({int? movieId, int? cinemaId, DateTime? date}) {
    setState(() {
      _selectedSlot = null;
      _selectedMovieId = null;
    });
    context.replace(
      AppRoutes.showtimesWithFilters(
        movieId: movieId,
        cinemaId: cinemaId,
        date: date,
      ),
    );
  }

  List<DateOption> _dates(DateTime today, DateTime selected) {
    const weekdays = ['T.Hai', 'T.Ba', 'T.Tư', 'T.Năm', 'T.Sáu', 'T.Bảy', 'CN'];
    final length = selected.difference(today).inDays.clamp(6, 30) + 1;
    return List.generate(length, (index) {
      final date = today.add(Duration(days: index));
      return DateOption(
        date: date,
        label: index == 0 ? 'Hôm nay' : weekdays[date.weekday - 1],
        sub:
            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}',
      );
    });
  }

  Future<void> _pickDate(DateTime today, DateTime selected) async {
    final result = await showDatePicker(
      context: context,
      initialDate: selected,
      firstDate: today,
      lastDate: today.add(const Duration(days: 30)),
      helpText: 'Chọn ngày chiếu',
    );
    if (result != null && mounted) {
      _setFilters(
        movieId: widget.movieId,
        cinemaId: widget.cinemaId,
        date: result == today ? null : result,
      );
    }
  }

  Future<void> _pickItem<T>({
    required String title,
    required List<T> items,
    required String Function(T) label,
    required void Function(T) onSelected,
  }) async {
    var search = '';
    final selected = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, update) {
          final visible = items
              .where(
                (item) =>
                    label(item)
                        .toLowerCase()
                        .contains(search.trim().toLowerCase()),
              )
              .toList(growable: false);
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                MediaQuery.viewInsetsOf(sheetContext).bottom + AppSpacing.md,
              ),
              child: SizedBox(
                height: MediaQuery.sizeOf(sheetContext).height * .55,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.cardTitle),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Tìm $title',
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (value) => update(() => search = value),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: visible.isEmpty
                          ? const Center(child: Text('Không tìm thấy kết quả'))
                          : ListView.builder(
                              itemCount: visible.length,
                              itemBuilder: (context, index) => ListTile(
                                title: Text(label(visible[index])),
                                onTap: () =>
                                    Navigator.pop(sheetContext, visible[index]),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    if (selected != null && mounted) onSelected(selected);
  }

  Future<void> _openSeatSelection(ShowtimeSlot slot) async {
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
    final route = AppRoutes.seatSelection(slot.id);
    if (ref.read(authSessionProvider).isAuthenticated) {
      context.push(route);
    } else {
      context.go(AppRoutes.loginWithRedirect(route));
    }
  }

  List<ShowtimeRoom> _roomsAtCinema(MovieShowtime item, int cinemaId) => item
      .rooms
      .where((room) => (room.cinemaId ?? 0) == cinemaId)
      .toList(growable: false);

  Movie _movieFor(int id, List<Movie> movies) =>
      movies.where((m) => m.id == id).firstOrNull ??
      Movie(
        id: id,
        title: 'Phim #$id',
        ageRating: '',
        hasAgeRating: false,
        duration: 'Đang cập nhật',
        rating: null,
        genre: '',
        tagline: '',
        posterAsset: '',
        status: MovieStatus.unknown,
      );

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(appClockProvider).now();
    final today = _today(now);
    final selectedDate = _date(today);
    final dates = _dates(today, selectedDate);
    final query = ShowtimeQuery(
      movieId: widget.movieId,
      cinemaId: widget.cinemaId,
      date: selectedDate,
    );
    final moviesState = ref.watch(moviesProvider);
    final cinemasState = ref.watch(homeCinemasProvider);
    final showtimesState = ref.watch(showtimesProvider(query));
    final movies = moviesState.value ?? <Movie>[];
    final cinemas = cinemasState.value ?? <CinemaDto>[];
    final chosenMovie = movies.where((m) => m.id == widget.movieId).firstOrNull;
    final chosenCinema = cinemas
        .where((c) => c.id == widget.cinemaId)
        .firstOrNull;
    final items = showtimesState.value ?? <MovieShowtime>[];
    final cinemaIds = <int>{
      for (final item in items)
        for (final room in item.rooms) room.cinemaId ?? 0,
    }.toList(growable: false);
    cinemaIds.sort(
      (a, b) => (cinemas.where((c) => c.id == a).firstOrNull?.name ?? '$a')
          .compareTo(cinemas.where((c) => c.id == b).firstOrNull?.name ?? '$b'),
    );

    ShowtimeSlot? validSelection;
    for (final item in items.where(
      (item) => item.movieId == _selectedMovieId,
    )) {
      for (final room in item.rooms) {
        for (final slot in room.slots) {
          if (slot.id == _selectedSlot?.id && slot.isBookableAt(now)) {
            validSelection = slot;
          }
        }
      }
    }

    Widget filterButton(String title, String value, VoidCallback? onTap) =>
        OutlinedButton(
          onPressed: onTap,
          child: Text(
            '$title: $value',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
    final filtered =
        widget.movieId != null ||
        widget.cinemaId != null ||
        selectedDate != today;
    return AppShell(
      currentIndex: 2,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                const BookingProgress(currentStep: 0),
                if (moviesState.hasError || cinemasState.hasError)
                  RepositoryStatePane.error(
                    compact: true,
                    title: 'Chưa tải đủ phim và rạp',
                    message: 'Lịch chiếu vẫn có thể xem. Thử lại để dùng bộ lọc đầy đủ.',
                    onRetry: () {
                      ref.invalidate(moviesProvider);
                      ref.invalidate(homeCinemasProvider);
                    },
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    0,
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      filterButton(
                        'Phim',
                        chosenMovie?.title ??
                            (widget.movieId == null
                                ? 'Tất cả'
                                : '#${widget.movieId}'),
                        moviesState.isLoading || moviesState.hasError
                            ? null
                            : () => _pickItem<Movie>(
                                title: 'phim',
                                items: movies,
                                label: (m) => m.title,
                                onSelected: (m) => _setFilters(
                                  movieId: m.id,
                                  cinemaId: widget.cinemaId,
                                  date: selectedDate == today
                                      ? null
                                      : selectedDate,
                                ),
                              ),
                      ),
                      filterButton(
                        'Rạp',
                        chosenCinema?.name ??
                            (widget.cinemaId == null
                                ? 'Tất cả'
                                : '#${widget.cinemaId}'),
                        cinemasState.isLoading || cinemasState.hasError
                            ? null
                            : () => _pickItem<CinemaDto>(
                                title: 'rạp',
                                items: cinemas.where((c) => c.active).toList(),
                                label: (c) => '${c.name} · ${c.city}',
                                onSelected: (c) => _setFilters(
                                  movieId: widget.movieId,
                                  cinemaId: c.id,
                                  date: selectedDate == today
                                      ? null
                                      : selectedDate,
                                ),
                              ),
                      ),
                      filterButton(
                        'Ngày',
                        '${selectedDate.day}/${selectedDate.month}',
                        () => _pickDate(today, selectedDate),
                      ),
                    ],
                  ),
                ),
                if (filtered)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Wrap(
                      spacing: 6,
                      children: [
                        if (widget.movieId != null)
                          InputChip(
                            key: const ValueKey('showtime-movie-filter'),
                            backgroundColor: AppColors.surfaceRaised,
                            labelStyle: AppTextStyles.label.copyWith(
                              color: AppColors.text,
                            ),
                            deleteIconColor: AppColors.text,
                            label: Text(
                              'Phim: ${chosenMovie?.title ?? '#${widget.movieId}'}',
                            ),
                            onDeleted: () => _setFilters(
                              cinemaId: widget.cinemaId,
                              date: selectedDate == today ? null : selectedDate,
                            ),
                          ),
                        if (widget.cinemaId != null)
                          InputChip(
                            key: const ValueKey('showtime-cinema-filter'),
                            backgroundColor: AppColors.surfaceRaised,
                            labelStyle: AppTextStyles.label.copyWith(
                              color: AppColors.text,
                            ),
                            deleteIconColor: AppColors.text,
                            label: Text(
                              'Rạp: ${chosenCinema?.name ?? '#${widget.cinemaId}'}',
                            ),
                            onDeleted: () => _setFilters(
                              movieId: widget.movieId,
                              date: selectedDate == today ? null : selectedDate,
                            ),
                          ),
                        if (selectedDate != today)
                          InputChip(
                            key: const ValueKey('showtime-date-filter'),
                            backgroundColor: AppColors.surfaceRaised,
                            labelStyle: AppTextStyles.label.copyWith(
                              color: AppColors.text,
                            ),
                            deleteIconColor: AppColors.text,
                            label: Text(
                              'Ngày: ${selectedDate.day}/${selectedDate.month}',
                            ),
                            onDeleted: () => _setFilters(
                              movieId: widget.movieId,
                              cinemaId: widget.cinemaId,
                            ),
                          ),
                        TextButton(
                          key: const ValueKey('showtime-clear-all'),
                          onPressed: () => _setFilters(),
                          child: const Text('Xóa tất cả'),
                        ),
                      ],
                    ),
                  ),
                DateSelector(
                  dates: dates,
                  selectedIndex: selectedDate.difference(today).inDays,
                  onSelected: (index) => _setFilters(
                    movieId: widget.movieId,
                    cinemaId: widget.cinemaId,
                    date: index == 0 ? null : dates[index].date,
                  ),
                ),
                if (showtimesState.isLoading && !showtimesState.hasValue)
                  const SizedBox(
                    height: 320,
                    child: RepositoryStatePane.loading(
                      layout: RepositorySkeleton.showtimes,
                      title: 'Đang tải lịch chiếu…',
                    ),
                  )
                else if (showtimesState.hasError && !showtimesState.hasValue)
                  RepositoryStatePane.error(
                    title: 'Chưa tải được lịch chiếu',
                    onRetry: () => ref.invalidate(showtimesProvider(query)),
                  )
                else ...[
                  if (showtimesState.hasError)
                    RepositoryStatePane.error(
                      compact: true,
                      message:
                          'Chưa cập nhật được lịch chiếu. Vui lòng thử lại.',
                      onRetry: () => ref.invalidate(showtimesProvider(query)),
                    ),
                  if (cinemaIds.isEmpty)
                    const RepositoryStatePane.empty(
                      title: 'Chưa có lịch chiếu',
                      message: 'Không có suất phù hợp trong ngày này. Hãy thử bộ lọc khác.',
                    ),
                  for (final cinemaId in cinemaIds) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 19,
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              (cinemaId == 0 ? 'Rạp đang cập nhật' : null) ??
                                  cinemas
                                      .where((c) => c.id == cinemaId)
                                      .firstOrNull
                                      ?.name ??
                                  items
                                      .expand((i) => i.rooms)
                                      .where((r) => r.cinemaId == cinemaId)
                                      .first
                                      .cinemaName ??
                                  'Rạp #$cinemaId',
                              style: AppTextStyles.cardTitle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (final item in items)
                      if (_roomsAtCinema(item, cinemaId).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            0,
                            AppSpacing.md,
                            AppSpacing.md,
                          ),
                          child: ShowtimeMovieCard(
                            now: now,
                            movie: _movieFor(item.movieId, movies),
                            rooms: _roomsAtCinema(item, cinemaId),
                            selectedSlotId: _selectedMovieId == item.movieId
                                ? _selectedSlot?.id
                                : null,
                            onSlotSelected: showtimesState.hasError
                                ? null
                                : (slot) => setState(() {
                                    _selectedMovieId = item.movieId;
                                    _selectedSlot = slot;
                                  }),
                          ),
                        ),
                  ],
                ],
              ],
            ),
          ),
          if (validSelection != null && !showtimesState.hasError)
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
                      onPressed: () => _openSeatSelection(validSelection!),
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
