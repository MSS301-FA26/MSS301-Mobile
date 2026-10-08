import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class CinemaBottomNav extends StatelessWidget {
  const CinemaBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = <({String label, IconData icon})>[
      (label: 'Trang chủ', icon: Icons.home_rounded),
      (label: 'Khám phá', icon: Icons.explore_outlined),
      (label: 'Lịch chiếu', icon: Icons.calendar_month_outlined),
      (label: 'Đơn của tôi', icon: Icons.confirmation_number_outlined),
      (label: 'Tài khoản', icon: Icons.account_circle_outlined),
    ];

    return SafeArea(
      top: false,
      child: Material(
        color: AppColors.background,
        child: Container(
          height: AppSpacing.bottomBarHeight,
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.background,
            elevation: 0,
            selectedFontSize: 10,
            unselectedFontSize: 10,
            selectedItemColor: AppColors.gold,
            unselectedItemColor: AppColors.textMuted,
            selectedLabelStyle: AppTextStyles.meta.copyWith(
              color: AppColors.gold,
              fontWeight: FontWeight.w800,
            ),
            unselectedLabelStyle: AppTextStyles.meta.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
            showUnselectedLabels: true,
            onTap: onTap,
            items: [
              for (var i = 0; i < items.length; i++)
                BottomNavigationBarItem(
                  icon: _BottomNavIcon(
                    icon: items[i].icon,
                    showBadge: i == 3,
                    itemIndex: i,
                  ),
                  activeIcon: _BottomNavIcon(
                    icon: items[i].icon,
                    showBadge: i == 3,
                    itemIndex: i,
                    selected: true,
                  ),
                  label: items[i].label,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavIcon extends StatelessWidget {
  const _BottomNavIcon({
    required this.icon,
    required this.showBadge,
    required this.itemIndex,
    this.selected = false,
  });

  final IconData icon;
  final bool showBadge;
  final int itemIndex;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.gold : AppColors.textMuted;

    return Stack(
      key: ValueKey('bottom-nav-icon-$itemIndex'),
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: 22, color: color),
        if (showBadge)
          Positioned(
            top: -4,
            right: -9,
            child: Container(
              width: 16,
              height: 16,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
              child: const Text(
                '1',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
