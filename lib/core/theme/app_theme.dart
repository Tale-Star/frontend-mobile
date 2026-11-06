import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_radii.dart';
import 'app_typography.dart';

/// Configuración de temas claro y oscuro para Tale Star.
abstract class AppTheme {
  // ---------------------------------------------------------------------------
  // Modo Claro (Default)
  // ---------------------------------------------------------------------------
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: AppColors.primary900,
      primaryContainer: AppColors.primary100,
      secondary: AppColors.primary700,
      surface: AppColors.surfaceLight,
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimaryLight,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bgLight,
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.textPrimaryLight,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.md,
          side: BorderSide(color: AppColors.surface3Light, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface2Light,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: const OutlineInputBorder(
          borderRadius: AppRadii.sm,
          borderSide: BorderSide(color: AppColors.surface3Light, width: 1),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadii.sm,
          borderSide: BorderSide(color: AppColors.surface3Light, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadii.sm,
          borderSide: BorderSide(color: AppColors.primary900, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadii.sm,
          borderSide: BorderSide(color: AppColors.danger, width: 1),
        ),
        hintStyle: AppTypography.bodyMedium(color: AppColors.textTertiaryLight),
        labelStyle: AppTypography.label(color: AppColors.textSecondaryLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary900,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.sm),
          textStyle: AppTypography.button(),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor: AppColors.primary900,
        unselectedItemColor: AppColors.textTertiaryLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Modo Oscuro
  // ---------------------------------------------------------------------------
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.primary500,
      primaryContainer: AppColors.primary900,
      secondary: AppColors.primary700,
      surface: AppColors.surfaceDark,
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimaryDark,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bgDark,
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimaryDark,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.md,
          side: BorderSide(color: AppColors.surface3Dark, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface2Dark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: const OutlineInputBorder(
          borderRadius: AppRadii.sm,
          borderSide: BorderSide(color: AppColors.surface3Dark, width: 1),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadii.sm,
          borderSide: BorderSide(color: AppColors.surface3Dark, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadii.sm,
          borderSide: BorderSide(color: AppColors.primary500, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadii.sm,
          borderSide: BorderSide(color: AppColors.danger, width: 1),
        ),
        hintStyle: AppTypography.bodyMedium(color: AppColors.textTertiaryDark),
        labelStyle: AppTypography.label(color: AppColors.textSecondaryDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary700,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.sm),
          textStyle: AppTypography.button(),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primary300,
        unselectedItemColor: AppColors.textTertiaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}

/// Extensión de conveniencia para acceder reactivamente a los tokens del tema activo.
extension ThemeContextExtension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get scaffoldBg => isDarkMode ? AppColors.bgDark : AppColors.bgLight;
  Color get surfaceColor => isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight;
  Color get surface2Color => isDarkMode ? AppColors.surface2Dark : AppColors.surface2Light;
  Color get surface3Color => isDarkMode ? AppColors.surface3Dark : AppColors.surface3Light;
  Color get textPrimaryColor => isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
  Color get textSecondaryColor => isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
  Color get textTertiaryColor => isDarkMode ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
}
