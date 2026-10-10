import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class HomeSectionHeading extends StatelessWidget {
  const HomeSectionHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.accent = AppColors.gold,
    this.action,
    this.onAction,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Color accent;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 32, 16, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                eyebrow,
                style: AppTextStyles.meta.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: AppTextStyles.screenTitle.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
        ),
        if (action != null && onAction != null) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onAction,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: Text(action!),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.text,
              foregroundColor: AppColors.background,
              textStyle: AppTextStyles.meta.copyWith(
                fontWeight: FontWeight.w800,
              ),
              minimumSize: const Size(48, 48),
              shape: const StadiumBorder(),
            ),
          ),
        ],
        const SizedBox(height: 16),
        const Divider(),
      ],
    ),
  );
}
