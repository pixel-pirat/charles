import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors
  static const Color primary = Color(0xFF4A6FFF);
  static const Color primaryLight = Color(0xFF6B8EFF);
  static const Color primaryGradientStart = Color(0xFF4A6FFF);
  static const Color primaryGradientEnd = Color(0xFF00C6FF);

  // Backgrounds
  static const Color background = Color(0xFFF7F8FC);
  static const Color surface = Colors.white;
  static const Color cardBackground = Colors.white;

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF8A8FA3);
  static const Color textMuted = Color(0xFFB0B4C8);

  // Misc
  static const Color divider = Color(0xFFF0F1F5);
  static const Color iconInactive = Color(0xFFB0B4C8);
  static const Color likeRed = Color(0xFFFF5A6E);
  static const Color tagGreen = Color(0xFF22C55E);
  static const Color tagBlue = Color(0xFF4A6FFF);

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: primaryGradientEnd,
        surface: surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      dividerColor: divider,
    );
  }
}
