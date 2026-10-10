import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../models/account_summary.dart';

class WalletTile extends StatelessWidget {
  const WalletTile({super.key, required this.user, required this.onManage});

  final AccountSummary user;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) => AppSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.gold,
              size: AppSizes.iconLarge,
            ),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(
              child: Text('Số dư ví CineWallet', style: AppTextStyles.label),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(user.walletBalance.format(), style: AppTextStyles.price),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          key: const ValueKey('account-wallet-manage'),
          onPressed: onManage,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
            padding: const EdgeInsets.all(AppSpacing.sm),
          ),
          child: Text(
            onManage == null ? 'Sắp có' : 'Quản lý ví',
            textAlign: TextAlign.center,
            style: AppTextStyles.button.copyWith(
              fontFamily: Theme.of(context).textTheme.labelLarge?.fontFamily,
            ),
          ),
        ),
      ],
    ),
  );
}

class AccountMenu extends StatelessWidget {
  const AccountMenu({super.key, required this.items});

  final List<AccountMenuItemData> items;

  @override
  Widget build(BuildContext context) => AppSurface(
    padding: EdgeInsets.zero,
    child: ClipRRect(
      borderRadius: AppRadii.card,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              AccountMenuRow(item: items[i]),
              if (i < items.length - 1) const Divider(),
            ],
          ],
        ),
      ),
    ),
  );
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

class AccountMenuRow extends StatefulWidget {
  const AccountMenuRow({super.key, required this.item});

  final AccountMenuItemData item;

  @override
  State<AccountMenuRow> createState() => _AccountMenuRowState();
}

class _AccountMenuRowState extends State<AccountMenuRow> {
  var _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final enabled = item.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: InkWell(
        onTap: item.onTap,
        onFocusChange: (focused) => setState(() => _hasFocus = focused),
        focusColor: AppColors.goldSurface,
        hoverColor: AppColors.surfaceRaised,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadii.control,
            border: Border.all(
              color: _hasFocus ? AppColors.focus : Colors.transparent,
              width: 2,
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.buttonHeight),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: AppSizes.iconLarge,
                    color: enabled ? item.iconColor : AppColors.textMuted,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: AppTextStyles.emphasis.copyWith(
                            color: enabled
                                ? AppColors.text
                                : AppColors.textMuted,
                          ),
                        ),
                        if (item.trailing != null || item.status != null) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xxs,
                            children: [
                              if (item.trailing != null)
                                Text(
                                  item.trailing!,
                                  style: AppTextStyles.label.copyWith(
                                    color: AppColors.gold,
                                  ),
                                ),
                              if (item.status != null)
                                Text(
                                  item.status!,
                                  style: AppTextStyles.caption,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: AppSizes.iconMedium,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
