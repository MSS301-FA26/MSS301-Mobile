import 'package:flutter/material.dart';

import '../../core/constants/cinema_info.dart';
import '../../core/theme/app_theme.dart';

class CinemaInfoSheet extends StatelessWidget {
  const CinemaInfoSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageGutter,
          AppSpacing.xl,
          AppSpacing.pageGutter,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              CinemaInfo.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            const _InfoRow(Icons.location_on_outlined, CinemaInfo.address),
            const SizedBox(height: AppSpacing.sm),
            const _InfoRow(Icons.schedule_outlined, CinemaInfo.operatingHours),
            const SizedBox(height: AppSpacing.sm),
            const _InfoRow(Icons.call_outlined, CinemaInfo.hotline),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final feature in CinemaInfo.features)
                  Chip(
                    label: Text(feature),
                    backgroundColor: AppColors.surfaceRaised,
                    side: const BorderSide(color: AppColors.border),
                    labelStyle: AppTextStyles.meta,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: AppColors.gold, size: 20),
      const SizedBox(width: AppSpacing.xs),
      Expanded(child: Text(text, style: AppTextStyles.body)),
    ],
  );
}
