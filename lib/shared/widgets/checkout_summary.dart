import 'package:flutter/material.dart';

import '../../core/money/vnd_money.dart';
import '../../core/theme/app_theme.dart';
import 'app_button.dart';

class CheckoutSection extends StatelessWidget {
  const CheckoutSection({
    super.key,
    required this.title,
    required this.children,
  });
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surfaceRaised,
      borderRadius: AppRadii.card,
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.cardTitle),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );
}

class CheckoutLine extends StatelessWidget {
  const CheckoutLine(
    this.label,
    this.value, {
    super.key,
    this.emphasized = false,
    this.stacked = false,
  });
  final String label, value;
  final bool emphasized;
  final bool stacked;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final labelWidget = Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textMuted,
            fontSize: 14,
          ),
        );
        final valueStyle = AppTextStyles.body.copyWith(
          fontSize: 15,
          color: emphasized ? AppColors.gold : AppColors.text,
          fontWeight: emphasized ? FontWeight.w900 : FontWeight.w600,
        );
        if (stacked ||
            constraints.maxWidth < 290 ||
            MediaQuery.textScalerOf(context).scale(14) > 18) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              labelWidget,
              const SizedBox(height: 4),
              Text(value, style: valueStyle),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: labelWidget),
            const SizedBox(width: 12),
            Expanded(
              child: Text(value, textAlign: TextAlign.end, style: valueStyle),
            ),
          ],
        );
      },
    ),
  );
}

class PaymentActionBar extends StatelessWidget {
  const PaymentActionBar({
    super.key,
    required this.total,
    required this.label,
    required this.buttonKey,
    required this.onPressed,
    this.notice,
    this.loading = false,
    this.icon = Icons.lock_outline,
  });
  final VndMoney total;
  final String label;
  final Key buttonKey;
  final VoidCallback? onPressed;
  final String? notice;
  final bool loading;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (notice?.trim().isNotEmpty == true) ...[
            Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.gold,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notice!,
                      style: AppTextStyles.caption.copyWith(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Tổng thanh toán', style: AppTextStyles.body),
              Text(
                total.format(),
                style: AppTextStyles.sectionTitle.copyWith(
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppButton(
            key: buttonKey,
            label: label,
            loading: loading,
            onPressed: onPressed,
            icon: icon,
          ),
        ],
      ),
    ),
  );
}
