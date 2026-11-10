import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../../../../core/theme/app_theme.dart';

class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({super.key, this.url, this.radius = 32});
  final String? url;
  final double radius;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget fallback() => CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.goldSurface,
      child: Icon(Icons.person_rounded, size: radius, color: AppColors.gold),
    );
    var source = url?.trim() ?? '';
    if (source.isEmpty) return fallback();
    final uri = Uri.tryParse(source);
    if (uri == null) return fallback();
    if (!uri.hasScheme) {
      try {
        source = Uri.parse(ref.read(appConfigProvider).apiBaseUrl)
            .resolve(source)
            .toString();
      } catch (_) {
        return fallback();
      }
    }
    final resolved = Uri.tryParse(source);
    if (resolved == null ||
        resolved.host.isEmpty ||
        !['http', 'https'].contains(resolved.scheme)) {
      return fallback();
    }
    return ClipOval(
      child: Image.network(
        source,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
      ),
    );
  }
}
