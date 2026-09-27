import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class BookingProgress extends StatelessWidget {
  const BookingProgress({super.key, required this.currentStep});

  final int currentStep;

  static const _labels = ['Suất chiếu', 'Vé & Ghế', 'Bắp nước', 'Thanh toán'];

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.sm,
    ),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: Row(
      children: [
        for (var index = 0; index < _labels.length; index++) ...[
          Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: index <= currentStep
                      ? AppColors.gold
                      : AppColors.surfaceRaised,
                  child: index < currentStep
                      ? const Icon(Icons.check, size: 14, color: Colors.black)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: index == currentStep
                                ? Colors.black
                                : AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
                const SizedBox(height: 4),
                Text(
                  _labels[index],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: index == currentStep
                        ? AppColors.gold
                        : AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (index < _labels.length - 1)
            Container(
              width: 12,
              height: 2,
              color: index < currentStep ? AppColors.gold : AppColors.border,
            ),
        ],
      ],
    ),
  );
}
