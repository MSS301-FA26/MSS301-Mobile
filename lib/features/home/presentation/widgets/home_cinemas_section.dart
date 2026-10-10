import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
import '../../../movie/data/models/cinema_dto.dart';
import '../../../movie/presentation/providers/movies_provider.dart';
import '../../../showtime/presentation/providers/showtimes_provider.dart';
import '../providers/home_providers.dart';
import 'home_quick_booking.dart';
import 'home_section_heading.dart';

class HomeCinemasSection extends ConsumerStatefulWidget {
  const HomeCinemasSection({super.key, required this.onBook});
  final ValueChanged<int> onBook;
  @override
  ConsumerState<HomeCinemasSection> createState() => _HomeCinemasSectionState();
}

class _HomeCinemasSectionState extends ConsumerState<HomeCinemasSection> {
  String? _city;

  void _open(CinemaDto cinema) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => HomeCinemaSchedule(
      cinema: cinema,
      onBook: (id) {
        Navigator.of(context).pop();
        widget.onBook(id);
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeCinemasProvider);
    final cinemas = (state.value ?? <CinemaDto>[])
        .where((c) => c.active)
        .take(20)
        .toList();
    final cities =
        cinemas
            .map((c) => c.city)
            .where((c) => c.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final selectedCity = cities.contains(_city) ? _city : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionHeading(
          eyebrow: 'KHÔNG GIAN ĐIỆN ẢNH',
          title: 'RẠP CINEPREMIER',
          subtitle: 'Tìm kiếm cụm rạp phù hợp nhất với trải nghiệm của bạn',
          action: 'XEM LỊCH CHIẾU THEO RẠP',
          onAction: state.hasError || state.isLoading || cinemas.isEmpty
              ? null
              : () async {
                  final id = await homeChoose<int>(context, 'Chọn rạp', [
                    for (final c in cinemas) (value: c.id, label: c.name),
                  ]);
                  if (!mounted || id == null) return;
                  _open(cinemas.firstWhere((c) => c.id == id));
                },
        ),
        if (state.isLoading)
          const RepositoryStatePane.loading()
        else if (state.hasError)
          RepositoryStatePane.error(
            onRetry: () => ref.invalidate(homeCinemasProvider),
          )
        else if (cinemas.isEmpty)
          const RepositoryStatePane.empty(title: 'Chưa có rạp khả dụng')
        else ...[
          if (cities.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final city in [null, ...cities])
                    ChoiceChip(
                      label: Text(city ?? 'Tất cả khu vực'),
                      selected: city == selectedCity,
                      showCheckmark: false,
                      labelStyle: AppTextStyles.label.copyWith(
                        color: city == selectedCity
                            ? AppColors.background
                            : AppColors.text,
                      ),
                      padding: const EdgeInsets.all(12),
                      onSelected: (_) => setState(() => _city = city),
                    ),
                ],
              ),
            ),
          for (final cinema in cinemas.where(
            (c) => selectedCity == null || c.city == selectedCity,
          ))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Material(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: AppColors.borderStrong),
                  borderRadius: AppRadii.small,
                ),
                child: InkWell(
                  key: ValueKey('home-cinema-${cinema.id}'),
                  onTap: () => _open(cinema),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cinema.name,
                          style: AppTextStyles.cardTitle.copyWith(
                            color: AppColors.gold,
                          ),
                        ),
                        if (cinema.city.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(cinema.city, style: AppTextStyles.label),
                        ],
                        if (cinema.address.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(cinema.address, style: AppTextStyles.body),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.confirmation_number_outlined,
                              color: AppColors.gold,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'XEM LỊCH CHIẾU',
                                style: AppTextStyles.label.copyWith(
                                  color: AppColors.gold,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward,
                              color: AppColors.gold,
                              size: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class HomeCinemaSchedule extends ConsumerWidget {
  const HomeCinemaSchedule({
    super.key,
    required this.cinema,
    required this.onBook,
  });
  final CinemaDto cinema;
  final ValueChanged<int> onBook;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const query = ShowtimeQuery();
    final state = ref.watch(showtimesProvider(query));
    final movies = ref.watch(moviesProvider);
    final entries = [
      for (final film in state.value ?? [])
        for (final room in film.rooms)
          if (room.cinemaId == cinema.id)
            for (final slot in room.slots)
              (movieId: film.movieId, room: room, slot: slot),
    ]..sort((a, b) => a.slot.startAt.compareTo(b.slot.startAt));
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(cinema.name, style: AppTextStyles.sectionTitle),
            ),
            Expanded(
              child: state.isLoading || movies.isLoading
                  ? const RepositoryStatePane.loading()
                  : state.hasError || movies.hasError
                  ? RepositoryStatePane.error(
                      onRetry: () {
                        ref.invalidate(showtimesProvider(query));
                        ref.invalidate(moviesProvider);
                      },
                    )
                  : entries.isEmpty
                  ? const RepositoryStatePane.empty(
                      title: 'Chưa có lịch chiếu tại rạp này',
                    )
                  : ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const Divider(),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final movie = movies.requireValue
                            .where((m) => m.id == entry.movieId)
                            .firstOrNull;
                        return ListTile(
                          key: ValueKey('home-cinema-slot-${entry.slot.id}'),
                          minTileHeight: 64,
                          title: Text(movie?.title ?? 'Phim #${entry.movieId}'),
                          subtitle: Text(
                            '${entry.slot.startAt.day}/${entry.slot.startAt.month} • ${entry.slot.time} • ${entry.room.name}',
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward,
                            color: AppColors.gold,
                          ),
                          onTap: entry.slot.isBookable
                              ? () => onBook(entry.slot.id)
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
