import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/age_badge.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../../shared/widgets/checkout_summary.dart';
import '../../data/models/recommendation_dto.dart';
import '../../data/models/review_dto.dart';
import '../models/movie.dart';

class MovieDetailHero extends StatelessWidget {
  const MovieDetailHero({super.key, required this.movie, this.onTrailer});
  final Movie movie;
  final VoidCallback? onTrailer;
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 16 / 9,
    child: Stack(
      fit: StackFit.expand,
      children: [
        AppImage(
          asset: movie.bannerAsset?.trim().isNotEmpty == true
              ? movie.bannerAsset!
              : movie.posterAsset,
          borderRadius: BorderRadius.zero,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x22000000),
                Color(0xAA000000),
                AppColors.background,
              ],
            ),
          ),
        ),
        Center(
          child: FilledButton.tonalIcon(
            key: const ValueKey('movie-detail-trailer'),
            onPressed: onTrailer,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.surface.withValues(alpha: .9),
              foregroundColor: AppColors.gold,
              minimumSize: const Size(48, 48),
            ),
            icon: const Icon(Icons.play_circle_outline_rounded),
            label: Text(onTrailer == null ? 'Chưa có trailer' : 'Xem trailer'),
          ),
        ),
      ],
    ),
  );
}

String _ageDescription(String rating) {
  final normalized = rating.trim().toUpperCase();
  if (normalized == 'P') return 'Phù hợp với khán giả ở mọi độ tuổi.';
  if (normalized == 'K') {
    return 'Khán giả dưới 13 tuổi cần đi cùng cha mẹ hoặc người giám hộ.';
  }
  final minimum = RegExp(r'^(?:T)?(13|16|18)(?:\+)?$')
      .firstMatch(normalized)
      ?.group(1);
  if (minimum != null) {
    return 'Phim dành cho khán giả từ đủ $minimum tuổi trở lên.';
  }
  if (normalized == 'C') return 'Phim không được phép phổ biến.';
  return 'Vui lòng kiểm tra phân loại độ tuổi trước khi đặt vé.';
}

class MovieDetailIntroduction extends StatelessWidget {
  const MovieDetailIntroduction({super.key, required this.movie});
  final Movie movie;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        movie.title,
        key: ValueKey('movie-detail-title-${movie.id}'),
        style: AppTextStyles.screenTitle,
      ),
      const SizedBox(height: 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 88,
            height: 132,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: AppRadii.control,
            ),
            child: AppImage(
              asset: movie.posterAsset,
              fit: BoxFit.contain,
              semanticLabel: 'Poster ${movie.title}',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AgeBadge(rating: movie.ageRating),
                    Text(movie.duration, style: AppTextStyles.body),
                    if (movie.format.trim().isNotEmpty)
                      Text(movie.format, style: AppTextStyles.body),
                  ],
                ),
                const SizedBox(height: 10),
                if (movie.releaseDate != null) ...[
                  Text(
                    'Khởi chiếu: ${movie.releaseDate!.day.toString().padLeft(2, '0')}/${movie.releaseDate!.month.toString().padLeft(2, '0')}/${movie.releaseDate!.year}',
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  movie.genre,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.goldSurface,
          borderRadius: AppRadii.control,
          border: Border.all(color: AppColors.goldBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: AppColors.gold,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _ageDescription(movie.ageRating),
                style: AppTextStyles.body,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class MovieSynopsis extends StatefulWidget {
  const MovieSynopsis({super.key, required this.text});
  final String text;
  @override
  State<MovieSynopsis> createState() => _MovieSynopsisState();
}

class _MovieSynopsisState extends State<MovieSynopsis> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Nội dung phim', style: AppTextStyles.sectionTitle),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, constraints) {
          final text = widget.text.trim().isEmpty
              ? 'Nội dung phim đang được cập nhật.'
              : widget.text.trim();
          final bodyStyle = DefaultTextStyle.of(context).style
              .merge(AppTextStyles.body);
          final painter = TextPainter(
            text: TextSpan(text: text, style: bodyStyle),
            maxLines: 4,
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout(maxWidth: constraints.maxWidth);
          final canExpand = painter.didExceedMaxLines;
          painter.dispose();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                maxLines: _expanded ? null : 4,
                overflow: _expanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: bodyStyle,
              ),
              if (canExpand)
                TextButton(
                  key: const ValueKey('movie-synopsis-toggle'),
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(_expanded ? 'Thu gọn' : 'Xem thêm'),
                ),
            ],
          );
        },
      ),
    ],
  );
}

class MovieCredits extends StatelessWidget {
  const MovieCredits({super.key, required this.movie});
  final Movie movie;
  String value(String? text) =>
      text?.trim().isNotEmpty == true ? text!.trim() : 'Đang cập nhật';
  @override
  Widget build(BuildContext context) => CheckoutSection(
    title: 'Thông tin phim',
    children: [
      CheckoutLine('Đạo diễn', value(movie.director), stacked: true),
      CheckoutLine('Diễn viên', value(movie.cast), stacked: true),
      CheckoutLine('Ngôn ngữ', value(movie.language)),
      if (movie.subtitleLanguage?.trim().isNotEmpty == true)
        CheckoutLine('Phụ đề', movie.subtitleLanguage!),
    ],
  );
}

class MovieSectionNotice extends StatelessWidget {
  const MovieSectionNotice({
    super.key,
    required this.label,
    this.onRetry,
    this.retryKey,
    this.skeleton = false,
  });
  final String label;
  final VoidCallback? onRetry;
  final Key? retryKey;
  final bool skeleton;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    margin: const EdgeInsets.only(bottom: 10),
    decoration: const BoxDecoration(
      color: AppColors.surfaceRaised,
      borderRadius: AppRadii.control,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        if (skeleton) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < 3; i++)
                Expanded(
                  child: Container(
                    height: 100,
                    margin: EdgeInsets.only(right: i == 2 ? 0 : 12),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: AppRadii.control,
                    ),
                  ),
                ),
            ],
          ),
        ],
        if (onRetry != null)
          TextButton.icon(
            key: retryKey,
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
      ],
    ),
  );
}

class MovieReviewCard extends StatelessWidget {
  const MovieReviewCard({super.key, required this.review});
  final ReviewDto review;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    margin: const EdgeInsets.only(top: 10),
    decoration: const BoxDecoration(
      color: AppColors.surfaceRaised,
      borderRadius: AppRadii.control,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(review.userName, style: AppTextStyles.cardTitle),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: [
            Text(
              '★ ${review.rating}/10',
              style: AppTextStyles.body.copyWith(color: AppColors.gold),
            ),
            if (review.verifiedBooking)
              const Text('Đã mua vé', style: AppTextStyles.caption),
          ],
        ),
        if (review.content.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(review.content, style: AppTextStyles.body),
        ],
      ],
    ),
  );
}

class RelatedMovies extends StatelessWidget {
  const RelatedMovies({super.key, required this.items});
  final List<RecommendationDto> items;
  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Phim liên quan', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        SizedBox(
          height: 188 + scaler.scale(15) * 2.8 + scaler.scale(12) * 4.2,
          child: ListView.separated(
            key: const ValueKey('movie-related-list'),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return SizedBox(
                width: 150,
                child: Material(
                  color: AppColors.surfaceRaised,
                  borderRadius: AppRadii.control,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: ValueKey('related-movie-${item.movieId}'),
                    onTap: () =>
                        context.push(AppRoutes.movieDetail(item.movieId)),
                    child: Semantics(
                      button: true,
                      label: 'Xem chi tiết ${item.title}',
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SizedBox(
                                width: double.infinity,
                                child: AppImage(
                                  asset: item.posterUrl ?? '',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (item.averageRating != null &&
                                item.averageRating! > 0)
                              Text(
                                '★ ${item.averageRating!.toStringAsFixed(1)}/10',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.gold,
                                ),
                              ),
                            if (item.reason?.trim().isNotEmpty == true)
                              Text(
                                item.reason!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
