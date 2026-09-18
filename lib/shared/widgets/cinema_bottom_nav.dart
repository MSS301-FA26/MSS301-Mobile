import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class CinemaBottomNav extends StatelessWidget {
  const CinemaBottomNav({super.key, required this.onUnavailable});

  final void Function(String feature) onUnavailable;

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
      child: Container(
        height: 65,
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: InkWell(
                  onTap: i == 0 ? null : () => onUnavailable(items[i].label),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        items[i].icon,
                        size: 23,
                        color: i == 0 ? AppColors.gold : AppColors.textMuted,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[i].label,
                        maxLines: 1,
                        style: TextStyle(
                          color: i == 0 ? AppColors.gold : AppColors.textMuted,
                          fontWeight: i == 0
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
