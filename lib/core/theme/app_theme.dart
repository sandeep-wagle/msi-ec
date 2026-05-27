import 'package:flutter/material.dart';
import '../app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF050510),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFEB1D24),
        surface: Color(0xFF050510),
        onSurface: Color(0xFFFFFFFF),
        onSurfaceVariant: Color(0xFF94A3B8),
        outline: Color(0x26EB1D24),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: const Color(0xFFEB1D24).withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        color: const Color(0xFF080820),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF050510),
        indicatorColor: const Color(0xFFEB1D24).withValues(alpha: 0.15),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFFEB1D24),
              letterSpacing: 0.3,
            );
          }
          return const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            letterSpacing: 0.3,
          );
        }),
      ),
      extensions: const <ThemeExtension<dynamic>>[AppColors.dark],
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF050510),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: const Color(0xFFEB1D24).withValues(alpha: 0.08),
        thickness: 1,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          color: Color(0xFFCBD5E1),
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          color: Color(0xFF94A3B8),
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFFEB1D24),
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Color(0xFF64748B),
          letterSpacing: 0.5,
        ),
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFF94A3B8),
        size: 20,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFEB1D24);
          }
          return const Color(0xFF475569);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFEB1D24).withValues(alpha: 0.3);
          }
          return const Color(0xFF1E293B);
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: const Color(0xFFEB1D24),
        inactiveTrackColor: const Color(0xFF1E293B),
        thumbColor: const Color(0xFFEB1D24),
        overlayColor: const Color(0xFFEB1D24).withValues(alpha: 0.12),
        activeTickMarkColor: const Color(0xFFEB1D24).withValues(alpha: 0.5),
        inactiveTickMarkColor: const Color(0xFF475569),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEB1D24),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFEB1D24),
          side: const BorderSide(
            color: Color(0x33EB1D24),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0F0F2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEB1D24), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 13),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF0F0F2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0x1AFFFFFF)),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F4F0),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFC41E24),
        brightness: Brightness.light,
        primary: const Color(0xFFC41E24),
        surface: const Color(0xFFF5F4F0),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        color: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFFF5F4F0),
        indicatorColor: const Color(0xFFC41E24).withValues(alpha: 0.1),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFFC41E24),
            );
          }
          return const TextStyle(fontSize: 12, color: Color(0xFF888888));
        }),
      ),
      extensions: const <ThemeExtension<dynamic>>[AppColors.light],
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF5F4F0),
        foregroundColor: Color(0xFF1A1A1A),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.black.withValues(alpha: 0.06),
        thickness: 1,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A1A),
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          color: Color(0xFF444444),
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          color: Color(0xFF666666),
        ),
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFF666666),
        size: 20,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFC41E24);
          }
          return Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFC41E24).withValues(alpha: 0.3);
          }
          return Colors.grey.shade300;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: const Color(0xFFC41E24),
        inactiveTrackColor: Colors.grey.shade300,
        thumbColor: const Color(0xFFC41E24),
        overlayColor: const Color(0xFFC41E24).withValues(alpha: 0.12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC41E24),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFC41E24), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
