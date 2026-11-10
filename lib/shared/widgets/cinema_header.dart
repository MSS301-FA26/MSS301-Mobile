import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../features/cinema/application/cinema_preferences.dart';
import '../../features/home/presentation/providers/home_providers.dart';

class CinemaHeader extends ConsumerWidget implements PreferredSizeWidget {
  const CinemaHeader({
    super.key,
    required this.onHome,
    required this.onSearch,
    required this.onAccount,
    this.onNotifications,
    this.compact = false,
  });

  final VoidCallback onHome;
  final VoidCallback onSearch;
  final VoidCallback onAccount;
  final VoidCallback? onNotifications;
  final bool compact;

  @override
  Size get preferredSize =>
      Size.fromHeight(compact ? 56 : AppSpacing.headerHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferredId = ref.watch(preferredCinemaProvider).value;
    final cinemas = ref.watch(homeCinemasProvider).value ?? [];
    final selected = cinemas
        .where((cinema) => cinema.id == preferredId)
        .firstOrNull;
    return AppBar(
      toolbarHeight: compact ? 56 : AppSpacing.headerHeight,
      automaticallyImplyLeading: false,
      titleSpacing: AppSpacing.xs,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          if (compact)
            InkWell(
              key: const ValueKey('header-home-logo'),
              onTap: onHome,
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.goldBorder),
                  ),
                  child: Text(
                    'C',
                    style: AppTextStyles.screenTitle.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            )
          else
            _BrandMark(onTap: onHome),
          const SizedBox(width: AppSpacing.xs),
          if (compact)
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'CINEPREMIER',
                  style: AppTextStyles.emphasis.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: InkWell(
                onTap: () => context.push(AppRoutes.cinemas),
                borderRadius: AppRadii.control,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: AppRadii.control,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: AppColors.gold,
                        size: 17,
                      ),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          selected?.name ?? 'Chọn rạp',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.meta.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Tìm kiếm',
            constraints: BoxConstraints.tightFor(
              width: compact ? 48 : 44,
              height: compact ? 48 : 44,
            ),
            padding: EdgeInsets.zero,
            onPressed: onSearch,
            icon: const Icon(Icons.search, size: 22),
          ),
          if (!compact)
            IconButton(
              tooltip: 'Thông báo • Sắp có',
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
              padding: EdgeInsets.zero,
              onPressed: onNotifications,
              icon: const Icon(Icons.notifications_none, size: 22),
            ),
          IconButton(
            tooltip: 'Tài khoản',
            constraints: BoxConstraints.tightFor(
              width: compact ? 48 : 44,
              height: compact ? 48 : 44,
            ),
            padding: EdgeInsets.zero,
            onPressed: onAccount,
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: const Divider(height: 1, thickness: 1),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Về trang chủ',
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadii.control,
        child: InkWell(
          key: const ValueKey('header-home-logo'),
          onTap: onTap,
          borderRadius: AppRadii.control,
          child: Padding(
            // Keep the 40px visual mark while providing a 44px hit target.
            padding: const EdgeInsets.all(2),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: AppRadii.control,
                border: Border.all(color: AppColors.border),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'C',
                        style: TextStyle(color: AppColors.text),
                      ),
                      TextSpan(
                        text: 'P',
                        style: TextStyle(color: AppColors.gold),
                      ),
                    ],
                  ),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
