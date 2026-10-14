import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../features/seat/application/booking_entry_session.dart';
import '../../features/booking/application/booking_completion_controller.dart';
import 'cinema_bottom_nav.dart';
import 'cinema_header.dart';

/// Shared chrome for the primary tabs represented in the reference design.
class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.body,
    required this.currentIndex,
    this.showBottomNavigation = true,
    this.bookingTitle,
    this.bookingSubtitle,
    this.onBookingBack,
  });

  final Widget body;
  final int currentIndex;
  final bool showBottomNavigation;
  final String? bookingTitle;
  final String? bookingSubtitle;
  final VoidCallback? onBookingBack;

  static const _tabRoutes = [
    AppRoutes.home,
    AppRoutes.discover,
    AppRoutes.showtimes,
    AppRoutes.orders,
    AppRoutes.account,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: bookingTitle != null
          ? AppBar(
              key: const ValueKey('booking-header'),
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              toolbarHeight:
                  56 *
                  (MediaQuery.textScalerOf(context).scale(16) / 16).clamp(
                    1.0,
                    1.8,
                  ),
              leading: IconButton(
                key: const ValueKey('booking-header-back'),
                tooltip: 'Quay lại',
                onPressed: onBookingBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    bookingTitle!,
                    style: AppTextStyles.cardTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (bookingSubtitle != null)
                    Text(bookingSubtitle!, style: AppTextStyles.caption),
                ],
              ),
              actions: [
                IconButton(
                  key: const ValueKey('header-home-logo'),
                  tooltip: 'Về trang chủ',
                  onPressed: () => _navigate(context, ref, AppRoutes.home),
                  icon: const Icon(Icons.home_outlined),
                ),
              ],
            )
          : CinemaHeader(
              onHome: () => _navigate(context, ref, AppRoutes.home),
              onSearch: () => _navigate(context, ref, AppRoutes.discover),
              onAccount: () => _navigate(context, ref, AppRoutes.account),
            ),
      bottomNavigationBar: showBottomNavigation
          ? CinemaBottomNav(
              currentIndex: currentIndex,
              onTap: (index) => _navigate(context, ref, _tabRoutes[index]),
            )
          : null,
      body: SafeArea(
        top: false,
        child: ColoredBox(color: AppColors.background, child: body),
      ),
    );
  }

  Future<void> _navigate(
    BuildContext context,
    WidgetRef ref,
    String route,
  ) async {
    final completion = ref.read(bookingCompletionProvider);
    if (completion.isBusy) return;
    if (completion.payment != null &&
        completion.phase != BookingCompletionPhase.ticketReady) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Rời màn hình thanh toán?'),
          content: const Text(
            'Đơn vẫn được lưu. Bạn có thể kiểm tra kết quả trong Đơn của tôi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Ở lại'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Rời đi'),
            ),
          ],
        ),
      );
      if (leave == true && context.mounted) {
        ref.invalidate(bookingEntryProvider);
        ref.invalidate(bookingCompletionProvider);
        context.go(route);
      }
      return;
    }
    final session = ref.read(bookingEntryProvider);
    if (!session.hasActiveDraft) {
      context.go(route);
      return;
    }
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dừng đặt vé?'),
        content: const Text(
          'Bạn có muốn rời luồng đặt vé? Ghế đang giữ sẽ được giải phóng.',
        ),
        actions: [
          OutlinedButton(
            key: const ValueKey('booking-leave-yes'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Có'),
          ),
          FilledButton(
            key: const ValueKey('booking-leave-no'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Không'),
          ),
        ],
      ),
    );
    if (shouldLeave != true || !context.mounted) return;
    final left = await ref.read(bookingEntryProvider.notifier).abandon();
    if (!context.mounted) return;
    if (!left) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(bookingEntryProvider).message ??
                'Chưa thể hủy giữ ghế. Vui lòng thử lại.',
          ),
        ),
      );
      return;
    }
    ref.invalidate(bookingCompletionProvider);
    context.go(route);
  }
}
