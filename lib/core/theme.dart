import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeMode _activeThemeMode = ThemeMode.dark; // Default to dark per design.md

  static const Color primary = AppColors.primary;
  static const Color accent = AppColors.success;
  static const Color tertiary = AppColors.tertiary;

  static const Color success = AppColors.success;
  static const Color warning = AppColors.warning;
  static const Color error = AppColors.error;
  static const Color info = AppColors.info;

  static Color get glow => primary.withValues(alpha: 0.25);

  static Color get backgroundPrimary => _activeThemeMode == ThemeMode.dark
      ? AppColors.darkBackground
      : AppColors.lightBackground;
  static Color get surfaceLow => _activeThemeMode == ThemeMode.dark
      ? AppColors.darkElevated
      : AppColors.lightElevated;
  static Color get surface => _activeThemeMode == ThemeMode.dark
      ? AppColors.darkSurface
      : AppColors.lightSurface;
  static Color get surfaceHigh => _activeThemeMode == ThemeMode.dark
      ? AppColors.darkSidebar
      : AppColors.lightSidebar;

  static Color get textHighEmphasis => _activeThemeMode == ThemeMode.dark
      ? AppColors.darkTextPrimary
      : AppColors.lightTextPrimary;
  static Color get textMediumEmphasis => _activeThemeMode == ThemeMode.dark
      ? AppColors.darkTextSecondary
      : AppColors.lightTextSecondary;
  static Color get textLowEmphasis => _activeThemeMode == ThemeMode.dark
      ? AppColors.darkTextMuted
      : AppColors.lightTextMuted;

  static void setThemeMode(ThemeMode mode) {
    _activeThemeMode = mode;
  }

  static ThemeData get lightTheme => _buildTheme(isDark: false);
  static ThemeData get darkTheme => _buildTheme(isDark: true);

  static ThemeData _buildTheme({required bool isDark}) {
    final scheme = ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      tertiary: tertiary,
      onTertiary: Colors.white,
      error: error,
      onError: Colors.white,
      surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      onSurface: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      onSurfaceVariant: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      outline: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      outlineVariant: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      shadow: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
      scrim: Colors.black.withValues(alpha: 0.45),
      inverseSurface: isDark ? AppColors.lightSurface : AppColors.darkSurface,
      onInverseSurface: isDark ? AppColors.lightTextPrimary : AppColors.darkTextPrimary,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      canvasColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      fontFamily: 'Inter',
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: scheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: scheme.onSurface,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: scheme.onSurfaceVariant,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: isDark ? 2 : 1,
        shadowColor: scheme.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline,
        thickness: 1,
      ),
    );
  }
}
