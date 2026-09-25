import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_routes.dart';
import 'cinema_bottom_nav.dart';
import 'cinema_header.dart';

/// Shared chrome for the primary tabs represented in the reference design.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.body, required this.currentIndex});

  final Widget body;
  final int currentIndex;

  static const _tabRoutes = [
    AppRoutes.home,
    AppRoutes.discover,
    AppRoutes.showtimes,
    AppRoutes.orders,
    AppRoutes.account,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CinemaHeader(
        onSearch: () => context.go(AppRoutes.discover),
        onAccount: () => context.go(AppRoutes.account),
      ),
      bottomNavigationBar: CinemaBottomNav(
        currentIndex: currentIndex,
        onTap: (index) => context.go(_tabRoutes[index]),
      ),
      body: SafeArea(top: false, child: body),
    );
  }
}
