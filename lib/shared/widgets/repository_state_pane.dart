import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'repository_skeleton.dart';
export 'repository_skeleton.dart' show RepositorySkeleton;

class RepositoryStatePane extends StatelessWidget {
  const RepositoryStatePane.loading({
    super.key,
    this.layout = RepositorySkeleton.orders,
    this.title = 'Đang tải dữ liệu...',
  }) : message = null,
       icon = null,
       onRetry = null,
       actionLabel = 'Thử lại',
       compact = false,
       isLoading = true;

  const RepositoryStatePane.error({
    super.key,
    required this.onRetry,
    this.title = 'Chưa tải được dữ liệu',
    this.compact = false,
    this.message = 'Không thể tải dữ liệu. Vui lòng thử lại.',
  }) : icon = Icons.cloud_off_rounded,
       layout = RepositorySkeleton.orders,
       actionLabel = 'Thử lại',
       isLoading = false;

  const RepositoryStatePane.empty({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    VoidCallback? onAction,
    this.actionLabel = 'Khám phá phim',
    this.compact = false,
  }) : onRetry = onAction,
       layout = RepositorySkeleton.orders,
       isLoading = false;

  final String title;
  final String? message;
  final IconData? icon;
  final VoidCallback? onRetry;
  final bool isLoading;
  final RepositorySkeleton layout;
  final String actionLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Semantics(
        liveRegion: true,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(title, style: AppTextStyles.cardTitle),
            const SizedBox(height: AppSpacing.md),
            RepositorySkeletonView(layout: layout),
          ],
        ),
      );
    }
    final content = Padding(
      padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: AppColors.goldSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: AppColors.gold),
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
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
    if (compact) return content;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.hasBoundedHeight ? constraints.maxHeight : 0,
          ),
          child: Center(child: content),
        ),
      ),
    );
  }
}
