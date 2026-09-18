import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class AppImage extends StatelessWidget {
  const AppImage({super.key, required this.asset, this.fit = BoxFit.cover});

  final String asset;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => const ColoredBox(
        color: AppColors.surfaceRaised,
        child: Center(
          child: Icon(
            Icons.movie_outlined,
            color: AppColors.textMuted,
            size: 36,
          ),
        ),
      ),
    );
  }
}
