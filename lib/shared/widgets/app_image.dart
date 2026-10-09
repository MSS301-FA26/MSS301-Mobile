import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.asset,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.aspectRatio,
    this.borderRadius = AppRadii.small,
    this.semanticLabel,
  });

  final String asset;
  final BoxFit fit;
  final double? width;
  final double? height;
  final double? aspectRatio;
  final BorderRadius borderRadius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(asset);
    final isRemote =
        uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
    final image = Image(
      image: isRemote ? NetworkImage(asset) : AssetImage(asset),
      width: width,
      height: height,
      fit: fit,
      semanticLabel: semanticLabel,
      errorBuilder: (context, error, stackTrace) => const ColoredBox(
        color: AppColors.surfaceRaised,
        child: Center(
          child: Icon(
            Icons.movie_outlined,
            color: AppColors.textMuted,
            size: AppSizes.iconFallback,
          ),
        ),
      ),
    );
    final clipped = ClipRRect(borderRadius: borderRadius, child: image);
    if (aspectRatio == null) return clipped;
    return AspectRatio(aspectRatio: aspectRatio!, child: clipped);
  }
}
