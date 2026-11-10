import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_image.dart';
import '../models/movie.dart';

final movieTrailerLauncherProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

class TrailerPreviewDialog extends ConsumerStatefulWidget {
  const TrailerPreviewDialog({super.key, required this.movie});
  final Movie movie;
  @override
  ConsumerState<TrailerPreviewDialog> createState() =>
      _TrailerPreviewDialogState();
}

class _TrailerPreviewDialogState extends ConsumerState<TrailerPreviewDialog> {
  bool _busy = false;
  String? _error;
  Future<void> _open() async {
    if (_busy) return;
    final uri = Uri.tryParse(widget.movie.trailerUrl?.trim() ?? '');
    if (uri == null ||
        !{'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty) {
      setState(
        () => _error = 'Đường dẫn trailer chưa hợp lệ. Vui lòng thử lại sau.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final opened = await ref.read(movieTrailerLauncherProvider)(uri);
      if (!opened && mounted) {
        setState(() => _error = 'Không thể mở trailer. Bạn có thể thử lại.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không thể mở trailer. Bạn có thể thử lại.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(widget.movie.title, style: AppTextStyles.cardTitle),
              ),
              IconButton(
                tooltip: 'Đóng',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: AppImage(
              asset: widget.movie.bannerAsset ?? widget.movie.posterAsset,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Trailer sẽ mở bằng ứng dụng video hoặc trình duyệt trên thiết bị.',
            style: AppTextStyles.body,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                key: const ValueKey('movie-trailer-error'),
                style: AppTextStyles.body.copyWith(color: AppColors.error),
              ),
            ),
          ],
          const SizedBox(height: 16),
          AppButton(
            key: const ValueKey('movie-trailer-open'),
            label: _busy ? 'Đang mở trailer…' : 'Mở trailer',
            icon: Icons.open_in_new_rounded,
            loading: _busy,
            onPressed: _busy ? null : _open,
          ),
        ],
      ),
    ),
  );
}
