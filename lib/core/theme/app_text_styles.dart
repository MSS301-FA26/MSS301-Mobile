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
    color: AppColors.text,
  );
  static const sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );
  static const cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );
  static const body = TextStyle(fontSize: 13, color: AppColors.textSecondary);
  static const caption = TextStyle(fontSize: 11, color: AppColors.textMuted);
  static const button = TextStyle(fontSize: 14, fontWeight: FontWeight.w700);
}
