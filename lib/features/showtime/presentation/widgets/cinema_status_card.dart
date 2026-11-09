import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../movie/data/models/cinema_dto.dart';

class CinemaStatusCard extends StatelessWidget {
  const CinemaStatusCard({
    super.key,
    required this.onInfo,
    this.cinema,
    this.cinemaId,
  });

  final VoidCallback onInfo;
  final CinemaDto? cinema;
  final int? cinemaId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              size: 20,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cinema?.name ??
                      (cinemaId == null ? 'Tất cả rạp' : 'Rạp #$cinemaId'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.text,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  cinema?.address.trim().isNotEmpty == true
                      ? cinema!.address
                      : cinemaId == null
                      ? 'Chọn rạp để xem lịch chiếu theo địa điểm'
                      : 'Đang xem lịch chiếu tại rạp này',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            tooltip: 'Thông tin rạp',
            onPressed: onInfo,
            icon: const Icon(Icons.info_outline_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}
