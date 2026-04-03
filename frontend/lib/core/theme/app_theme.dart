import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.terracotta,
      primary: AppColors.terracotta,
      secondary: AppColors.burntOrange,
      surface: AppColors.warmCream,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.mist,
      textTheme: const TextTheme(
        displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.softCharcoal, height: 1.05),
        headlineMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.softCharcoal, height: 1.1),
        titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.softCharcoal),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.softCharcoal),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.softCharcoal, height: 1.45),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF6D7380), height: 1.45),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.white),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.white,
        titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.white.withValues(alpha: 0.78),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      dividerColor: AppColors.softCharcoal.withValues(alpha: 0.08),
    );
  }
}
