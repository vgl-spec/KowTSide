import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFFCD96FF);
  static const Color accent = Color(0xFF6DFC74);
  static const Color tertiary = Color(0xFFFF7439);
  static const Color glow = Color(0x4DCD96FF);

  // Background Colors
  static const Color backgroundPrimary = Color(0xFF0C0C1F);
  static const Color surfaceLow = Color(0xFF111127);
  static const Color surface = Color(0xFF17172F);
  static const Color surfaceHigh = Color(0xFF23233F);

  // Semantic Colors
  static const Color success = Color(0xFF6DFC74);
  static const Color warning = Color(0xFFFFB74D);
  static const Color error = Color(0xFFFF6E84);
  static const Color info = Color(0xFF4FC3F7);

  // Text Colors
  static const Color textHighEmphasis = Color(0xFFE5E3FF);
  static const Color textMediumEmphasis = Color(0xFFAAA8C3);
  static const Color textLowEmphasis = Color(0xFF46465C);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Inter',
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundPrimary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        tertiary: tertiary,
        surface: surface,
        error: error,
        onPrimary: Color(0xFF47007B),
        onSecondary: Color(0xFF005E17),
        onSurface: textHighEmphasis,
        onError: Color(0xFF490013),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.5,
          color: textHighEmphasis,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: textHighEmphasis,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textHighEmphasis,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: textHighEmphasis,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.5,
          color: textHighEmphasis,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textMediumEmphasis,
        ),
        labelSmall: TextStyle(
          fontSize: 12,
          fontFamily: 'monospace',
          color: textMediumEmphasis,
        ), // Mono
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textHighEmphasis,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0x3346465C), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLow,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x6646465C)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x6646465C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: const TextStyle(color: textMediumEmphasis),
        hintStyle: const TextStyle(color: textLowEmphasis),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: const Color(0xFF47007B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shadowColor: glow,
          elevation: 2,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: const Color(0xFF47007B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceLow,
        selectedColor: primary.withOpacity(0.2),
        side: const BorderSide(color: Color(0x6646465C)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: const TextStyle(color: textHighEmphasis, fontSize: 12),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(surfaceLow),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withOpacity(0.08);
          }
          return surfaceHigh;
        }),
        headingTextStyle: const TextStyle(
          color: textMediumEmphasis,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        dataTextStyle: const TextStyle(color: textHighEmphasis, fontSize: 13),
        dividerThickness: 0.4,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: backgroundPrimary,
        selectedIconTheme: IconThemeData(color: primary),
        unselectedIconTheme: IconThemeData(color: textMediumEmphasis),
        selectedLabelTextStyle: TextStyle(
          color: primary,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelTextStyle: TextStyle(color: textMediumEmphasis),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withOpacity(0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected))
            return const IconThemeData(color: accent);
          return const IconThemeData(color: textLowEmphasis);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected))
            return const TextStyle(
              color: accent,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            );
          return const TextStyle(color: textMediumEmphasis, fontSize: 12);
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x6646465C),
        thickness: 1,
        space: 1,
      ),
    );
  }
}
