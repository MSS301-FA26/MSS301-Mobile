import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../models/movie.dart';

class MovieDetailContent extends StatelessWidget {
  const MovieDetailContent({super.key, required this.movie});
  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final synopsis = movie.description ?? movie.tagline;
    final hasDirector = movie.director?.trim().isNotEmpty ?? false;
    final hasCast = movie.cast?.trim().isNotEmpty ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (synopsis.trim().isNotEmpty) ...[
          const AppSectionHeader(title: 'Nội dung phim'),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            child: _Synopsis(key: ValueKey(movie.id), text: synopsis),
          ),
        ],
        const AppSectionHeader(title: 'Thông tin phim'),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          child: AppSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InformationRow(label: 'Thời lượng', value: movie.duration),
                if (movie.releaseDate != null)
                  _InformationRow(
                    label: 'Khởi chiếu',
                    value: _date(movie.releaseDate!),
                  ),
                if (movie.language?.trim().isNotEmpty ?? false)
                  _InformationRow(label: 'Ngôn ngữ', value: movie.language!),
                if (movie.subtitleLanguage?.trim().isNotEmpty ?? false)
                  _InformationRow(
                    label: 'Phụ đề',
                    value: movie.subtitleLanguage!,
                  ),
                if (movie.format.isNotEmpty)
                  _InformationRow(label: 'Định dạng', value: movie.format),
              ],
            ),
          ),
        ),
        if (hasDirector || hasCast) ...[
          const AppSectionHeader(title: 'Ê-kíp phim'),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            child: Column(
              children: [
                if (hasDirector)
                  _InformationRow(label: 'Đạo diễn', value: movie.director!),
                if (hasCast)
                  _InformationRow(label: 'Diễn viên', value: movie.cast!),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Synopsis extends StatefulWidget {
  const _Synopsis({super.key, required this.text});
  final String text;

  @override
  State<_Synopsis> createState() => _SynopsisState();
}

class _SynopsisState extends State<_Synopsis> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final canExpand = widget.text.length > 220;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          key: const ValueKey('movie-detail-synopsis'),
          maxLines: canExpand && !_expanded ? 4 : null,
          overflow: canExpand && !_expanded
              ? TextOverflow.ellipsis
              : TextOverflow.clip,
          style: AppTextStyles.body,
        ),
        if (canExpand)
          TextButton.icon(
            key: const ValueKey('movie-detail-synopsis-toggle'),
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            label: Text(_expanded ? 'Thu gọn' : 'Xem thêm'),
          ),
      ],
    );
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 1, child: Text(label, style: AppTextStyles.caption)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(flex: 2, child: Text(value, style: AppTextStyles.body)),
      ],
    ),
  );
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
