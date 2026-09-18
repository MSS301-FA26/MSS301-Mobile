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
      titleSpacing: 12,
      title: Row(
        children: [
          const _BrandMark(),
          const SizedBox(width: 8),
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
            visualDensity: VisualDensity.compact,
            onPressed: () => onUnavailable('Tìm kiếm'),
            icon: const Icon(Icons.search, size: 23),
          ),
          IconButton(
            tooltip: 'Thông báo',
            visualDensity: VisualDensity.compact,
            onPressed: () => onUnavailable('Thông báo'),
            icon: const Icon(Icons.notifications_none, size: 23),
          ),
          IconButton(
            tooltip: 'Tài khoản',
            visualDensity: VisualDensity.compact,
            onPressed: () => onUnavailable('Tài khoản'),
            icon: const Icon(Icons.account_circle_outlined, size: 23),
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
