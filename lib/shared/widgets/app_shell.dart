import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_routes.dart';
import '../../features/seat/application/booking_entry_session.dart';
import 'cinema_bottom_nav.dart';
import 'cinema_header.dart';

/// Shared chrome for the primary tabs represented in the reference design.
class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.body,
    required this.currentIndex,
    this.showBottomNavigation = true,
  });

  final Widget body;
  final int currentIndex;
  final bool showBottomNavigation;

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
      appBar: CinemaHeader(
        onHome: () => _goHome(context, ref),
        onSearch: () => context.go(AppRoutes.discover),
        onAccount: () => context.go(AppRoutes.account),
      ),
      bottomNavigationBar: showBottomNavigation
          ? CinemaBottomNav(
              currentIndex: currentIndex,
              onTap: (index) => context.go(_tabRoutes[index]),
            )
          : null,
      body: SafeArea(top: false, child: body),
    );
  }

  Future<void> _goHome(BuildContext context, WidgetRef ref) async {
    final session = ref.read(bookingEntryProvider);
    if (!session.hasActiveDraft) {
      context.go(AppRoutes.home);
      return;
    }
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quay lại Trang chủ?'),
        content: const Text(
          'Bạn có muốn dừng đặt vé và quay lại Trang chủ không?',
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
    await ref.read(bookingEntryProvider.notifier).abandon();
    if (context.mounted) context.go(AppRoutes.home);
  }
}
