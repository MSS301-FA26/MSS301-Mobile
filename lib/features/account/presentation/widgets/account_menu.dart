import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../models/account_summary.dart';

class WalletTile extends StatelessWidget {
  const WalletTile({super.key, required this.user, required this.onManage});

  final AccountSummary user;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.goldSurface,
              borderRadius: AppRadii.control,
              border: Border.all(color: AppColors.goldBorder),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Số dư ví CineWallet', style: AppTextStyles.caption),
                const SizedBox(height: 3),
                Text(
                  user.walletBalance.format(),
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: onManage,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 38),
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
        color: AppColors.surface,
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
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: enabled ? AppColors.text : AppColors.textDisabled,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (item.trailing != null) ...[
              Text(
                item.trailing!,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
            ],
            if (item.status != null) ...[
              Text(
                item.status!,
                style: const TextStyle(
                  color: AppColors.textDisabled,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
            ],
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
