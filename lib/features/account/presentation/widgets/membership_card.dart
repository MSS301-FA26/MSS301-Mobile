import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../models/account_summary.dart';

class MembershipCard extends StatelessWidget {
  const MembershipCard({super.key, required this.user, required this.onQr});

  final AccountSummary user;
  final VoidCallback? onQr;

  @override
  Widget build(BuildContext context) => AppSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Điểm tích lũy', style: AppTextStyles.cardTitle),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _formatNumber(user.points),
          style: AppTextStyles.price.copyWith(color: AppColors.gold),
        ),
        const SizedBox(height: AppSpacing.xxs),
        const Text('CinePoints hiện có', style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.md),
        TextButton.icon(
          key: const ValueKey('account-membership-qr'),
          onPressed: onQr,
          icon: const Icon(Icons.qr_code_rounded, size: AppSizes.iconSmall),
          label: Text(onQr == null ? 'Sắp có' : 'Mã VIP'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.gold,
            minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
            padding: const EdgeInsets.all(AppSpacing.sm),
            textStyle: AppTextStyles.button.copyWith(
              fontFamily: Theme.of(context).textTheme.labelLarge?.fontFamily,
            ),
          ),
        ),
      ],
    ),
  );
}

String _formatNumber(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final fromEnd = text.length - i;
    buffer.write(text[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buffer.write('.');
  }
  return buffer.toString();
}
