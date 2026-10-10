import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_surface.dart';

/// Displays controller state without interpreting payment or booking outcomes.
class PaymentStatePanel extends StatelessWidget {
  const PaymentStatePanel({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.busy,
    required this.actions,
    this.paymentUrl,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final bool busy;
  final Widget actions;
  final String? paymentUrl;

  @override
  Widget build(BuildContext context) => AppSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: AppSpacing.md),
              Semantics(
                header: true,
                child: Text(title, style: AppTextStyles.sectionTitle),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (busy)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          ),
        const SizedBox(height: AppSpacing.lg),
        actions,
        if (paymentUrl != null) ...[
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          const Text('Đường dẫn thanh toán', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xs),
          SelectableText(
            paymentUrl!,
            key: const ValueKey('payment-url'),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    ),
  );
}
