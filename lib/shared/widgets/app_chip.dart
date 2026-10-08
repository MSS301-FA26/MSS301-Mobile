import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Compact customer filter/status chip with selected and disabled states.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.onPressed,
    this.selected = false,
    this.enabled = true,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool selected;
  final bool enabled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final foreground = !enabled
        ? AppColors.textDisabled
        : selected
        ? AppColors.background
        : AppColors.textSecondary;
    final background = !enabled
        ? AppColors.disabled
        : selected
        ? AppColors.gold
        : AppColors.surfaceRaised;

    return ActionChip(
      onPressed: enabled ? onPressed : null,
      avatar: icon == null ? null : Icon(icon, size: 16, color: foreground),
      label: Text(label),
      labelStyle: AppTextStyles.meta.copyWith(
        color: foreground,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: background,
      disabledColor: background,
      side: BorderSide(color: selected ? AppColors.gold : AppColors.border),
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.small),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
    );
  }
}
