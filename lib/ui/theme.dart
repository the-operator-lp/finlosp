import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF8B5CF6), // Violet
        secondary: Color(0xFF10B981), // Emerald
        surface: Color(0xFF1E293B), // Card background
        error: Color(0xFFF43F5E), // Rose
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF1E293B),
        elevation: 0,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF8B5CF6), // Violet
        secondary: Color(0xFF10B981), // Emerald
        surface: Colors.white, // Card background
        error: Color(0xFFF43F5E), // Rose
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Color(0x080F172A),
      ),
    );
  }

  static ThemeData get goldTheme {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: const Color(0xFF16130C), // Deep obsidian gold canvas
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFF59E0B), // Golden Amber
        secondary: Color(0xFFD97706), // Rich Bronze
        surface: Color(0xFF252014), // Amber-Charcoal card bg
        error: Color(0xFFF43F5E), // Rose
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF252014),
        elevation: 0,
      ),
    );
  }
}
