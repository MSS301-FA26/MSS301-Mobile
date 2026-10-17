import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../../../shared/widgets/app_surface.dart';

/// Displays only the query already applied by DiscoverPage.
class DiscoverFilterSummary extends StatelessWidget {
  const DiscoverFilterSummary({
    super.key,
    required this.keyword,
    required this.statusLabel,
    required this.genreLabel,
    required this.onClear,
  });

  final String keyword;
  final String statusLabel;
  final String? genreLabel;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) => AppSurface(
    padding: const EdgeInsets.all(AppSpacing.sm),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Đang lọc', style: AppTextStyles.emphasis),
            ),
            if (onClear != null)
              TextButton(
                key: const ValueKey('discover-clear-filters'),
                onPressed: onClear,
                child: const Text('Xóa bộ lọc'),
              ),
          ],
        ),
        Semantics(
          selected: true,
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xxs,
            children: [AppChip(label: statusLabel, selected: true)],
          ),
        ),
        if (genreLabel != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text('Thể loại: $genreLabel', style: AppTextStyles.body),
        ],
        if (keyword.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text('Từ khóa: “$keyword”', style: AppTextStyles.body),
        ],
      ],
    ),
  );
}
