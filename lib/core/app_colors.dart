import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand tokens aligned to the provided design palette.
  static const Color primary = Color(0xFF7B2CBF);
  static const Color secondary = Color(0xFF1A1A2E);
  static const Color tertiary = Color(0xFF7E4D00);

  // Semantic tokens.
  static const Color success = Color(0xFF21885C);
  static const Color warning = Color(0xFFCC7A00);
  static const Color error = Color(0xFFC6284F);
  static const Color info = Color(0xFF2D7FF9);

  // Light theme surfaces/text.
  static const Color lightBackground = Color(0xFFF8F9FE);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceLow = Color(0xFFF1F2F7);
  static const Color lightSurfaceHigh = Color(0xFFE7EAF3);
  static const Color lightOutline = Color(0xFFD7DBE8);
  static const Color lightTextHigh = Color(0xFF171827);
  static const Color lightTextMedium = Color(0xFF5D6073);
  static const Color lightTextLow = Color(0xFF8D91A4);

  // Dark theme surfaces/text.
  static const Color darkBackground = Color(0xFF0C0C1F);
  static const Color darkSurface = Color(0xFF17172F);
  static const Color darkSurfaceLow = Color(0xFF111127);
  static const Color darkSurfaceHigh = Color(0xFF23233F);
  static const Color darkOutline = Color(0xFF46465C);
  static const Color darkTextHigh = Color(0xFFE5E3FF);
  static const Color darkTextMedium = Color(0xFFAAA8C3);
  static const Color darkTextLow = Color(0xFF74738B);
}
