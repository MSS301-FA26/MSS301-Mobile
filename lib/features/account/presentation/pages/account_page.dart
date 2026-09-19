import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../models/mock_user_profile.dart';
import '../widgets/account_menu.dart';
import '../widgets/account_profile_card.dart';
import '../widgets/membership_card.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  void _showUnavailable(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature sẽ có trong giai đoạn tiếp theo.'),
        backgroundColor: AppColors.surfaceRaised,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = mockUserProfile;
    return AppShell(
      currentIndex: 4,
      onUnavailable: (feature) => _showUnavailable(context, feature),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AccountProfileCard(user: user),
          const SizedBox(height: AppSpacing.md),
          MembershipCard(
            user: user,
            onQr: () => _showUnavailable(context, 'Mã VIP'),
          ),
          const SizedBox(height: AppSpacing.md),
          WalletTile(
            user: user,
            onManage: () => _showUnavailable(context, 'CineWallet'),
          ),
          const SizedBox(height: AppSpacing.md),
          AccountMenu(
            items: [
              AccountMenuItemData(
                icon: Icons.confirmation_number_outlined,
                label: 'Vé xem phim của tôi',
                onTap: () => context.go('/orders'),
              ),
              AccountMenuItemData(
                icon: Icons.smart_toy_outlined,
                label: 'Trợ lý điện ảnh PopBot AI',
                iconColor: AppColors.lavender,
                onTap: () => _showUnavailable(context, 'PopBot AI'),
              ),
              AccountMenuItemData(
                icon: Icons.local_activity_outlined,
                label: 'Ưu đãi & Voucher cá nhân',
                trailing: '3 mã',
                onTap: () => _showUnavailable(context, 'Voucher cá nhân'),
              ),
              AccountMenuItemData(
                icon: Icons.apartment_rounded,
                label: 'Thông tin rạp',
                iconColor: AppColors.textMuted,
                onTap: () => _showUnavailable(context, 'Thông tin rạp'),
              ),
              AccountMenuItemData(
                icon: Icons.support_agent_rounded,
                label: 'Trung tâm trợ giúp & CSKH',
                iconColor: AppColors.textMuted,
                onTap: () => _showUnavailable(context, 'Trung tâm trợ giúp'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () => _showUnavailable(context, 'Đăng xuất'),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Đăng xuất tài khoản'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.border),
              minimumSize: const Size(double.infinity, 48),
              shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Phiên bản 3.4.0 • Bản quyền CinePremier & PopBot AI',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}
