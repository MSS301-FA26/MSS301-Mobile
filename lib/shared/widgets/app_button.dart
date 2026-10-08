import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, purple, danger, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.height = 46,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final double height;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final buttonChild = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (loading)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (icon != null) ...[
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
          onPressed: loading ? null : onPressed,
          style: style,
          child: buttonChild,
        ),
        AppButtonVariant.purple => FilledButton(
          onPressed: loading ? null : onPressed,
          style: style.copyWith(
            backgroundColor: const WidgetStatePropertyAll(AppColors.purple),
            foregroundColor: const WidgetStatePropertyAll(AppColors.text),
          ),
          child: buttonChild,
        ),
        AppButtonVariant.secondary => OutlinedButton(
          onPressed: loading ? null : onPressed,
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
        AppButtonVariant.danger => FilledButton(
          onPressed: loading ? null : onPressed,
          style: style.copyWith(
            backgroundColor: const WidgetStatePropertyAll(AppColors.error),
            foregroundColor: const WidgetStatePropertyAll(AppColors.text),
          ),
          child: buttonChild,
        ),
        AppButtonVariant.ghost => TextButton(
          onPressed: loading ? null : onPressed,
          style: style.copyWith(
            foregroundColor: const WidgetStatePropertyAll(
              AppColors.textSecondary,
            ),
            overlayColor: WidgetStatePropertyAll(
              AppColors.text.withValues(alpha: 0.08),
            ),
          ),
          child: buttonChild,
        ),
      },
    );
  }
}
