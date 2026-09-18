import 'package:flutter/material.dart';

import 'cinema_bottom_nav.dart';
import 'cinema_header.dart';

/// Shared chrome for the primary tabs represented in the reference design.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.body, required this.onUnavailable});

  final Widget body;
  final void Function(String feature) onUnavailable;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CinemaHeader(onUnavailable: onUnavailable),
      bottomNavigationBar: CinemaBottomNav(onUnavailable: onUnavailable),
      body: SafeArea(top: false, child: body),
    );
  }
}
