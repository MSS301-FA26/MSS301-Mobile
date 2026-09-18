import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../../shared/widgets/age_badge.dart';
import '../../../movie/presentation/models/movie.dart';

class ComingSoonCard extends StatelessWidget {
  const ComingSoonCard({
    super.key,
    required this.movie,
    required this.reminded,
    required this.onOpen,
    required this.onReminder,
  });
  final Movie movie;
  final bool reminded;
  final VoidCallback onOpen;
  final VoidCallback onReminder;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadii.card,
      child: InkWell(
        onTap: onOpen,
        borderRadius: AppRadii.card,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: AppRadii.card,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 96,
                height: 128,
                child: ClipRRect(
                  borderRadius: AppRadii.control,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppImage(asset: movie.posterAsset),
                      Positioned(
                        top: 4,
                        left: 4,
                        child: AgeBadge(rating: movie.ageRating),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 128,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.goldSurface,
                                border: Border.all(color: AppColors.goldBorder),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                movie.releaseDate ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.gold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        movie.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${movie.genre} • ${movie.duration}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: OutlinedButton.icon(
                          onPressed: onReminder,
                          icon: Icon(
                            reminded
                                ? Icons.check_circle
                                : Icons.notifications_active_outlined,
                            size: 15,
                          ),
                          label: Text(
                            reminded ? 'Đã bật nhắc' : 'Nhắc tôi mở bán',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: reminded
                                ? AppColors.gold
                                : AppColors.text,
                            backgroundColor: reminded
                                ? AppColors.goldSurface
                                : AppColors.surfaceRaised,
                            side: BorderSide(
                              color: reminded
                                  ? AppColors.gold
                                  : AppColors.border,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppRadii.small,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
