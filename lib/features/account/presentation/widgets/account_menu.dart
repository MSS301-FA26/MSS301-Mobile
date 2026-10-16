import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../models/account_summary.dart';

class WalletTile extends StatelessWidget {
  const WalletTile({
    super.key,
    required this.user,
    required this.onManage,
    this.onRetry,
    this.refreshing = false,
  });

  final AccountSummary user;
  final VoidCallback? onManage;
  final VoidCallback? onRetry;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.gold,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text('CineWallet', style: AppTextStyles.cardTitle),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            user.walletBalance?.format() ??
                (refreshing ? 'Đang tải số dư…' : 'Chưa tải được số dư'),
            key: const ValueKey('account-wallet-value'),
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              TextButton(
                onPressed: onManage,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.text,
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadii.control,
                  ),
                ),
                child: Text(
                  onManage == null ? 'Sắp có' : 'Quản lý ví',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
              if (user.walletBalance == null && !refreshing)
                TextButton.icon(
                  key: const ValueKey('account-wallet-retry'),
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                    minimumSize: const Size(48, 48),
                  ),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Thử lại số dư'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class AccountMenu extends StatelessWidget {
  const AccountMenu({super.key, required this.items});

  final List<AccountMenuItemData> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: AppRadii.card,
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              AccountMenuRow(item: items[i]),
              if (i < items.length - 1)
                const Divider(height: 1, color: AppColors.border),
            ],
          ],
        ),
      ),
    );
  }
}

class AccountMenuItemData {
  const AccountMenuItemData({
    required this.icon,
    required this.label,
    this.onTap,
    this.iconColor = AppColors.gold,
    this.trailing,
    this.status,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color iconColor;
  final String? trailing;
  final String? status;
}

class AccountMenuRow extends StatelessWidget {
  const AccountMenuRow({super.key, required this.item});

  final AccountMenuItemData item;

  @override
  Widget build(BuildContext context) {
    final enabled = item.onTap != null;
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 21,
              color: enabled ? item.iconColor : AppColors.textDisabled,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      color: enabled ? AppColors.text : AppColors.textDisabled,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (item.trailing != null)
                    Text(
                      item.trailing!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.gold,
                      ),
                    ),
                  if (item.status != null)
                    Text(item.status!, style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textDisabled,
            ),
          ],
        ),
      ),
    );
  }
}
