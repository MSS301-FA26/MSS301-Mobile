import 'package:flutter/material.dart';

import '../../core/constants/cinema_info.dart';
import '../../core/theme/app_theme.dart';
import 'cinema_info_sheet.dart';

class CinemaHeader extends StatelessWidget implements PreferredSizeWidget {
  const CinemaHeader({super.key, required this.onUnavailable});

  final void Function(String feature) onUnavailable;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 64,
      automaticallyImplyLeading: false,
      titleSpacing: 10,
      title: Row(
        children: [
          const _BrandMark(),
          const SizedBox(width: 6),
          Expanded(
            child: InkWell(
              onTap: () => showModalBottomSheet<void>(
                context: context,
                backgroundColor: AppColors.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadii.card,
                ),
                builder: (context) => const CinemaInfoSheet(),
              ),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: AppColors.gold,
                      size: 17,
                    ),
                    SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        CinemaInfo.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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
            constraints: const BoxConstraints.tightFor(width: 40, height: 40),
            padding: EdgeInsets.zero,
            onPressed: () => onUnavailable('Tìm kiếm'),
            icon: const Icon(Icons.search, size: 22),
          ),
          IconButton(
            tooltip: 'Thông báo',
            constraints: const BoxConstraints.tightFor(width: 40, height: 40),
            padding: EdgeInsets.zero,
            onPressed: () => onUnavailable('Thông báo'),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none, size: 22),
                Positioned(
                  top: 1,
                  right: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background),
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Tài khoản',
            constraints: const BoxConstraints.tightFor(width: 40, height: 40),
            padding: EdgeInsets.zero,
            onPressed: () => onUnavailable('Tài khoản'),
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
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.control,
        border: Border.all(color: AppColors.border),
      ),
      child: const Text.rich(
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
    );
  }
}
