import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
import '../../application/cinema_preferences.dart';
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
    final preferredId = ref.watch(preferredCinemaProvider).value;
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
                          Container(
                            height: 150,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceRaised,
                              borderRadius: AppRadii.card,
                            ),
                            child: const Icon(
                              Icons.theaters_rounded,
                              size: 72,
                              color: AppColors.gold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(cinema.name, style: AppTextStyles.sectionTitle),
                          const SizedBox(height: 12),
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
                          const SizedBox(height: 10),
                          AppButton(
                            key: const ValueKey('cinema-preferred'),
                            label: preferredId == cinema.id
                                ? 'Bỏ rạp ưu tiên'
                                : 'Đặt làm rạp ưu tiên',
                            variant: AppButtonVariant.secondary,
                            onPressed: cinema.active
                                ? () async {
                                    try {
                                      await ref
                                          .read(
                                            preferredCinemaProvider.notifier,
                                          )
                                          .choose(
                                            preferredId == cinema.id
                                                ? null
                                                : cinema.id,
                                          );
                                    } catch (_) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Chưa lưu được rạp ưu tiên. Vui lòng thử lại.',
                                                ),
                                              ),
                                            );
                                      }
                                    }
                                  }
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
