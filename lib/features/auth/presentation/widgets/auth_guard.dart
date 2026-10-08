import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../application/auth_session.dart';

class AuthGuard extends ConsumerWidget {
  const AuthGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authSessionProvider);
    final authenticated = auth.isAuthenticated;
    if (auth.status == AuthStatus.initializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (authenticated) return child;
    final requestedRoute = GoRouterState.of(context).uri.toString();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.go(AppRoutes.loginWithRedirect(requestedRoute));
      }
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
