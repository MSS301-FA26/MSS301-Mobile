import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_image.dart';
import '../models/movie.dart';

/// Phase 2 modal shell. Playback is added with the movie flow in a later phase.
class TrailerPreviewDialog extends StatelessWidget {
  const TrailerPreviewDialog({super.key, required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    movie.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardTitle,
                  ),
                ),
                IconButton(
                  tooltip: 'Đóng',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: AppRadii.control,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppImage(asset: movie.bannerAsset ?? movie.posterAsset),
                    const Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        size: 56,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Bản xem trước trailer đang dùng nội dung mô phỏng.',
              style: AppTextStyles.body,
            ),
          ],
        ),
      ),
    );
  }
}
