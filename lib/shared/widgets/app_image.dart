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
    final source = asset.trim();
    final uri = Uri.tryParse(source);
    final isNetwork =
        uri != null &&
        uri.host.isNotEmpty &&
        (uri.scheme == 'http' || uri.scheme == 'https');
    Widget fallback(
      BuildContext context,
      Object error,
      StackTrace? stackTrace,
    ) => const ColoredBox(
      color: AppColors.surfaceRaised,
      child: Center(
        child: Icon(Icons.movie_outlined, color: AppColors.textMuted, size: 36),
      ),
    );
    final image = isNetwork
        ? Image.network(
            source,
            width: width,
            height: height,
            fit: fit,
            semanticLabel: semanticLabel,
            errorBuilder: fallback,
          )
        : Image.asset(
            source,
            width: width,
            height: height,
            fit: fit,
            semanticLabel: semanticLabel,
            errorBuilder: fallback,
          );
    final clipped = ClipRRect(borderRadius: borderRadius, child: image);
    if (aspectRatio == null) return clipped;
    return AspectRatio(aspectRatio: aspectRatio!, child: clipped);
  }
}
