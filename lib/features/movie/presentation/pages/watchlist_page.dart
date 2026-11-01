import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
import '../../application/watchlist.dart';
import '../providers/movies_provider.dart';

class WatchlistPage extends ConsumerWidget {
  const WatchlistPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(watchlistProvider);
    return AppShell(
      currentIndex: 4,
      showBottomNavigation: false,
      body: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: IconButton(
                tooltip: 'Quay lại Tài khoản',
                onPressed: () => context.go(AppRoutes.account),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              title: const Text(
                'Danh sách muốn xem',
                style: AppTextStyles.sectionTitle,
              ),
              subtitle: const Text(
                'Chỉ lưu trên thiết bị này',
                style: AppTextStyles.caption,
              ),
            ),
            Expanded(
              child: saved.when(
                loading: () => const RepositoryStatePane.loading(
                  title: 'Đang tải phim đã lưu…',
                ),
                error: (_, _) => RepositoryStatePane.error(
                  title: 'Chưa đọc được danh sách đã lưu',
                  message:
                      'Dữ liệu trên thiết bị vẫn được giữ lại. Hãy thử lại.',
                  onRetry: () => ref.invalidate(watchlistProvider),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.favorite_border_rounded,
                              size: 48,
                              color: AppColors.gold,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Chưa lưu phim nào',
                              style: AppTextStyles.sectionTitle,
                            ),
                            const Text(
                              'Mở chi tiết phim và chọn Lưu phim.',
                              style: AppTextStyles.caption,
                            ),
                            TextButton(
                              onPressed: () => context.go(AppRoutes.discover),
                              child: const Text('Khám phá phim'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final ids = items.keys.toList()
                    ..sort((a, b) => items[b]!.compareTo(items[a]!));
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: ids.length,
                    itemBuilder: (context, index) =>
                        _SavedMovie(id: ids[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedMovie extends ConsumerWidget {
  const _SavedMovie({required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movie = ref.watch(movieProvider(id));
    final value = movie.asData?.value;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              height: 106,
              child: value == null
                  ? const Icon(Icons.movie_outlined, color: AppColors.textMuted)
                  : AppImage(asset: value.posterAsset, aspectRatio: 2 / 3),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value?.title ??
                        (movie.isLoading
                            ? 'Đang tải phim…'
                            : 'Phim không còn công khai'),
                    style: AppTextStyles.cardTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (value != null)
                    Text(
                      value.isNowShowing
                          ? 'Đang chiếu'
                          : value.isComingSoon
                          ? 'Sắp chiếu'
                          : 'Không còn mở bán',
                      style: AppTextStyles.caption,
                    ),
                  if (movie.hasError)
                    TextButton(
                      onPressed: () => ref.invalidate(movieProvider(id)),
                      child: const Text('Tải lại'),
                    ),
                  if (value != null)
                    TextButton(
                      onPressed: () => context.push(AppRoutes.movieDetail(id)),
                      child: const Text('Xem phim'),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Bỏ lưu phim',
              onPressed: () async {
                try {
                  final removed = await ref
                      .read(watchlistProvider.notifier)
                      .setSaved(id, false);
                  if (!removed || !context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Đã bỏ lưu phim'),
                      action: SnackBarAction(
                        label: 'Hoàn tác',
                        onPressed: () async {
                          try {
                            await ref
                                .read(watchlistProvider.notifier)
                                .setSaved(id, true);
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Chưa hoàn tác được. Thử lại sau.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  );
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chưa bỏ lưu được phim. Thử lại sau.'),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.favorite_rounded, color: AppColors.gold),
            ),
          ],
        ),
      ),
    );
  }
}
