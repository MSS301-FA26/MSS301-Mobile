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
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 24),
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          accent.withValues(alpha: 0.12),
          AppColors.surfaceRaised.withValues(alpha: 0.72),
          AppColors.background,
        ],
      ),
      border: Border(
        left: BorderSide(color: accent, width: 3),
        bottom: const BorderSide(color: AppColors.border),
      ),
    ),
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
        const SizedBox(height: 6),
        Builder(
          builder: (context) {
            final heading = Text(
              title,
              style: AppTextStyles.sectionTitle.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            );
            if (action == null || onAction == null) return heading;
            final button = TextButton.icon(
              key: ValueKey('home-section-action-$title'),
              onPressed: onAction,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: Text(action!),
              style: TextButton.styleFrom(
                foregroundColor: accent,
                textStyle: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            );
            if (MediaQuery.textScalerOf(context).scale(12) > 18) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [heading, button],
              );
            }
            return Row(
              children: [
                Expanded(child: heading),
                const SizedBox(width: 8),
                button,
              ],
            );
          },
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
          ),
        ],
      ],
    ),
  );
}
