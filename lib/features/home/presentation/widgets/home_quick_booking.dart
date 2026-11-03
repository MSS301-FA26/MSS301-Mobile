import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../movie/presentation/models/movie.dart';
import '../../../movie/data/repositories/catalog_providers.dart';
import '../../../showtime/presentation/models/showtime_models.dart';
import '../../../showtime/presentation/providers/showtimes_provider.dart';
import '../providers/home_providers.dart';

/// Only selector state lives here. Booking/hold/pricing remain in the existing flow.
class HomeQuickBooking extends ConsumerStatefulWidget {
  const HomeQuickBooking({
    super.key,
    required this.movies,
    required this.onBook,
  });
  final List<Movie> movies;
  final ValueChanged<int> onBook;

  @override
  ConsumerState<HomeQuickBooking> createState() => _HomeQuickBookingState();
}

class _HomeQuickBookingState extends ConsumerState<HomeQuickBooking> {
  int? _movieId;
  int? _cinemaId;
  DateTime? _date;
  int? _showtimeId;

  @override
  Widget build(BuildContext context) {
    final movie = widget.movies.where((m) => m.id == _movieId).firstOrNull;
    final cinemasState = ref.watch(homeCinemasProvider);
    final query = ShowtimeQuery(movieId: movie?.id);
    final schedule = movie == null ? null : ref.watch(showtimesProvider(query));
    final now = ref.watch(appClockProvider).now();
    final rooms = [
      for (final film in schedule?.value ?? <MovieShowtime>[])
        if (film.movieId == movie?.id) ...film.rooms,
    ];
    bool usable(ShowtimeSlot slot) =>
        slot.isBookable && slot.startAt.isAfter(now);
    final dates = List<DateTime>.generate(
      7,
      (index) => DateTime(now.year, now.month, now.day + index),
    );
    final cinemas = [
      for (final cinema in cinemasState.value ?? [])
        if (cinema.active &&
            rooms.any(
              (room) =>
                  room.cinemaId == cinema.id &&
                  room.slots.any(
                    (slot) =>
                        usable(slot) &&
                        dates.contains(
                          DateTime(
                            slot.startAt.year,
                            slot.startAt.month,
                            slot.startAt.day,
                          ),
                        ),
                  ),
            ))
          cinema,
    ];
    final cinema = cinemas.where((c) => c.id == _cinemaId).firstOrNull;
    final cinemaRooms = rooms.where((r) => r.cinemaId == cinema?.id);
    final availableDates = [
      for (final day in dates)
        if (cinemaRooms.any(
          (room) => room.slots.any(
            (slot) =>
                usable(slot) &&
                DateTime(
                      slot.startAt.year,
                      slot.startAt.month,
                      slot.startAt.day,
                    ) ==
                    day,
          ),
        ))
          day,
    ];
    final date = availableDates.where((d) => d == _date).firstOrNull;
    final slots = [
      for (final room in cinemaRooms)
        for (final slot in room.slots)
          if (usable(slot) &&
              date != null &&
              DateTime(
                    slot.startAt.year,
                    slot.startAt.month,
                    slot.startAt.day,
                  ) ==
                  date)
            (slot: slot, room: room),
    ]..sort((a, b) => a.slot.startAt.compareTo(b.slot.startAt));
    final selected = slots.where((s) => s.slot.id == _showtimeId).firstOrNull;
    final failed = cinemasState.hasError || (schedule?.hasError ?? false);
    final loading = cinemasState.isLoading || (schedule?.isLoading ?? false);
    final dataReady = !failed && !loading;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            key: const ValueKey('home-quick-card'),
            color: AppColors.surface,
            shape: const RoundedRectangleBorder(
              side: BorderSide(color: AppColors.goldBorder),
              borderRadius: BorderRadius.all(Radius.circular(18)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.confirmation_number_outlined,
                        color: AppColors.gold,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'MUA VÉ NHANH',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .5,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '4 BƯỚC',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  HomeBookingStep(
                    step: 1,
                    name: 'Phim',
                    label: movie?.title ?? 'Chọn phim',
                    selected: movie != null,
                    onTap: widget.movies.isEmpty
                        ? null
                        : () async {
                            final id = await homeChoose<int>(
                              context,
                              'Chọn phim',
                              [
                                for (final m in widget.movies)
                                  (value: m.id, label: m.title),
                              ],
                              imageAssets: {
                                for (final m in widget.movies)
                                  m.id: m.posterAsset,
                              },
                            );
                            if (!mounted || id == null) return;
                            setState(() {
                              _movieId = id;
                              _cinemaId = null;
                              _date = null;
                              _showtimeId = null;
                            });
                          },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: HomeBookingStep(
                          step: 2,
                          name: 'Rạp',
                          label:
                              cinema?.name ??
                              (movie != null && dataReady && cinemas.isEmpty
                                  ? 'Chưa có rạp'
                                  : 'Chọn rạp'),
                          selected: cinema != null,
                          onTap: movie == null || !dataReady || cinemas.isEmpty
                              ? null
                              : () async {
                                  final id = await homeChoose<int>(
                                    context,
                                    'Chọn rạp',
                                    [
                                      for (final c in cinemas)
                                        (value: c.id, label: c.name),
                                    ],
                                  );
                                  if (!mounted || id == null) return;
                                  setState(() {
                                    _cinemaId = id;
                                    _date = null;
                                    _showtimeId = null;
                                  });
                                },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: HomeBookingStep(
                          step: 3,
                          name: 'Ngày',
                          label: date == null ? 'Chọn ngày' : _dateLabel(date),
                          selected: date != null,
                          onTap:
                              cinema == null ||
                                  !dataReady ||
                                  availableDates.isEmpty
                              ? null
                              : () async {
                                  final selected = await homeChoose<DateTime>(
                                    context,
                                    'Chọn ngày',
                                    [
                                      for (final d in availableDates)
                                        (value: d, label: _dateLabel(d)),
                                    ],
                                  );
                                  if (!mounted || selected == null) return;
                                  setState(() {
                                    _date = selected;
                                    _showtimeId = null;
                                  });
                                },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  HomeBookingStep(
                    step: 4,
                    name: 'Suất',
                    label: selected == null
                        ? (date != null && dataReady && slots.isEmpty
                              ? 'Chưa có suất chiếu'
                              : 'Chọn suất')
                        : '${selected.slot.time} • ${selected.room.name}',
                    selected: selected != null,
                    onTap: date == null || !dataReady || slots.isEmpty
                        ? null
                        : () async {
                            final id = await homeChoose<int>(
                              context,
                              'Chọn suất',
                              [
                                for (final s in slots)
                                  (
                                    value: s.slot.id,
                                    label: '${s.slot.time} • ${s.room.name}',
                                  ),
                              ],
                            );
                            if (!mounted || id == null) return;
                            setState(() => _showtimeId = id);
                          },
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: const ValueKey('home-quick-buy'),
                    onPressed: selected == null || !dataReady
                        ? null
                        : () => widget.onBook(selected.slot.id),
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward, size: 20),
                    label: const Text('MUA VÉ NHANH'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      disabledBackgroundColor: AppColors.goldSurface,
                      disabledForegroundColor: AppColors.textMuted,
                      textStyle: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (failed)
            RepositoryStatePane.error(
              message:
                  'Không thể tải rạp hoặc suất chiếu cho lựa chọn hiện tại.',
              onRetry: () {
                ref.invalidate(homeCinemasProvider);
                if (movie != null) ref.invalidate(showtimesProvider(query));
              },
              compact: true,
            ),
        ],
      ),
    );
  }
}

class HomeBookingStep extends StatelessWidget {
  const HomeBookingStep({
    super.key,
    required this.step,
    required this.name,
    required this.label,
    required this.selected,
    this.onTap,
  });
  final int step;
  final String name;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.goldSurface : AppColors.surfaceRaised,
    shape: RoundedRectangleBorder(
      side: BorderSide(
        color: selected ? AppColors.goldBorder : AppColors.borderStrong,
      ),
      borderRadius: AppRadii.small,
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: ValueKey('home-quick-step-$step'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.gold : AppColors.goldSurface,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$step',
                    style: AppTextStyles.caption.copyWith(
                      color: selected ? AppColors.background : AppColors.gold,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    name.toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .5,
                    ),
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: selected ? AppColors.gold : AppColors.textMuted,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              semanticsLabel: '$name: $label',
              style: AppTextStyles.body.copyWith(
                color: onTap == null && !selected
                    ? AppColors.textMuted
                    : AppColors.text,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<T?> homeChoose<T>(
  BuildContext context,
  String title,
  List<({T value, String label})> options, {
  Map<T, String>? imageAssets,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  showDragHandle: false,
  backgroundColor: AppColors.surface,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
  ),
  builder: (context) {
    var query = '';
    return StatefulBuilder(
      builder: (context, setModalState) {
        final isMovieChooser = title == 'Chọn phim';
        final icon = isMovieChooser
            ? Icons.movie_outlined
            : Icons.checklist_rounded;
        final availability = isMovieChooser
            ? 'phim khả dụng'
            : 'lựa chọn khả dụng';
        final maxHeight = MediaQuery.sizeOf(context).height * .72;
        final filteredOptions = options
            .where(
              (option) => option.label.toLowerCase().contains(
                query.toLowerCase().trim(),
              ),
            )
            .toList(growable: false);

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  key: const ValueKey('home-choice-header'),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.goldSurface,
                          borderRadius: AppRadii.small,
                        ),
                        child: Icon(icon, color: AppColors.gold),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: AppTextStyles.sectionTitle),
                            const SizedBox(height: 2),
                            Text(
                              '${options.length} $availability',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Đóng',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                if (isMovieChooser)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: TextField(
                      onChanged: (value) => setModalState(() => query = value),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm phim...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: AppRadii.small,
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                const Divider(height: 1),
                Flexible(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                    itemCount: filteredOptions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final option = filteredOptions[index];
                      return Material(
                        color: AppColors.surface,
                        shape: const RoundedRectangleBorder(
                          side: BorderSide(color: AppColors.border),
                          borderRadius: AppRadii.small,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: ValueKey('home-choice-${option.value}'),
                          onTap: () => Navigator.of(context).pop(option.value),
                          child: Semantics(
                            button: true,
                            label: option.label,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  if (imageAssets?[option.value]
                                          ?.trim()
                                          .isNotEmpty ==
                                      true)
                                    SizedBox(
                                      width: 42,
                                      height: 58,
                                      child: AppImage(
                                        asset: imageAssets![option.value]!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  else
                                    Icon(icon, color: AppColors.textSecondary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      option.label,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.body.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: AppColors.gold,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  },
);

String _dateLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
