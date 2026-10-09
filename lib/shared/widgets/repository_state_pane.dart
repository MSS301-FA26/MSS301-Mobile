import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'app_button.dart';

class RepositoryStatePane extends StatelessWidget {
  const RepositoryStatePane.loading({super.key})
    : title = 'Đang tải dữ liệu...',
      message = null,
      icon = null,
      onRetry = null,
      isLoading = true;

  const RepositoryStatePane.error({
    super.key,
    required this.onRetry,
    this.message = 'Không thể tải dữ liệu. Vui lòng thử lại.',
  }) : title = 'Đã xảy ra lỗi',
       icon = Icons.error_outline_rounded,
       isLoading = false;

  const RepositoryStatePane.empty({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
  }) : onRetry = null,
       isLoading = false;

  final String title;
  final String? message;
  final IconData? icon;
  final VoidCallback? onRetry;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
              )
            else if (icon != null)
              Icon(
                icon,
                size: AppSizes.stateIcon,
                color: onRetry == null ? AppColors.textMuted : AppColors.error,
              ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.cardTitle,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              AppButton(
                variant: AppButtonVariant.secondary,
                onPressed: onRetry,
                icon: Icons.refresh_rounded,
                label: 'Thử lại',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
