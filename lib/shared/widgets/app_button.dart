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
    this.height = 48,
    this.loading = false,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final double height;
  final bool loading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final buttonChild = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (loading) ...[
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.xs),
        ] else if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: AppSpacing.xxs),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 2,
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

    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: (height < 48 ? 48 : height) * (textScale < 1 ? 1 : textScale),
      child: switch (variant) {
        AppButtonVariant.primary => FilledButton(
          onPressed: loading ? null : onPressed,
          style: style,
          child: buttonChild,
        ),
        AppButtonVariant.purple => FilledButton(
          onPressed: loading ? null : onPressed,
          style: style.copyWith(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? AppColors.disabled
                  : AppColors.purple,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? AppColors.textMuted
                  : AppColors.text,
            ),
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
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? AppColors.disabled
                  : AppColors.error,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? AppColors.textMuted
                  : AppColors.text,
            ),
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
