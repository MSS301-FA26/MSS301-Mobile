import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'cinema_bottom_nav.dart';
import 'cinema_header.dart';

/// Shared chrome for the primary tabs represented in the reference design.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.body,
    required this.onUnavailable,
    required this.currentIndex,
  });

  final Widget body;
  final void Function(String feature) onUnavailable;
  final int currentIndex;

  static const _tabRoutes = [
    '/home',
    '/discover',
    '/showtimes',
    '/orders',
    '/account',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CinemaHeader(onUnavailable: onUnavailable),
      bottomNavigationBar: CinemaBottomNav(
        currentIndex: currentIndex,
        onTap: (index) => context.go(_tabRoutes[index]),
      ),
      body: SafeArea(top: false, child: body),
    );
  }
}
