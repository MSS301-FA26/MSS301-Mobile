import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
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
    final cinemas = [
      for (final cinema in cinemasState.value ?? [])
        if (cinema.active &&
            rooms.any(
              (room) => room.cinemaId == cinema.id && room.slots.any(usable),
            ))
          cinema,
    ];
    final cinema = cinemas.where((c) => c.id == _cinemaId).firstOrNull;
    final cinemaRooms = rooms.where(
      (r) => r.cinemaId == cinema?.id && cinema != null,
    );
    final dates = {
      for (final room in cinemaRooms)
        for (final slot in room.slots)
          if (usable(slot))
            DateTime(slot.startAt.year, slot.startAt.month, slot.startAt.day),
    }.toList()..sort();
    final date = dates.where((d) => d == _date).firstOrNull;
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
              side: BorderSide(color: AppColors.borderStrong),
              borderRadius: AppRadii.small,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Text(
                    'MUA VÉ NHANH',
                    style: AppTextStyles.label.copyWith(color: AppColors.gold),
                  ),
                ),
                HomeBookingStep(
                  step: 1,
                  name: 'Phim',
                  label: movie?.title ?? 'Chọn phim',
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
                const Divider(color: AppColors.borderStrong),
                HomeBookingStep(
                  step: 2,
                  name: 'Rạp',
                  label: cinema?.name ?? 'Chọn rạp',
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
                const Divider(color: AppColors.borderStrong),
                HomeBookingStep(
                  step: 3,
                  name: 'Ngày',
                  label: date == null ? 'Chọn ngày' : _dateLabel(date),
                  onTap: cinema == null || !dataReady || dates.isEmpty
                      ? null
                      : () async {
                          final selected = await homeChoose<DateTime>(
                            context,
                            'Chọn ngày',
                            [
                              for (final d in dates)
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
                const Divider(color: AppColors.borderStrong),
                HomeBookingStep(
                  step: 4,
                  name: 'Suất',
                  label: selected == null
                      ? 'Chọn suất'
                      : '${selected.slot.time} • ${selected.room.name}',
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
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: FilledButton.icon(
                    key: const ValueKey('home-quick-buy'),
                    onPressed: selected == null || !dataReady
                        ? null
                        : () => widget.onBook(selected.slot.id),
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward, size: 20),
                    label: const Text('MUA VÉ NHANH'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      disabledBackgroundColor: AppColors.goldSurface,
                      disabledForegroundColor: AppColors.textMuted,
                      textStyle: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
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
            )
          else if (loading)
            const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (movie != null && cinemas.isEmpty)
            const RepositoryStatePane.empty(
              title: 'Chưa có suất chiếu phù hợp',
              message: 'Hãy chọn một phim khác hoặc xem lịch chiếu.',
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
    this.onTap,
  });
  final int step;
  final String name;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    key: ValueKey('home-quick-step-$step'),
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 24 * MediaQuery.textScalerOf(context).scale(12) / 12,
              height: 24 * MediaQuery.textScalerOf(context).scale(12) / 12,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$step',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.background,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.end,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                semanticsLabel: '$name: $label',
                style: AppTextStyles.body.copyWith(
                  color: onTap == null ? AppColors.textMuted : AppColors.text,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textDisabled,
              size: 20,
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
  List<({T value, String label})> options,
) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) {
    final isMovieChooser = title == 'Chọn phim';
    final icon = isMovieChooser
        ? Icons.movie_outlined
        : Icons.checklist_rounded;
    final availability = isMovieChooser ? 'phim khả dụng' : 'lựa chọn khả dụng';
    final maxHeight = MediaQuery.sizeOf(context).height * .72;

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
            const Divider(height: 1),
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                itemCount: options.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final option = options[index];
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

String _dateLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
