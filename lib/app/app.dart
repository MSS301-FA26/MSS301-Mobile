import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/routing/app_router.dart';

class CinePremierApp extends StatelessWidget {
  const CinePremierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CinePremier',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
