import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Type scale used by the native widgets; Inter is bundled in assets/fonts.
abstract final class AppTextStyles {
  static const heroTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1.1,
    color: AppColors.text,
  );
  static const screenTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1.2,
    color: AppColors.text,
  );
  static const displayTitle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    height: 1.15,
    color: AppColors.text,
  );
  static const sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.text,
  );
  static const cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.text,
  );
  static const body = TextStyle(
    fontSize: 13,
    height: 1.45,
    color: AppColors.textSecondary,
  );
  static const emphasis = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.35,
    color: AppColors.text,
  );
  static const price = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    height: 1.15,
    color: AppColors.text,
  );
  static const label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.6,
    color: AppColors.textSecondary,
  );
  static const eyebrow = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: 1.2,
    color: AppColors.textMuted,
  );
  static const caption = TextStyle(
    fontSize: 11,
    height: 1.3,
    color: AppColors.textMuted,
  );
  static const meta = TextStyle(
    fontSize: 10,
    height: 1.25,
    letterSpacing: 0.7,
    color: AppColors.textMuted,
  );
  static const button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: 0.2,
  );
}
