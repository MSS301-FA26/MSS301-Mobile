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
  final _searchController = TextEditingController();
  String _search = '';
  String? _cityKey;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
            padding: const EdgeInsets.fromLTRB(12, 12, 16, 10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 10, 12, 10),
              decoration: BoxDecoration(
                borderRadius: AppRadii.medium,
                gradient: LinearGradient(
                  colors: [
                    AppColors.gold.withValues(alpha: 0.14),
                    AppColors.surfaceRaised.withValues(alpha: 0.75),
                  ],
                ),
                border: Border.all(color: AppColors.goldBorder),
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Quay lại',
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(AppRoutes.home),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: AppRadii.small,
                    ),
                    child: const Icon(
                      Icons.theaters_rounded,
                      color: AppColors.background,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HỆ THỐNG RẠP',
                          style: AppTextStyles.sectionTitle,
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Tìm rạp và lịch chiếu gần bạn',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              key: const ValueKey('cinema-search'),
              controller: _searchController,
              onChanged: (value) => setState(() => _search = value),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên rạp, quận hoặc thành phố',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Xóa tìm kiếm',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
              ),
            ),
          ),
          if (cities.isNotEmpty)
            SizedBox(
              height: 56,
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
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final cinema = visible[index];
                        return _CinemaCard(
                          key: ValueKey('cinema-card-${cinema.id}'),
                          cinema: cinema,
                          isPreferred: preferredId == cinema.id,
                          onTap: () =>
                              context.push(AppRoutes.cinemaDetail(cinema.id)),
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

class _CinemaCard extends StatelessWidget {
  const _CinemaCard({
    super.key,
    required this.cinema,
    required this.isPreferred,
    required this.onTap,
  });

  final CinemaDto cinema;
  final bool isPreferred;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.card,
        side: BorderSide(
          color: isPreferred ? AppColors.goldBorder : AppColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: AppColors.goldSurface,
                  borderRadius: AppRadii.medium,
                ),
                child: const Icon(
                  Icons.theaters_rounded,
                  color: AppColors.gold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            cinema.name,
                            style: AppTextStyles.cardTitle.copyWith(
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (isPreferred)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: const BoxDecoration(
                              color: AppColors.goldSurface,
                              borderRadius: AppRadii.pill,
                            ),
                            child: Text(
                              'RẠP ƯU TIÊN',
                              style: AppTextStyles.meta.copyWith(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (cinema.address.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 17,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              cinema.address,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (cinema.city.trim().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceRaised,
                              borderRadius: AppRadii.pill,
                            ),
                            child: Text(
                              cinema.city,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        const Spacer(),
                        Text(
                          'Xem lịch chiếu',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.gold,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: AppColors.gold,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
