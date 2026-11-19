import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:msi_controller/domain/entities/system_info.dart';

class SettingsState extends Equatable {
  final GpuMode gpuMode;
  final int batteryLimit;
  final PerformanceMode performanceMode;
  final bool webcamEnabled;
  final bool superBatteryEnabled;
  final FanMode fanMode;
  final PerformanceLevel performanceLevel;
  final FanMode? userFanMode;
  final bool isLoading;
  final bool isGpuLoading;
  final bool isFanLoading;
  final bool isPerformanceLoading;
  final bool isGpuSwitching;

  const SettingsState({
    required this.gpuMode,
    required this.batteryLimit,
    required this.performanceMode,
    required this.webcamEnabled,
    required this.superBatteryEnabled,
    required this.fanMode,
    required this.performanceLevel,
    this.userFanMode,
    this.isLoading = false,
    this.isGpuLoading = false,
    this.isFanLoading = false,
    this.isPerformanceLoading = false,
    this.isGpuSwitching = false,
  });

  factory SettingsState.initial() {
    return const SettingsState(
      gpuMode: GpuMode.hybrid,
      batteryLimit: 100,
      performanceMode: PerformanceMode.balanced,
      webcamEnabled: false,
      superBatteryEnabled: false,
      fanMode: FanMode.auto,
      performanceLevel: PerformanceLevel.medium,
      userFanMode: null,
    );
  }

  factory SettingsState.fromPrefs(SharedPreferences prefs) {
    try {
      final jsonStr = prefs.getString('msi_settings');
      if (jsonStr == null) return SettingsState.initial();
      final map = json.decode(jsonStr);
      final parsedPerformanceMode = PerformanceMode.fromString(
        map['performanceMode'] ?? 'balanced',
      );
      return SettingsState(
        gpuMode: GpuMode.fromString(map['gpuMode'] ?? 'hybrid'),
        batteryLimit: map['batteryLimit'] ?? 100,
        performanceMode: parsedPerformanceMode == PerformanceMode.unknown
            ? PerformanceMode.balanced
            : parsedPerformanceMode,
        webcamEnabled: map['webcamEnabled'] ?? false,
        superBatteryEnabled: map['superBatteryEnabled'] ?? false,
        fanMode: FanMode.fromString(map['fanMode'] ?? 'auto'),
        performanceLevel: PerformanceLevel.fromString(
          map['performanceLevel'] ?? 'medium',
        ),
        userFanMode: map['userFanMode'] != null
            ? FanMode.fromString(map['userFanMode'])
            : null,
      );
    } catch (_) {
      return SettingsState.initial();
    }
  }

  SettingsState copyWith({
    GpuMode? gpuMode,
    int? batteryLimit,
    PerformanceMode? performanceMode,
    bool? webcamEnabled,
    bool? superBatteryEnabled,
    FanMode? fanMode,
    PerformanceLevel? performanceLevel,
    FanMode? userFanMode,
    bool? isLoading,
    bool? isGpuLoading,
    bool? isFanLoading,
    bool? isPerformanceLoading,
    bool? isGpuSwitching,
  }) {
    return SettingsState(
      gpuMode: gpuMode ?? this.gpuMode,
      batteryLimit: batteryLimit ?? this.batteryLimit,
      performanceMode: performanceMode ?? this.performanceMode,
      webcamEnabled: webcamEnabled ?? this.webcamEnabled,
      superBatteryEnabled: superBatteryEnabled ?? this.superBatteryEnabled,
      fanMode: fanMode ?? this.fanMode,
      performanceLevel: performanceLevel ?? this.performanceLevel,
      userFanMode: userFanMode ?? this.userFanMode,
      isLoading: isLoading ?? this.isLoading,
      isGpuLoading: isGpuLoading ?? this.isGpuLoading,
      isFanLoading: isFanLoading ?? this.isFanLoading,
      isPerformanceLoading: isPerformanceLoading ?? this.isPerformanceLoading,
      isGpuSwitching: isGpuSwitching ?? this.isGpuSwitching,
    );
  }

  @override
  List<Object?> get props => [
    gpuMode,
    batteryLimit,
    performanceMode,
    webcamEnabled,
    superBatteryEnabled,
    fanMode,
    performanceLevel,
    userFanMode,
    isLoading,
    isGpuLoading,
    isFanLoading,
    isPerformanceLoading,
    isGpuSwitching,
  ];
}
