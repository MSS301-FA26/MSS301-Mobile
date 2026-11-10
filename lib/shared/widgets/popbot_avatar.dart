import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class PopBotAvatar extends StatelessWidget {
  const PopBotAvatar({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppColors.purple.withValues(alpha: .35),
      borderRadius: AppRadii.control,
    ),
    child: Icon(
      Icons.smart_toy_rounded,
      color: AppColors.lavender,
      size: size * .6,
    ),
  );
}
