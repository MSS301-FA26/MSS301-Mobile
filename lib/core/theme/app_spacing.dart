import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  static const headerHeight = 64.0;
  static const bottomBarHeight = 64.0;
  static const heroHeight = 398.0;
  static const quickActionHeight = 116.0;
  static const movieCardWidth = 160.0;
}

abstract final class AppRadii {
  static const card = BorderRadius.all(Radius.circular(16));
  static const control = BorderRadius.all(Radius.circular(12));
  static const small = BorderRadius.all(Radius.circular(8));
}
