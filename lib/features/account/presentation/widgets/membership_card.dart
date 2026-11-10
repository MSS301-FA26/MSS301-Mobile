import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../models/account_summary.dart';

class MembershipCard extends StatelessWidget {
  const MembershipCard({
    super.key,
    required this.user,
    required this.onQr,
    this.onRetry,
    this.refreshing = false,
  });
  final AccountSummary user;
  final VoidCallback? onQr, onRetry;
  final bool refreshing;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surfaceRaised,
      borderRadius: AppRadii.card,
      border: Border.all(color: AppColors.goldBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(Icons.stars_rounded, color: AppColors.gold, size: 22),
            Text(
              user.membershipTier,
              style: AppTextStyles.cardTitle.copyWith(color: AppColors.gold),
            ),
            if (onQr != null)
              TextButton.icon(
                onPressed: onQr,
                icon: const Icon(Icons.qr_code_rounded),
                label: const Text('Mã VIP'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Điểm CinePoints', style: AppTextStyles.caption),
        const SizedBox(height: 4),
        Text(
          user.points == null
              ? refreshing
                    ? 'Đang tải điểm…'
                    : 'Chưa tải được điểm'
              : _formatNumber(user.points!),
          key: const ValueKey('account-points-value'),
          style: AppTextStyles.sectionTitle.copyWith(
            color: AppColors.gold,
            fontSize: user.points == null ? 16 : 28,
          ),
        ),
        if (user.points == null && !refreshing)
          TextButton.icon(
            key: const ValueKey('account-points-retry'),
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textMuted,
              minimumSize: const Size(48, 48),
            ),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Thử lại điểm'),
          ),
        const SizedBox(height: 10),
        Text('Mã hội viên: ${user.memberCode}', style: AppTextStyles.caption),
      ],
    ),
  );
}

String _formatNumber(int value) => value.toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
  (match) => '${match[1]}.',
);
