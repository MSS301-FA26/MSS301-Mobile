import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

export 'app_colors.dart';
export 'app_spacing.dart';
export 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.gold,
      onPrimary: AppColors.background,
      secondary: AppColors.lavender,
      onSecondary: AppColors.deepPurple,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      outline: AppColors.border,
      error: AppColors.error,
      onError: AppColors.text,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Inter',
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      splashColor: AppColors.gold.withValues(alpha: 0.12),
      dividerColor: AppColors.border,
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.card),
      ),
      textTheme: const TextTheme(
        displaySmall: AppTextStyles.heroTitle,
        headlineSmall: AppTextStyles.screenTitle,
        titleLarge: AppTextStyles.sectionTitle,
        titleMedium: AppTextStyles.cardTitle,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.caption,
        labelMedium: AppTextStyles.label,
        labelLarge: AppTextStyles.button,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.background,
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.control),
          textStyle: AppTextStyles.button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceHigh,
        labelStyle: AppTextStyles.label,
        hintStyle: AppTextStyles.caption,
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.border),
          borderRadius: AppRadii.control,
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.focus, width: 1.5),
          borderRadius: AppRadii.control,
        ),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.error),
          borderRadius: AppRadii.control,
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
          borderRadius: AppRadii.control,
        ),
      ),
    );
  }
}
