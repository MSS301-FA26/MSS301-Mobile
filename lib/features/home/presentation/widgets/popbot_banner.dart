import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/popbot_avatar.dart';

class PopBotBanner extends StatelessWidget {
  const PopBotBanner({super.key, required this.onOpen});
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.purple.withValues(alpha: 0.22), AppColors.surface],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: AppRadii.card,
      border: Border.all(color: AppColors.purple.withValues(alpha: 0.45)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const PopBotAvatar(),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PopBot AI', style: AppTextStyles.cardTitle),
                  SizedBox(height: 4),
                  Text(
                    'Chưa biết xem gì? Để PopBot gợi ý.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppButton(
          label: 'Trò chuyện với PopBot',
          icon: Icons.chat_bubble_outline,
          onPressed: onOpen,
          variant: AppButtonVariant.purple,
          height: 48,
        ),
      ],
    ),
  );
}
