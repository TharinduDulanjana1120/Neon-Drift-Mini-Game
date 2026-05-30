// =============================================================================
// Neon palette and Material 3 theme used across the game.
// Centralizing colors here keeps the UI consistent and easy to re-skin later.
// =============================================================================

import 'package:flutter/material.dart';

class AppTheme {
  // ---- Neon palette (Gen-Z cyberpunk) ----
  static const Color neonPink = Color(0xFFFF2D95);
  static const Color neonCyan = Color(0xFF00F0FF);
  static const Color neonPurple = Color(0xFF9D00FF);
  static const Color neonYellow = Color(0xFFFFE600);
  static const Color neonGreen = Color(0xFF00FF94);

  // ---- Backgrounds ----
  static const Color bgDark = Color(0xFF0A0014);
  static const Color bgDarker = Color(0xFF050010);
  static const Color bgTop = Color(0xFF1A0033);
  static const Color roadDark = Color(0xFF14082A);

  /// Builds the global Material 3 dark theme.
  static ThemeData darkNeonTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: neonPink,
        secondary: neonCyan,
        tertiary: neonPurple,
        surface: bgDark,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
    );
  }
}
