import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/age_badge.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../movie/presentation/models/movie.dart';
import '../models/showtime_models.dart';

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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: AppRadii.small,
                child: SizedBox(
                  width: 56,
                  height: 80,
                  child: AppImage(asset: movie.posterAsset),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AgeBadge(
                          rating: movie.ageRating,
                          variant: AgeBadgeVariant.hero,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          movie.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      movie.title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${movie.genre} • ${movie.duration}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          for (final room in rooms) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, color: AppColors.border),
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
  Widget build(BuildContext context) {
    final isImax = room.formatBadge.contains('IMAX');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              room.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isImax
                    ? AppColors.purple.withValues(alpha: 0.3)
                    : AppColors.goldSurface,
                borderRadius: AppRadii.small,
                border: Border.all(
                  color: isImax
                      ? AppColors.purple.withValues(alpha: 0.35)
                      : AppColors.goldBorder,
                ),
              ),
              child: Text(
                room.formatBadge,
                style: TextStyle(
                  color: isImax ? AppColors.lavender : AppColors.gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              room.screenDetail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: room.slots.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: AppSpacing.xs,
            mainAxisSpacing: AppSpacing.xs,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (context, index) {
            final slot = room.slots[index];
            return _SlotPill(
              slot: slot,
              selected: selectedSlotId == slot.id,
              onTap: slot.isSoldOut || onSlotSelected == null
                  ? null
                  : () => onSlotSelected!(slot),
            );
          },
        ),
      ],
    );
  }
}

class _SlotPill extends StatelessWidget {
  const _SlotPill({
    required this.slot,
    required this.selected,
    required this.onTap,
  });

  final ShowtimeSlot slot;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final soldOut = slot.isSoldOut;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.control,
      child: Opacity(
        opacity: soldOut ? 0.45 : 1,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceRaised : AppColors.background,
            borderRadius: AppRadii.control,
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (selected)
                const Positioned(
                  top: -13,
                  right: -13,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: AppColors.gold,
                    child: Icon(Icons.check, size: 11, color: Colors.black),
                  ),
                ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      slot.time,
                      style: TextStyle(
                        color: soldOut
                            ? AppColors.textDisabled
                            : AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        decoration: soldOut ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      slot.endTime,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      soldOut ? 'Hết chỗ' : slot.priceDisplay,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: soldOut ? AppColors.adultBadge : AppColors.gold,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
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
