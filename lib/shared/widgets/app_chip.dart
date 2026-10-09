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
    this.maxLabelWidth,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool selected;
  final bool enabled;
  final IconData? icon;
  final double? maxLabelWidth;

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

    final chip = ActionChip(
      onPressed: enabled ? onPressed : null,
      avatar: icon == null ? null : Icon(icon, size: 16, color: foreground),
      label: maxLabelWidth == null
          ? Text(label)
          : ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxLabelWidth!),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
      labelStyle: AppTextStyles.meta.copyWith(
        fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
        color: foreground,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: background,
      disabledColor: background,
      side: BorderSide(color: selected ? AppColors.gold : AppColors.border),
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.small),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
    );
    return maxLabelWidth == null ? chip : Tooltip(message: label, child: chip);
  }
}
