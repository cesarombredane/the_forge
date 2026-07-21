import 'package:flutter/material.dart';
import 'package:the_forge/theme/app_colors.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.yellow,
      onPrimary: AppColors.background,
      secondary: AppColors.yellowSoft,
      onSecondary: AppColors.background,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: Color(0xFFCF6679),
      onError: AppColors.background,
    );

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      useMaterial3: true,
    );
  }
}
