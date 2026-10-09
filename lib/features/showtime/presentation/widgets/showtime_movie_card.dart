import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/age_badge.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../../../movie/presentation/models/movie.dart';
import '../models/showtime_models.dart';
import 'showtime_slot_button.dart';

class ShowtimeMovieCard extends StatelessWidget {
  const ShowtimeMovieCard({
    super.key,
    required this.movie,
    required this.rooms,
    required this.selectedSlotId,
    required this.onSlotSelected,
  });

  final Movie movie;
  final List<ShowtimeRoom> rooms;
  final int? selectedSlotId;
  final ValueChanged<ShowtimeSlot>? onSlotSelected;

  @override
  Widget build(BuildContext context) => AppSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: AppSpacing.headerHeight,
              child: AppImage(
                asset: movie.posterAsset,
                aspectRatio: AppSizes.posterAspectRatio,
                semanticLabel: 'Poster ${movie.title}',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xxs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AgeBadge(rating: movie.ageRating),
                      Text(movie.duration, style: AppTextStyles.caption),
                      if (movie.rating > 0)
                        Text(
                          '★ ${movie.rating.toStringAsFixed(1)}/10',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.gold,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Semantics(
                    header: true,
                    child: Text(movie.title, style: AppTextStyles.cardTitle),
                  ),
                  if (movie.genre.isNotEmpty &&
                      movie.genre != 'Đang cập nhật') ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(movie.genre, style: AppTextStyles.caption),
                  ],
                ],
              ),
            ),
          ],
        ),
        for (final room in rooms) ...[
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          _RoomSection(
            room: room,
            selectedSlotId: selectedSlotId,
            onSlotSelected: onSlotSelected,
          ),
        ],
      ],
    ),
  );
}

class _RoomSection extends StatelessWidget {
  const _RoomSection({
    required this.room,
    required this.selectedSlotId,
    required this.onSlotSelected,
  });

  final ShowtimeRoom room;
  final int? selectedSlotId;
  final ValueChanged<ShowtimeSlot>? onSlotSelected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (room.cinemaName?.trim().isNotEmpty ?? false) ...[
        Row(
          key: ValueKey('showtime-cinema-${room.cinemaId}-room-${room.id}'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: AppSizes.iconSmall,
              color: AppColors.gold,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Expanded(
              child: Text(
                room.cinemaName!,
                style: AppTextStyles.emphasis.copyWith(color: AppColors.gold),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
      ],
      Text(room.name, style: AppTextStyles.emphasis),
      if (room.formatBadge.isNotEmpty || room.screenDetail.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.xxs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xxs,
          children: [
            if (room.formatBadge.isNotEmpty) AppChip(label: room.formatBadge),
            if (room.screenDetail.isNotEmpty)
              Text(room.screenDetail, style: AppTextStyles.caption),
          ],
        ),
      ],
      const SizedBox(height: AppSpacing.sm),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = (constraints.maxWidth / 144).floor().clamp(2, 4);
          final slotWidth =
              (constraints.maxWidth - AppSpacing.xs * (columns - 1)) / columns;
          return Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final slot in room.slots)
                SizedBox(
                  width: slotWidth,
                  child: ShowtimeSlotButton(
                    slot: slot,
                    selected: selectedSlotId == slot.id,
                    onTap: !slot.isBookable || onSlotSelected == null
                        ? null
                        : () => onSlotSelected!(slot),
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}
