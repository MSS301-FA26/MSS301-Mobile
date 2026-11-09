import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
import '../../../cinema/presentation/providers/cinema_providers.dart';
import '../../../movie/data/models/cinema_dto.dart';
import '../../../cinema/application/cinema_preferences.dart';
import '../providers/home_providers.dart';
import 'home_section_heading.dart';

class HomeCinemasSection extends ConsumerStatefulWidget {
  const HomeCinemasSection({super.key});
  @override
  ConsumerState<HomeCinemasSection> createState() => _HomeCinemasSectionState();
}

class _HomeCinemasSectionState extends ConsumerState<HomeCinemasSection> {
  String? _city;

  void _open(CinemaDto cinema) =>
      context.push(AppRoutes.cinemaDetail(cinema.id));

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeCinemasProvider);
    final preferredId = ref.watch(preferredCinemaProvider).value;
    final cinemas = (state.value ?? <CinemaDto>[])
        .where((c) => c.active)
        .toList();
    final cityLabels = <String, String>{};
    for (final cinema in cinemas) {
      if (cinema.city.trim().isNotEmpty) {
        cityLabels.putIfAbsent(
          normalizedCinemaCity(cinema.city),
          () => cinema.city,
        );
      }
    }
    final cities = cityLabels.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final selectedCity = cityLabels.containsKey(_city) ? _city : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionHeading(
          eyebrow: 'KHÔNG GIAN ĐIỆN ẢNH',
          title: 'RẠP CINEPREMIER',
          subtitle: 'Tìm kiếm cụm rạp phù hợp nhất với trải nghiệm của bạn',
          action: 'Xem tất cả',
          onAction: () => context.push(AppRoutes.cinemas),
        ),
        if (state.isLoading)
          const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state.hasError)
          RepositoryStatePane.error(
            onRetry: () => ref.invalidate(homeCinemasProvider),
            compact: true,
          )
        else if (cinemas.isEmpty)
          const RepositoryStatePane.empty(
            title: 'Chưa có rạp khả dụng',
            compact: true,
          )
        else ...[
          if (cities.isNotEmpty)
            SingleChildScrollView(
              key: const ValueKey('home-cinema-filters'),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (final city in [
                    const MapEntry<String?, String>(null, 'Tất cả'),
                    ...cities.map(
                      (entry) =>
                          MapEntry<String?, String>(entry.key, entry.value),
                    ),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(city.value, maxLines: 1),
                        selected: city.key == selectedCity,
                        showCheckmark: false,
                        selectedColor: AppColors.gold,
                        backgroundColor: AppColors.surface,
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        side: const BorderSide(color: AppColors.borderStrong),
                        labelStyle: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: city.key == selectedCity
                                  ? AppColors.background
                                  : AppColors.text,
                            ),
                        padding: const EdgeInsets.all(8),
                        onSelected: (_) => setState(() => _city = city.key),
                      ),
                    ),
                ],
              ),
            ),
          for (final cinema
              in cinemas
                  .where(
                    (c) =>
                        selectedCity == null ||
                        normalizedCinemaCity(c.city) == selectedCity,
                  )
                  .take(3))
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
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cinema.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.cardTitle.copyWith(
                            color: AppColors.gold,
                          ),
                        ),
                        if (preferredId == cinema.id)
                          const Text(
                            '★ Rạp ưu tiên',
                            style: AppTextStyles.caption,
                          ),
                        if (cinema.city.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            cinema.city,
                            style: AppTextStyles.body,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (cinema.address.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            cinema.address,
                            style: AppTextStyles.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
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
                                'XEM RẠP & LỊCH CHIẾU',
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
