import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import 'home_section_heading.dart';

class HomeFoodSection extends StatelessWidget {
  const HomeFoodSection({super.key});

  static const _image =
      'https://images.unsplash.com/photo-1586899028174-e7098604235b?auto=format&fit=crop&w=1200&q=82';

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      HomeSectionHeading(
        eyebrow: 'TRỌN VẸN VỊ PHIM',
        title: 'BẮP NƯỚC CINEPREMIER',
        subtitle: 'Combo hấp dẫn, nhận nhanh tại rạp — không cần mua vé phim.',
        action: 'Xem thực đơn',
        onAction: () => context.push(AppRoutes.foodShop),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Material(
          color: AppColors.surface,
          borderRadius: AppRadii.card,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: const ValueKey('home-food-shop'),
            onTap: () => context.push(AppRoutes.foodShop),
            child: SizedBox(
              height: 210,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: AppColors.goldSurface,
                      child: Icon(
                        Icons.fastfood_rounded,
                        size: 56,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x18000000),
                          Color(0x66000000),
                          Color(0xF0000000),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'BẮP GIÒN • NƯỚC MÁT • COMBO TIẾT KIỆM',
                                style: AppTextStyles.meta.copyWith(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Chọn món yêu thích\nNhận tại rạp gần bạn',
                                style: AppTextStyles.sectionTitle,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        AppButton(
                          label: 'Mua ngay',
                          icon: Icons.arrow_forward_rounded,
                          onPressed: () => context.push(AppRoutes.foodShop),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
