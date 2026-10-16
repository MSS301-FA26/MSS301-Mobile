import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../models/account_summary.dart';
import 'profile_avatar.dart';

class AccountProfileCard extends StatelessWidget {
  const AccountProfileCard({super.key, required this.user});
  final AccountSummary user;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surfaceRaised,
      borderRadius: AppRadii.card,
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 52,
              height: 52,
              child: user.avatarUrl?.trim().isNotEmpty == true
                  ? ProfileAvatar(url: user.avatarUrl, radius: 26)
                  : CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.goldSurface,
                      child: Text(
                        user.initials,
                        style: AppTextStyles.cardTitle.copyWith(
                          color: AppColors.gold,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: AppTextStyles.cardTitle.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Thành viên từ ${user.joinYear}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
