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
    required this.cardBackground,
    required this.border,
    required this.gaugeTrack,
    required this.surfaceElevated,
    required this.glassBg,
    required this.glassBorder,
    required this.glassHighlight,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.liquidStart,
    required this.liquidMid,
    required this.liquidEnd,
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

  final Color cardBackground;
  final Color border;
  final Color gaugeTrack;
  final Color surfaceElevated;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  final Color glassBg;
  final Color glassBorder;
  final Color glassHighlight;
  final Color liquidStart;
  final Color liquidMid;
  final Color liquidEnd;

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
    Color? cardBackground,
    Color? border,
    Color? gaugeTrack,
    Color? surfaceElevated,
    Color? glassBg,
    Color? glassBorder,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? glassHighlight,
    Color? liquidStart,
    Color? liquidMid,
    Color? liquidEnd,
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
      cardBackground: cardBackground ?? this.cardBackground,
      border: border ?? this.border,
      gaugeTrack: gaugeTrack ?? this.gaugeTrack,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      glassBg: glassBg ?? this.glassBg,
      glassBorder: glassBorder ?? this.glassBorder,
      glassHighlight: glassHighlight ?? this.glassHighlight,
      liquidStart: liquidStart ?? this.liquidStart,
      liquidMid: liquidMid ?? this.liquidMid,
      liquidEnd: liquidEnd ?? this.liquidEnd,
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
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      border: Color.lerp(border, other.border, t)!,
      gaugeTrack: Color.lerp(gaugeTrack, other.gaugeTrack, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      glassBg: Color.lerp(glassBg, other.glassBg, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassHighlight: Color.lerp(glassHighlight, other.glassHighlight, t)!,
      liquidStart: Color.lerp(liquidStart, other.liquidStart, t)!,
      liquidMid: Color.lerp(liquidMid, other.liquidMid, t)!,
      liquidEnd: Color.lerp(liquidEnd, other.liquidEnd, t)!,
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
    cardBackground: Color(0xFFFFFFFF),
    border: Color(0xFFE2E8F0),
    gaugeTrack: Color(0xFFE2E8F0),
    surfaceElevated: Color(0xFFF8FAFC),
    textPrimary: Color(0xFF1E293B),
    textSecondary: Color(0xFF64748B),
    textTertiary: Color(0xFF94A3B8),
    glassBg: Color(0x99FFFFFF),
    glassBorder: Color(0x4DFFFFFF),
    glassHighlight: Color(0x33FFFFFF),
    liquidStart: Color(0xFF2563EB),
    liquidMid: Color(0xFF7C3AED),
    liquidEnd: Color(0xFFDC2626),
  );

  static const dark = AppColors(
    performance: Color(0xFFEF4444),
    balanced: Color(0xFF3B82F6),
    silent: Color(0xFF22C55E),
    superBattery: Color(0xFFC084FC),
    success: Color(0xFF22C55E),
    warning: Color(0xFFFBBF24),
    tempCool: Color(0xFF34D399),
    tempWarm: Color(0xFFFB923C),
    tempHot: Color(0xFFF87171),
    cardBackground: Color(0xFF0A0A1E),
    border: Color(0x15FFFFFF),
    gaugeTrack: Color(0x15FFFFFF),
    surfaceElevated: Color(0xFF0D0D2B),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    textTertiary: Color(0xFF64748B),
    glassBg: Color(0xBB0A0A1E),
    glassBorder: Color(0x550A0A1E),
    glassHighlight: Color(0x0AFFFFFF),
    liquidStart: Color(0x22EB1D24),
    liquidMid: Color(0x182A0A8B),
    liquidEnd: Color(0x12050510),
  );
}
