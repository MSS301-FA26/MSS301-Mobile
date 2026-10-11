import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../providers/account_summary_provider.dart';
import 'account_menu.dart';
import 'membership_card.dart';

class AccountWalletSection extends ConsumerWidget {
  const AccountWalletSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(accountWalletProvider);
    return wallet.when(
      skipLoadingOnRefresh: false,
      loading: () => const _RemoteSectionState(title: 'Ví CinePremier'),
      error: (error, stack) => _RemoteSectionState(
        title: 'Ví CinePremier',
        message: 'Không thể tải thông tin ví.',
        onRetry: () {
          if (ref.read(accountWalletProvider).isLoading) return;
          ref.invalidate(accountWalletProvider);
          // Start synchronously so a second tap before rebuild sees loading.
          ref.read(accountWalletProvider);
        },
      ),
      data: (data) => WalletTile(
        balance: data.balance,
        onManage: () => context.go(AppRoutes.wallet),
      ),
    );
  }
}

class AccountLoyaltySection extends ConsumerWidget {
  const AccountLoyaltySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loyalty = ref.watch(accountLoyaltyProvider);
    return loyalty.when(
      skipLoadingOnRefresh: false,
      loading: () => const _RemoteSectionState(title: 'CinePoints'),
      error: (error, stack) => _RemoteSectionState(
        title: 'CinePoints',
        message: 'Không thể tải thông tin điểm thưởng.',
        onRetry: () {
          if (ref.read(accountLoyaltyProvider).isLoading) return;
          ref.invalidate(accountLoyaltyProvider);
          ref.read(accountLoyaltyProvider);
        },
      ),
      data: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MembershipCard(points: data.points, onQr: null),
          const SizedBox(height: AppSpacing.sm),
          AccountMenu(
            items: [
              AccountMenuItemData(
                icon: Icons.stars_rounded,
                label: 'CinePoints',
                trailing: '${data.points}',
                onTap: () => context.go(AppRoutes.points),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RemoteSectionState extends StatelessWidget {
  const _RemoteSectionState({required this.title, this.message, this.onRetry});

  final String title;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => AppSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: AppTextStyles.cardTitle),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (message == null)
          const Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(semanticsLabel: 'Đang tải'),
            ),
          )
        else ...[
          Semantics(
            liveRegion: true,
            child: Text(message!, style: AppTextStyles.body),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ],
    ),
  );
}
