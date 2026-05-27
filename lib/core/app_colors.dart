import 'package:flutter/material.dart';

// ThemeExtension holding MSI brand and semantic colors
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.performance,
    required this.balanced,
    required this.silent,
    required this.superBattery,
    required this.success,
    required this.warning,
    required this.tempCool,
    required this.tempWarm,
    required this.tempHot,
  });

  final Color performance; // MSI red
  final Color balanced; // blue
  final Color silent; // green
  final Color superBattery; // purple

  final Color success;
  final Color warning;

  final Color tempCool;
  final Color tempWarm;
  final Color tempHot;

  @override
  AppColors copyWith({
    Color? performance,
    Color? balanced,
    Color? silent,
    Color? superBattery,
    Color? success,
    Color? warning,
    Color? tempCool,
    Color? tempWarm,
    Color? tempHot,
  }) {
    return AppColors(
      performance: performance ?? this.performance,
      balanced: balanced ?? this.balanced,
      silent: silent ?? this.silent,
      superBattery: superBattery ?? this.superBattery,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      tempCool: tempCool ?? this.tempCool,
      tempWarm: tempWarm ?? this.tempWarm,
      tempHot: tempHot ?? this.tempHot,
    );
  }

  @override
  AppColors lerp(covariant ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      performance: Color.lerp(performance, other.performance, t)!,
      balanced: Color.lerp(balanced, other.balanced, t)!,
      silent: Color.lerp(silent, other.silent, t)!,
      superBattery: Color.lerp(superBattery, other.superBattery, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      tempCool: Color.lerp(tempCool, other.tempCool, t)!,
      tempWarm: Color.lerp(tempWarm, other.tempWarm, t)!,
      tempHot: Color.lerp(tempHot, other.tempHot, t)!,
    );
  }

  static const light = AppColors(
    performance: Color(0xFFDC2626),
    balanced: Color(0xFF2563EB),
    silent: Color(0xFF16A34A),
    superBattery: Color(0xFFA78BFA),
    success: Color(0xFF16A34A),
    warning: Color(0xFFF59E0B),
    tempCool: Color(0xFF2DD4BF),
    tempWarm: Color(0xFFF97316),
    tempHot: Color(0xFFEF4444),
  );

  static const dark = AppColors(
    performance: Color(0xFFEF4444), // Brighter red for dark theme
    balanced: Color(0xFF3B82F6),
    silent: Color(0xFF22C55E),
    superBattery: Color(0xFFC084FC),
    success: Color(0xFF22C55E),
    warning: Color(0xFFFBBF24),
    tempCool: Color(0xFF34D399),
    tempWarm: Color(0xFFFB923C),
    tempHot: Color(0xFFF87171),
  );
}
