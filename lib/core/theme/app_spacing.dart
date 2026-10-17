import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const section = 40.0;
  static const pageGutter = 16.0;
  static const cardGap = 12.0;
  static const compactGap = xs;
  static const listGap = sm;
  static const cardPadding = md;
  static const sectionGap = section;
  static const pageHorizontal = pageGutter;

  static const headerHeight = 64.0;
  static const bottomBarHeight = 64.0;
  static const heroHeight = 398.0;
  static const quickActionHeight = 116.0;
  static const movieCardWidth = 160.0;
}

abstract final class AppSizes {
  static const iconSmall = 16.0;
  static const iconMedium = 20.0;
  static const iconLarge = 24.0;
  static const iconDisplay = 32.0;
  static const iconFallback = 36.0;
  static const stateIcon = 44.0;
  static const seatTouchTarget = 44.0;
  static const badgeHorizontalPadding = 6.0;
  static const badgeVerticalPadding = 3.0;

  static const buttonHeight = 48.0;
  static const inputHeight = 52.0;
  static const posterAspectRatio = 2 / 3;
  static const backdropAspectRatio = 16 / 9;
}

abstract final class AppRadii {
  static const small = BorderRadius.all(Radius.circular(8));
  static const medium = BorderRadius.all(Radius.circular(12));
  static const large = BorderRadius.all(Radius.circular(16));
  static const pill = BorderRadius.all(Radius.circular(999));

  // Backward-compatible semantic names used by existing feature widgets.
  static const card = large;
  static const control = medium;
}
