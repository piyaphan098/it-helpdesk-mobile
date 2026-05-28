import 'package:flutter/material.dart';

class AppColors {
  // Surfaces
  static const surface = Color(0xFF101415);
  static const surfaceDim = Color(0xFF101415);
  static const surfaceBright = Color(0xFF363a3b);
  static const surfaceContainerLowest = Color(0xFF0b0f10);
  static const surfaceContainerLow = Color(0xFF191c1e);
  static const surfaceContainer = Color(0xFF1d2022);
  static const surfaceContainerHigh = Color(0xFF272a2c);
  static const surfaceContainerHighest = Color(0xFF323537);

  // On-surface
  static const onSurface = Color(0xFFe0e3e5);
  static const onSurfaceVariant = Color(0xFFc6c6cd);
  static const outline = Color(0xFF909097);
  static const outlineVariant = Color(0xFF45464d);

  // Primary
  static const primary = Color(0xFFbec6e0);
  static const onPrimary = Color(0xFF283044);
  static const primaryContainer = Color(0xFF0f172a);
  static const onPrimaryContainer = Color(0xFF798098);

  // Secondary
  static const secondary = Color(0xFFadc6ff);
  static const onSecondary = Color(0xFF002e6a);
  static const secondaryContainer = Color(0xFF0566d9);
  static const onSecondaryContainer = Color(0xFFe6ecff);

  // Tertiary (Cyan - the main accent)
  static const tertiary = Color(0xFF2fd9f4);
  static const onTertiary = Color(0xFF00363e);
  static const tertiaryContainer = Color(0xFF001b20);
  static const onTertiaryContainer = Color(0xFF008ea1);

  // Error
  static const error = Color(0xFFffb4ab);
  static const onError = Color(0xFF690005);
  static const errorContainer = Color(0xFF93000a);

  // Background
  static const background = Color(0xFF101415);
  static const onBackground = Color(0xFFe0e3e5);
}

class AppTheme {
  static ThemeData get lightTheme => darkTheme;
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        error: AppColors.error,
        onError: AppColors.onError,
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.tertiary,
        unselectedItemColor: Color(0x99c6c6cd),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}



