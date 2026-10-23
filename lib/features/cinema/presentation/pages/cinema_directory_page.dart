import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../../movie/data/models/cinema_dto.dart';
import '../../application/cinema_preferences.dart';
import '../providers/cinema_providers.dart';

class CinemaDirectoryPage extends ConsumerStatefulWidget {
  const CinemaDirectoryPage({super.key});

  @override
  ConsumerState<CinemaDirectoryPage> createState() =>
      _CinemaDirectoryPageState();
}

class _CinemaDirectoryPageState extends ConsumerState<CinemaDirectoryPage> {
  String _search = '';
  String? _cityKey;

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(homeCinemasProvider);
    final preferredId = ref.watch(preferredCinemaProvider).value;
    final cinemas = result.value ?? const <CinemaDto>[];
    final cityLabels = <String, String>{};
    for (final cinema in cinemas) {
      final label = cinema.city.trim();
      if (label.isNotEmpty) {
        cityLabels.putIfAbsent(normalizedCinemaCity(label), () => label);
      }
    }
    final cities = cityLabels.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final selectedCityKey = cityLabels.containsKey(_cityKey) ? _cityKey : null;
    final keyword = normalizedCinemaSearch(_search);
    final visible =
        cinemas.where((cinema) {
          if (selectedCityKey != null &&
              normalizedCinemaCity(cinema.city) != selectedCityKey) {
            return false;
          }
          return keyword.isEmpty ||
              normalizedCinemaSearch(
                '${cinema.name} ${cinema.address} ${cinema.city}',
              ).contains(keyword);
        }).toList()..sort((a, b) {
          final result = a.name.compareTo(b.name);
          return result == 0 ? a.id.compareTo(b.id) : result;
        });

    return AppShell(
      currentIndex: 2,
      showBottomNavigation: false,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Quay lại',
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go(AppRoutes.home),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text(
                    'Hệ thống rạp',
                    style: AppTextStyles.sectionTitle,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              key: const ValueKey('cinema-search'),
              onChanged: (value) => setState(() => _search = value),
              decoration: const InputDecoration(
                hintText: 'Tìm tên rạp hoặc địa chỉ',
                prefixIcon: Icon(Icons.search_rounded),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (cities.isNotEmpty)
            SizedBox(
              height: 58,
              child: ListView(
                key: const ValueKey('cinema-city-filters'),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final entry in [
                    const MapEntry<String?, String>(null, 'Tất cả'),
                    ...cities.map(
                      (entry) =>
                          MapEntry<String?, String>(entry.key, entry.value),
                    ),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(entry.value),
                        selected: selectedCityKey == entry.key,
                        showCheckmark: false,
                        selectedColor: AppColors.gold,
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.borderStrong),
                        labelStyle: AppTextStyles.label.copyWith(
                          color: selectedCityKey == entry.key
                              ? AppColors.background
                              : AppColors.text,
                        ),
                        onSelected: (_) => setState(() => _cityKey = entry.key),
                      ),
                    ),
                ],
              ),
            ),
          if (result.hasError && result.hasValue)
            RepositoryStatePane.error(
              compact: true,
              title: 'Danh sách rạp chưa được cập nhật',
              onRetry: () => ref.invalidate(homeCinemasProvider),
            ),
          Expanded(
            child: result.isLoading && !result.hasValue
                ? const RepositoryStatePane.loading()
                : result.hasError && !result.hasValue
                ? RepositoryStatePane.error(
                    title: 'Chưa tải được danh sách rạp',
                    onRetry: () => ref.invalidate(homeCinemasProvider),
                  )
                : visible.isEmpty
                ? RepositoryStatePane.empty(
                    title: cinemas.isEmpty
                        ? 'Chưa có rạp khả dụng'
                        : 'Không tìm thấy rạp phù hợp',
                  )
                : RefreshIndicator(
                    onRefresh: () async =>
                        ref.refresh(homeCinemasProvider.future),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final cinema = visible[index];
                        return Card(
                          child: InkWell(
                            key: ValueKey('cinema-card-${cinema.id}'),
                            borderRadius: AppRadii.card,
                            onTap: () =>
                                context.push(AppRoutes.cinemaDetail(cinema.id)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.movie_outlined,
                                        color: AppColors.gold,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          cinema.name,
                                          style: AppTextStyles.cardTitle,
                                        ),
                                      ),
                                      if (preferredId == cinema.id)
                                        const Icon(
                                          Icons.star_rounded,
                                          color: AppColors.gold,
                                        ),
                                    ],
                                  ),
                                  if (cinema.address.trim().isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      cinema.address,
                                      style: AppTextStyles.body,
                                    ),
                                  ],
                                  if (cinema.city.trim().isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      cinema.city,
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    'Xem rạp và lịch chiếu',
                                    style: AppTextStyles.label.copyWith(
                                      color: AppColors.gold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
