import 'dart:math' as math;

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
    required this.now,
  });
  final Movie movie;
  final List<ShowtimeRoom> rooms;
  final int? selectedSlotId;
  final ValueChanged<ShowtimeSlot>? onSlotSelected;
  final DateTime now;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadii.card,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: AppRadii.small,
              child: SizedBox(
                width: 56,
                height: 84,
                child: AppImage(asset: movie.posterAsset),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (movie.ageRating.isNotEmpty)
                        AgeBadge(rating: movie.ageRating),
                      if (movie.rating != null)
                        Text(
                          '★ ${movie.rating!.toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                  movie.title.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardTitle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${movie.duration} · ${movie.genre}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
        for (final room in rooms) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                room.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (room.formatBadge.isNotEmpty)
                Text(
                  room.formatBadge,
                  style: const TextStyle(color: AppColors.gold, fontSize: 12),
                ),
              if (room.screenDetail.isNotEmpty)
                Text(room.screenDetail, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final minimumWidth =
                  104 *
                  math.max(
                    1.0,
                    MediaQuery.textScalerOf(context).scale(14) / 14,
                  );
              final columns = math.max(
                1,
                ((constraints.maxWidth + 8) / (minimumWidth + 8)).floor(),
              );
              final width =
                  (constraints.maxWidth - (columns - 1) * 8) / columns;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final slot in room.slots)
                    SizedBox(
                      width: width,
                      child: _SlotPill(
                        slot: slot,
                        now: now,
                        selected:
                            selectedSlotId == slot.id && slot.isBookableAt(now),
                        onTap: !slot.isBookableAt(now) || onSlotSelected == null
                            ? null
                            : () => onSlotSelected!(slot),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ],
    ),
  );
}

class _SlotPill extends StatelessWidget {
  const _SlotPill({
    required this.slot,
    required this.now,
    required this.selected,
    required this.onTap,
  });
  final ShowtimeSlot slot;
  final DateTime now;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final reason = slot.unavailableReason(now);
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      child: Material(
        color: selected ? AppColors.goldSurface : AppColors.surfaceRaised,
        borderRadius: AppRadii.control,
        child: InkWell(
          key: ValueKey('showtime-slot-${slot.id}'),
          onTap: onTap,
          borderRadius: AppRadii.control,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: AppRadii.control,
              border: Border.all(
                color: selected ? AppColors.gold : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  slot.time,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: reason == null
                        ? AppColors.text
                        : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(slot.endTime, style: AppTextStyles.caption),
                const SizedBox(height: 4),
                Text(
                  reason ?? slot.priceDisplay,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: reason == null
                        ? AppColors.gold
                        : AppColors.textSecondary,
                  ),
                ),
                if (selected)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      '✓ Đã chọn',
                      style: TextStyle(fontSize: 12, color: AppColors.gold),
                    ),
                  ),
                if (reason == null && onTap == null)
                  const Text(
                    'Cần tải lại',
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
