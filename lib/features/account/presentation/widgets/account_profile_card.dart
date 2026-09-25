import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../models/account_summary.dart';

class AccountProfileCard extends StatelessWidget {
  const AccountProfileCard({super.key, required this.user});

  final AccountSummary user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.goldSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold, width: 2),
                ),
                child: Text(
                  user.initials,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Positioned(
                right: -2,
                bottom: -2,
                child: CircleAvatar(
                  radius: 11,
                  backgroundColor: AppColors.gold,
                  child: Icon(
                    Icons.stars_rounded,
                    size: 14,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.goldSurface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.goldBorder),
                      ),
                      child: Text(
                        user.membershipTier.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 4),
                Text(
                  'Thành viên CinePremier từ ${user.joinYear}',
                  style: const TextStyle(
                    color: AppColors.textDisabled,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
