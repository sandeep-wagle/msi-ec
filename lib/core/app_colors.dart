import 'package:flutter/material.dart';

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
    required this.surfaceElevated,
    required this.border,
    required this.textMuted,
    required this.gaugeBackground,
    required this.gaugeTrack,
    required this.cardBackground,
  });

  final Color performance;
  final Color balanced;
  final Color silent;
  final Color superBattery;
  final Color success;
  final Color warning;
  final Color tempCool;
  final Color tempWarm;
  final Color tempHot;
  final Color surfaceElevated;
  final Color border;
  final Color textMuted;
  final Color gaugeBackground;
  final Color gaugeTrack;
  final Color cardBackground;

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
    Color? surfaceElevated,
    Color? border,
    Color? textMuted,
    Color? gaugeBackground,
    Color? gaugeTrack,
    Color? cardBackground,
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
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      border: border ?? this.border,
      textMuted: textMuted ?? this.textMuted,
      gaugeBackground: gaugeBackground ?? this.gaugeBackground,
      gaugeTrack: gaugeTrack ?? this.gaugeTrack,
      cardBackground: cardBackground ?? this.cardBackground,
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
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      border: Color.lerp(border, other.border, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      gaugeBackground: Color.lerp(gaugeBackground, other.gaugeBackground, t)!,
      gaugeTrack: Color.lerp(gaugeTrack, other.gaugeTrack, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
    );
  }

  static const dark = AppColors(
    performance: Color(0xFFEB1D24),
    balanced: Color(0xFF3B82F6),
    silent: Color(0xFF22C55E),
    superBattery: Color(0xFFA78BFA),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    tempCool: Color(0xFF22C55E),
    tempWarm: Color(0xFFF59E0B),
    tempHot: Color(0xFFEF4444),
    surfaceElevated: Color(0xFF0F0F2E),
    border: Color(0x26EB1D24),
    textMuted: Color(0xFF64748B),
    gaugeBackground: Color(0xFF050510),
    gaugeTrack: Color(0x1AFFFFFF),
    cardBackground: Color(0xFF080820),
  );

  static const light = AppColors(
    performance: Color(0xFFC41E24),
    balanced: Color(0xFF2563EB),
    silent: Color(0xFF16A34A),
    superBattery: Color(0xFF7C3AED),
    success: Color(0xFF16A34A),
    warning: Color(0xFFD97706),
    tempCool: Color(0xFF059669),
    tempWarm: Color(0xFFEA580C),
    tempHot: Color(0xFFDC2626),
    surfaceElevated: Color(0xFFFAFAF8),
    border: Color(0x1AC41E24),
    textMuted: Color(0xFF888888),
    gaugeBackground: Color(0xFFF5F4F0),
    gaugeTrack: Color(0xFFE8E6E1),
    cardBackground: Color(0xFFFFFFFF),
  );
}
