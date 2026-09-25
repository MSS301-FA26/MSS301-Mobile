import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/cinema_info_sheet.dart';
import '../models/mock_user_profile.dart';
import '../widgets/account_menu.dart';
import '../widgets/account_profile_card.dart';
import '../widgets/membership_card.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = mockUserProfile;
    return AppShell(
      currentIndex: 4,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AccountProfileCard(user: user),
          const SizedBox(height: AppSpacing.md),
          MembershipCard(user: user, onQr: null),
          const SizedBox(height: AppSpacing.md),
          WalletTile(user: user, onManage: null),
          const SizedBox(height: AppSpacing.md),
          AccountMenu(
            items: [
              AccountMenuItemData(
                icon: Icons.confirmation_number_outlined,
                label: 'Vé xem phim của tôi',
                onTap: () => context.go(AppRoutes.orders),
              ),
              AccountMenuItemData(
                icon: Icons.smart_toy_outlined,
                label: 'Trợ lý điện ảnh PopBot AI',
                iconColor: AppColors.lavender,
                status: 'Sắp có',
              ),
              AccountMenuItemData(
                icon: Icons.local_activity_outlined,
                label: 'Ưu đãi & Voucher cá nhân',
                status: 'Sắp có',
              ),
              AccountMenuItemData(
                icon: Icons.apartment_rounded,
                label: 'Thông tin rạp',
                iconColor: AppColors.textMuted,
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  backgroundColor: AppColors.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadii.card,
                  ),
                  builder: (context) => const CinemaInfoSheet(),
                ),
              ),
              AccountMenuItemData(
                icon: Icons.support_agent_rounded,
                label: 'Trung tâm trợ giúp & CSKH',
                iconColor: AppColors.textMuted,
                status: 'Sắp có',
              ),
            ],
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
