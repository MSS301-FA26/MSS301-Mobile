import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class ShowtimeFilterPanel extends StatelessWidget {
  const ShowtimeFilterPanel({
    super.key,
    required this.movie,
    required this.cinema,
    required this.date,
    required this.movieSelected,
    required this.cinemaSelected,
    required this.dateSelected,
    required this.onMovieTap,
    required this.onCinemaTap,
    required this.onDateTap,
    required this.onClearMovie,
    required this.onClearCinema,
    required this.onClearDate,
    required this.onClearAll,
  });

  final String movie;
  final String cinema;
  final String date;
  final bool movieSelected;
  final bool cinemaSelected;
  final bool dateSelected;
  final VoidCallback? onMovieTap;
  final VoidCallback? onCinemaTap;
  final VoidCallback onDateTap;
  final VoidCallback onClearMovie;
  final VoidCallback onClearCinema;
  final VoidCallback onClearDate;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final activeCount = [
      movieSelected,
      cinemaSelected,
      dateSelected,
    ].where((selected) => selected).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.borderStrong),
          borderRadius: AppRadii.large,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 0, AppSpacing.sm),
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    const Icon(
                      Icons.tune_rounded,
                      color: AppColors.gold,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'BỘ LỌC',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.meta.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .7,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 108,
                      child: activeCount == 0
                          ? const SizedBox.shrink()
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: AppColors.goldSurface,
                                    borderRadius: AppRadii.pill,
                                  ),
                                  child: Text(
                                    '$activeCount',
                                    style: AppTextStyles.meta.copyWith(
                                      color: AppColors.gold,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Semantics(
                                    button: true,
                                    label: 'Đặt lại bộ lọc',
                                    child: InkWell(
                                      key: const ValueKey('showtime-clear-all'),
                                      onTap: onClearAll,
                                      borderRadius: AppRadii.small,
                                      child: SizedBox(
                                        height: 48,
                                        child: Center(
                                          child: Text(
                                            'Đặt lại',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.label.copyWith(
                                              color: AppColors.gold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
            _FilterField(
              key: const ValueKey('showtime-filter-movie'),
              label: 'PHIM',
              value: movie,
              icon: Icons.movie_outlined,
              selected: movieSelected,
              onTap: onMovieTap,
              clearKey: 'showtime-movie-filter',
              onClear: onClearMovie,
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: _FilterField(
                    key: const ValueKey('showtime-filter-cinema'),
                    label: 'RẠP',
                    value: cinema,
                    icon: Icons.location_on_outlined,
                    selected: cinemaSelected,
                    onTap: onCinemaTap,
                    clearKey: 'showtime-cinema-filter',
                    onClear: onClearCinema,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _FilterField(
                    key: const ValueKey('showtime-filter-date'),
                    label: 'NGÀY',
                    value: date,
                    icon: Icons.calendar_month_outlined,
                    selected: dateSelected,
                    onTap: onDateTap,
                    clearKey: 'showtime-date-filter',
                    onClear: onClearDate,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterField extends StatelessWidget {
  const _FilterField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.clearKey,
    required this.onClear,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  final String clearKey;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Material(
      color: selected ? AppColors.goldSurface : AppColors.surfaceRaised,
      borderRadius: AppRadii.medium,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.medium,
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: AppRadii.medium,
            border: Border.all(
              color: selected ? AppColors.goldBorder : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              if (constraints.maxWidth >= 150) ...[
                Icon(
                  icon,
                  size: 19,
                  color: selected ? AppColors.gold : AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.meta.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                IconButton(
                  key: ValueKey(clearKey),
                  tooltip: 'Bỏ lọc ${label.toLowerCase()}',
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: AppColors.textSecondary,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  padding: EdgeInsets.zero,
                )
              else
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: AppColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
