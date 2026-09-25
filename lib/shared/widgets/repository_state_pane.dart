import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

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
              const CircularProgressIndicator()
            else if (icon != null)
              Icon(icon, size: 42, color: AppColors.textMuted),
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
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
