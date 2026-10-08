import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class CinemaStatusCard extends StatelessWidget {
  const CinemaStatusCard({super.key, required this.onInfo});

  final VoidCallback onInfo;

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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'CineAI Central',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.text,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    SizedBox(width: 6),
                    _OpenBadge(),
                  ],
                ),
                SizedBox(height: 3),
                Text(
                  'Tầng 5, 1 Nguyễn Huệ, P. Bến Nghé, Quận 1',
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

class _OpenBadge extends StatelessWidget {
  const _OpenBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.allAgesBadge.withValues(alpha: 0.14),
        borderRadius: AppRadii.small,
        border: Border.all(
          color: AppColors.allAgesBadge.withValues(alpha: 0.3),
        ),
      ),
      child: const Text(
        'Đang chiếu',
        style: TextStyle(
          color: AppColors.allAgesBadge,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
