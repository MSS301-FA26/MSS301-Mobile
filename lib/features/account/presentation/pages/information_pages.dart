import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_shell.dart';

enum InformationPageType { cinema, policies, support }

class InformationPage extends StatelessWidget {
  const InformationPage({super.key, required this.type});

  final InformationPageType type;

  @override
  Widget build(BuildContext context) {
    final (title, items) = switch (type) {
      InformationPageType.cinema => (
        'Thông tin rạp',
        const [
          ('CineAI Central', '123 Đường Điện Ảnh, Quận 1, TP.HCM'),
          ('Giờ mở cửa', '08:00–23:30 mỗi ngày'),
          ('Tiện ích', 'IMAX, phòng VIP, bãi xe và lối đi hỗ trợ'),
        ],
      ),
      InformationPageType.policies => (
        'Chính sách',
        const [
          ('Đặt vé', 'Ghế chỉ được xác nhận sau khi booking PAID.'),
          ('Hoàn/đổi', 'Điều kiện và mức hoàn phải được backend xác nhận.'),
          ('Bảo mật', 'Không chia sẻ OTP, mật khẩu hoặc mã QR vé.'),
        ],
      ),
      InformationPageType.support => (
        'Trung tâm trợ giúp & CSKH',
        const [
          ('Hotline', '1900 0000 • 08:00–22:00'),
          ('Email', 'support@cinepremier.vn'),
          ('Sự cố thanh toán', 'Giữ mã booking và mã giao dịch để tra soát.'),
        ],
      ),
    };
    return AppShell(
      currentIndex: 4,
      showBottomNavigation: false,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: IconButton(
                tooltip: 'Quay lại',
                onPressed: () => context.go(AppRoutes.account),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              title: Text(title, style: AppTextStyles.sectionTitle),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final item in items)
              Card(
                child: ListTile(
                  title: Text(item.$1, style: AppTextStyles.cardTitle),
                  subtitle: Text(item.$2, style: AppTextStyles.caption),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
