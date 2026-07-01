import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF3F4F6),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFEB1D24),
        brightness: Brightness.light,
        primary: const Color(0xFFEB1D24),
        surface: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        color: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: const Color(0xFFEB1D24).withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFFEB1D24),
            );
          }
          return const TextStyle(fontSize: 12, color: Colors.black54);
        }),
      ),
      extensions: const <ThemeExtension<dynamic>>[AppColors.light],
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF050510),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFEB1D24),
        brightness: Brightness.dark,
        primary: const Color(0xFFEB1D24),
        surface: const Color(0xFF0A0A1E),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        color: const Color(0xFF0A0A1E),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: const Color(0xFFEB1D24).withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            );
          }
          return const TextStyle(fontSize: 12, color: Colors.white60);
        }),
      ),
      extensions: const <ThemeExtension<dynamic>>[AppColors.dark],
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF050510),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}
