import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
import '../cinema_visuals.dart';
import '../providers/cinema_providers.dart';

class CinemaDetailPage extends ConsumerWidget {
  const CinemaDetailPage({super.key, required this.cinemaId});

  final int cinemaId;

  Future<void> _openDirections(
    BuildContext context,
    String address,
    String city,
  ) async {
    final query = [address.trim(), city.trim()].join(', ');
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': query,
    });
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không mở được bản đồ trên thiết bị này.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(cinemaDetailProvider(cinemaId));
    return AppShell(
      currentIndex: 2,
      showBottomNavigation: false,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Quay lại',
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go(AppRoutes.cinemas),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const Expanded(
                  child: Text(
                    'Chi tiết rạp',
                    style: AppTextStyles.sectionTitle,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: result.isLoading && !result.hasValue
                ? const RepositoryStatePane.loading()
                : result.hasError
                ? RepositoryStatePane.error(
                    title: 'Chưa tải được thông tin rạp',
                    onRetry: () =>
                        ref.invalidate(cinemaDetailProvider(cinemaId)),
                  )
                : result.value == null
                ? const RepositoryStatePane.empty(title: 'Không tìm thấy rạp')
                : Builder(
                    builder: (context) {
                      final cinema = result.requireValue!;
                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 220,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                AppImage(
                                  asset: cinemaImageFor(cinema.id),
                                  borderRadius: AppRadii.card,
                                ),
                                const DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: AppRadii.card,
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0x10000000),
                                        Color(0x33000000),
                                        Color(0xE6000000),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 16,
                                  right: 16,
                                  bottom: 16,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: const BoxDecoration(
                                          color: AppColors.gold,
                                          borderRadius: AppRadii.medium,
                                        ),
                                        child: const Icon(
                                          Icons.theaters_rounded,
                                          color: AppColors.background,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              cinema.name,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTextStyles.sectionTitle,
                                            ),
                                            Text(
                                              cinema.active
                                                  ? 'ĐANG MỞ CỬA ĐÓN KHÁCH'
                                                  : 'TẠM NGỪNG HOẠT ĐỘNG',
                                              style: AppTextStyles.meta.copyWith(
                                                color: cinema.active
                                                    ? AppColors.gold
                                                    : AppColors.textMuted,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'THÔNG TIN RẠP',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (cinema.address.trim().isNotEmpty)
                            _DetailLine(
                              Icons.location_on_outlined,
                              cinema.address,
                            ),
                          if (cinema.city.trim().isNotEmpty)
                            _DetailLine(
                              Icons.location_city_outlined,
                              cinema.city,
                            ),
                          if (cinema.phone?.trim().isNotEmpty == true)
                            _DetailLine(
                              Icons.call_outlined,
                              cinema.phone!.trim(),
                            ),
                          if (!cinema.active) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Rạp hiện chưa mở bán vé.',
                              style: AppTextStyles.body,
                            ),
                          ],
                          const SizedBox(height: 24),
                          AppButton(
                            key: const ValueKey('cinema-showtimes'),
                            label: 'Xem lịch chiếu tại rạp',
                            onPressed: cinema.active
                                ? () => context.push(
                                    AppRoutes.showtimesForCinema(cinema.id),
                                  )
                                : null,
                            fullWidth: true,
                          ),
                          if (cinema.address.trim().length >= 8 &&
                              cinema.city.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            TextButton.icon(
                              onPressed: () => _openDirections(
                                context,
                                cinema.address,
                                cinema.city,
                              ),
                              icon: const Icon(Icons.directions_outlined),
                              label: const Text('Chỉ đường'),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.icon, this.value);
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.gold),
        const SizedBox(width: 10),
        Expanded(child: Text(value, style: AppTextStyles.body)),
      ],
    ),
  );
}
