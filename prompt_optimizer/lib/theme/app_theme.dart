import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get dark {
    const seedColor = Color(0xFF7C3AED);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF1E293B),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F172A),
        foregroundColor: Color(0xFFF1F5F9),
        elevation: 0,
        centerTitle: false,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFF1E293B),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Color(0xFFF1F5F9)),
        displayMedium: TextStyle(color: Color(0xFFF1F5F9)),
        displaySmall: TextStyle(color: Color(0xFFF1F5F9)),
        headlineLarge: TextStyle(color: Color(0xFFF1F5F9)),
        headlineMedium: TextStyle(color: Color(0xFFF1F5F9)),
        headlineSmall: TextStyle(color: Color(0xFFF1F5F9)),
        titleLarge: TextStyle(color: Color(0xFFF1F5F9)),
        titleMedium: TextStyle(color: Color(0xFFF1F5F9)),
        titleSmall: TextStyle(color: Color(0xFFF1F5F9)),
        bodyLarge: TextStyle(color: Color(0xFFF1F5F9)),
        bodyMedium: TextStyle(color: Color(0xFF94A3B8)),
        bodySmall: TextStyle(color: Color(0xFF94A3B8)),
        labelLarge: TextStyle(color: Color(0xFFF1F5F9)),
        labelMedium: TextStyle(color: Color(0xFF94A3B8)),
        labelSmall: TextStyle(color: Color(0xFF94A3B8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: seedColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        counterStyle: const TextStyle(color: Color(0xFF64748B)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF1E293B),
        selectedColor: seedColor.withOpacity(0.3),
        labelStyle: const TextStyle(color: Color(0xFFF1F5F9)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF1E293B),
      ),
    );
  }
}
