import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, purple }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.height = 46,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final double height;

  @override
  Widget build(BuildContext context) {
    final buttonChild = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: AppSpacing.xxs),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.button,
          ),
        ),
      ],
    );

    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(0, height)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      ),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: AppRadii.control),
      ),
    );

    return SizedBox(
      height: height,
      child: switch (variant) {
        AppButtonVariant.primary => FilledButton(
          onPressed: onPressed,
          style: style,
          child: buttonChild,
        ),
        AppButtonVariant.purple => FilledButton(
          onPressed: onPressed,
          style: style.copyWith(
            backgroundColor: const WidgetStatePropertyAll(AppColors.purple),
            foregroundColor: const WidgetStatePropertyAll(AppColors.text),
          ),
          child: buttonChild,
        ),
        AppButtonVariant.secondary => OutlinedButton(
          onPressed: onPressed,
          style: style.copyWith(
            backgroundColor: const WidgetStatePropertyAll(
              AppColors.surfaceRaised,
            ),
            foregroundColor: const WidgetStatePropertyAll(AppColors.text),
            side: const WidgetStatePropertyAll(
              BorderSide(color: AppColors.border),
            ),
          ),
          child: buttonChild,
        ),
      },
    );
  }
}
