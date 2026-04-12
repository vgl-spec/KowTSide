import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeMode _activeThemeMode = ThemeMode.light;

  // Brand colors
  static const Color primary = AppColors.primary;
  static const Color accent = AppColors.success;
  static const Color tertiary = AppColors.tertiary;

  // Semantic colors
  static const Color success = AppColors.success;
  static const Color warning = AppColors.warning;
  static const Color error = AppColors.error;
  static const Color info = AppColors.info;

  static Color get glow => primary.withOpacity(0.25);

  // Surface and text tokens resolve dynamically for the current mode.
  static Color get backgroundPrimary => _activeThemeMode == ThemeMode.dark
      ? AppColors.darkBackground
      : AppColors.lightBackground;
  static Color get surfaceLow => _activeThemeMode == ThemeMode.dark
      ? AppColors.darkSurfaceLow
      : AppColors.lightSurfaceLow;
  static Color get surface => _activeThemeMode == ThemeMode.dark
      ? AppColors.darkSurface
      : AppColors.lightSurface;
  static Color get surfaceHigh => _activeThemeMode == ThemeMode.dark
      ? AppColors.darkSurfaceHigh
      : AppColors.lightSurfaceHigh;

  static Color get textHighEmphasis => _activeThemeMode == ThemeMode.dark
      ? AppColors.darkTextHigh
      : AppColors.lightTextHigh;
  static Color get textMediumEmphasis => _activeThemeMode == ThemeMode.dark
      ? AppColors.darkTextMedium
      : AppColors.lightTextMedium;
  static Color get textLowEmphasis => _activeThemeMode == ThemeMode.dark
      ? AppColors.darkTextLow
      : AppColors.lightTextLow;

  static void setThemeMode(ThemeMode mode) {
    _activeThemeMode = mode;
  }

  static ThemeData get lightTheme => _buildTheme(isDark: false);
  static ThemeData get darkTheme => _buildTheme(isDark: true);

  static ThemeData _buildTheme({required bool isDark}) {
    final scheme = ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: primary,
      onPrimary: isDark ? const Color(0xFF130022) : Colors.white,
      primaryContainer: isDark
          ? const Color(0xFF57207B)
          : const Color(0xFFECDCF9),
      onPrimaryContainer: isDark
          ? const Color(0xFFF2E1FF)
          : const Color(0xFF2B0A44),
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: isDark
          ? const Color(0xFF2A2A47)
          : const Color(0xFFE6E8F3),
      onSecondaryContainer: isDark
          ? const Color(0xFFE6E8F6)
          : const Color(0xFF121326),
      tertiary: tertiary,
      onTertiary: Colors.white,
      tertiaryContainer: isDark
          ? const Color(0xFF5A3910)
          : const Color(0xFFFFE4C8),
      onTertiaryContainer: isDark
          ? const Color(0xFFFFDFC0)
          : const Color(0xFF3E2300),
      error: error,
      onError: Colors.white,
      errorContainer: isDark
          ? const Color(0xFF7A1A39)
          : const Color(0xFFFFD7E1),
      onErrorContainer: isDark
          ? const Color(0xFFFFD9E1)
          : const Color(0xFF3D0013),
      surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      onSurface: isDark ? AppColors.darkTextHigh : AppColors.lightTextHigh,
      onSurfaceVariant: isDark
          ? AppColors.darkTextMedium
          : AppColors.lightTextMedium,
      outline: isDark ? AppColors.darkOutline : AppColors.lightOutline,
      outlineVariant: isDark
          ? const Color(0xFF373751)
          : const Color(0xFFE2E5EE),
      shadow: Colors.black.withOpacity(isDark ? 0.34 : 0.08),
      scrim: Colors.black.withOpacity(0.45),
      inverseSurface: isDark ? AppColors.lightSurface : AppColors.secondary,
      onInverseSurface: isDark ? AppColors.secondary : AppColors.lightSurface,
      inversePrimary: isDark
          ? const Color(0xFFD8B3F7)
          : const Color(0xFF9B57D0),
      surfaceTint: primary,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      canvasColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      fontFamily: 'Inter',
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.2,
        color: scheme.onSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        color: scheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.45,
        color: scheme.onSurface,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: scheme.onSurfaceVariant,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        fontFamily: 'monospace',
        color: scheme.onSurfaceVariant,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: surfaceHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outline.withOpacity(0.32), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLow,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline.withOpacity(0.55)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline.withOpacity(0.55)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle: TextStyle(color: textLowEmphasis),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shadowColor: glow,
          elevation: 1,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceLow,
        selectedColor: primary.withOpacity(0.16),
        side: BorderSide(color: scheme.outline.withOpacity(0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: TextStyle(color: scheme.onSurface, fontSize: 12),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(surfaceLow),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withOpacity(0.08);
          }
          return surfaceHigh;
        }),
        headingTextStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        dataTextStyle: TextStyle(color: scheme.onSurface, fontSize: 13),
        dividerThickness: 0.4,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        selectedIconTheme: const IconThemeData(color: primary),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: const TextStyle(
          color: primary,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelTextStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withOpacity(0.16),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary);
          }
          return IconThemeData(color: scheme.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            );
          }
          return TextStyle(color: scheme.onSurfaceVariant, fontSize: 12);
        }),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline.withOpacity(0.35),
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? AppColors.darkSurfaceHigh
            : AppColors.secondary,
        contentTextStyle: TextStyle(
          color: isDark ? AppColors.darkTextHigh : Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
