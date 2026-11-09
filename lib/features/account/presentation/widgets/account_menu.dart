import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

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
    this.detailLabel,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color iconColor;
  final String? trailing;
  final String? status;
  final String? detailLabel;
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
            if (item.detailLabel != null) ...[
              Text(
                item.detailLabel!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w800,
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
