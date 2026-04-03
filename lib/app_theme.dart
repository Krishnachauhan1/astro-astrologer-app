import 'package:flutter/material.dart';
class AppColors {
  static const Color primary = Color(0xFF008080);
  static const Color primaryLight = Color(0xFF00A3A3);
  static const Color primaryDark = Color(0xFF005F5F);
  static const Color primarySurface = Color(0xFFE0F5F5);
  static const Color gold = Color(0xFFD4A853);
  static const Color goldLight = Color(0xFFF5D98A);
  static const Color background = Color(0xFFF7FAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEFF8F8);
  static const Color textPrimary = Color(0xFF0D2626);
  static const Color textSecondary = Color(0xFF4A7070);
  static const Color textHint = Color(0xFF8AADAD);
  static const Color online = Color(0xFF2ECC71);
  static const Color busy = Color(0xFFE74C3C);
  static const Color away = Color(0xFFF39C12);
  static const Color overlay = Color(0x80005F5F);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.gold,
        background: AppColors.background,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 4,
        shadowColor: AppColors.primary.withOpacity(0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        elevation: 16,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}