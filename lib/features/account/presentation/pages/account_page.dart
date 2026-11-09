import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
import '../../../auth/application/auth_session.dart';
import '../providers/account_summary_provider.dart';
import '../../application/profile_controller.dart';
import '../models/account_summary.dart';
import '../widgets/account_menu.dart';
import '../widgets/account_profile_card.dart';
import '../widgets/membership_card.dart';

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    if (!session.isAuthenticated) {
      return AppShell(
        currentIndex: 4,
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const SizedBox(height: 48),
            const Icon(
              Icons.account_circle_outlined,
              size: 76,
              color: AppColors.gold,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Đăng nhập để quản lý vé và quyền lợi',
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Bạn vẫn có thể xem phim, thông tin rạp, chính sách và liên hệ CSKH khi chưa đăng nhập.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => context.go(AppRoutes.login),
              child: const Text('Đăng nhập'),
            ),
            OutlinedButton(
              onPressed: () => context.go(AppRoutes.register),
              child: const Text('Đăng ký'),
            ),
            const SizedBox(height: AppSpacing.lg),
            AccountMenu(
              items: [
                AccountMenuItemData(
                  icon: Icons.apartment_rounded,
                  label: 'Thông tin rạp',
                  onTap: () => context.push(AppRoutes.cinemas),
                ),
              ],
            ),
          ],
        ),
      );
    }
    final accountState = ref.watch(accountSummaryProvider);
    final profileState = accountState.hasValue
        ? null
        : ref.watch(currentProfileProvider);
    if (accountState.isLoading &&
        !accountState.hasValue &&
        profileState?.hasValue != true) {
      return const AppShell(
        currentIndex: 4,
        body: RepositoryStatePane.loading(
          layout: RepositorySkeleton.account,
          title: 'Đang tải tài khoản…',
        ),
      );
    }
    if (accountState.hasError &&
        !accountState.hasValue &&
        profileState?.hasValue != true) {
      return AppShell(
        currentIndex: 4,
        body: RepositoryStatePane.error(
          onRetry: () => ref.invalidate(accountSummaryProvider),
        ),
      );
    }
    final user =
        accountState.value ??
        mapAccountSummary(profileState!.requireValue, null, null);
    return AppShell(
      currentIndex: 4,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AccountProfileCard(user: user),
          if (accountState.hasError)
            RepositoryStatePane.error(
              compact: true,
              message: 'Chưa cập nhật được tài khoản. Thông tin đã tải vẫn được giữ lại.',
              onRetry: () => ref.invalidate(accountSummaryProvider),
            ),
          const SizedBox(height: AppSpacing.md),
          MembershipCard(
            user: user,
            onQr: null,
            refreshing: accountState.isLoading,
            onRetry: accountState.isLoading
                ? null
                : () => ref.invalidate(accountSummaryProvider),
          ),
          const SizedBox(height: AppSpacing.md),
          AccountMenu(
            items: [
              AccountMenuItemData(
                icon: Icons.account_balance_wallet_outlined,
                label: 'CineWallet',
                status:
                    'Số dư: ${user.walletBalance?.format() ?? (accountState.isLoading ? 'Đang tải…' : 'Chưa tải được')}',
                detailLabel: 'Chi tiết',
                onTap: () => context.go(AppRoutes.wallet),
              ),
              AccountMenuItemData(
                icon: Icons.person_outline_rounded,
                label: 'Hồ sơ cá nhân',
                onTap: () => context.go(AppRoutes.profile),
              ),
              if (FeatureFlags.popBotPreview)
                AccountMenuItemData(
                  icon: Icons.smart_toy_outlined,
                  label: 'Trợ lý điện ảnh PopBot AI',
                  iconColor: AppColors.lavender,
                  status: 'Preview',
                  onTap: () => context.go(AppRoutes.popBot),
                ),
              if (FeatureFlags.voucherPreview)
                AccountMenuItemData(
                  icon: Icons.local_activity_outlined,
                  label: 'Ưu đãi & Voucher cá nhân',
                  status: 'Preview',
                  onTap: () => context.go(AppRoutes.vouchers),
                ),
              if (FeatureFlags.vipPreview)
                AccountMenuItemData(
                  icon: Icons.workspace_premium_outlined,
                  label: 'CinePremier VIP',
                  status: 'Preview',
                  onTap: () => context.go(AppRoutes.vip),
                ),
              if (FeatureFlags.socialMoviePreview)
                AccountMenuItemData(
                  icon: Icons.notifications_none_rounded,
                  label: 'Thông báo',
                  status: 'Preview',
                  onTap: () => context.go(AppRoutes.notifications),
                ),
              if (FeatureFlags.independentFoodOrderPreview)
                AccountMenuItemData(
                  icon: Icons.fastfood_outlined,
                  label: 'Đặt bắp nước độc lập',
                  status: 'Preview',
                  onTap: () => context.go(AppRoutes.previewFood),
                ),
              AccountMenuItemData(
                icon: Icons.apartment_rounded,
                label: 'Thông tin rạp',
                iconColor: AppColors.textMuted,
                onTap: () => context.push(AppRoutes.cinemas),
              ),
              AccountMenuItemData(
                icon: Icons.logout_rounded,
                label: 'Đăng xuất',
                iconColor: AppColors.adultBadge,
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Đăng xuất?'),
                      content: const Text('Bạn có chắc muốn đăng xuất?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Không'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Đăng xuất'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    ref.read(authSessionProvider.notifier).signOut();
                  }
                },
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
