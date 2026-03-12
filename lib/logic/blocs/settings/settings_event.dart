import 'package:equatable/equatable.dart';
import '../../../domain/entities/system_info.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {}

class SetGpuModeEvent extends SettingsEvent {
  final GpuMode mode;
  const SetGpuModeEvent(this.mode);

  @override
  List<Object?> get props => [mode];
}

class SetBatteryLimitEvent extends SettingsEvent {
  final int limit;
  const SetBatteryLimitEvent(this.limit);

  @override
  List<Object?> get props => [limit];
}

class SetPerformanceModeEvent extends SettingsEvent {
  final PerformanceMode mode;
  const SetPerformanceModeEvent(this.mode);

  @override
  List<Object?> get props => [mode];
}

class SetFanModeEvent extends SettingsEvent {
  final FanMode mode;
  const SetFanModeEvent(this.mode);

  @override
  List<Object?> get props => [mode];
}

class SetWebcamEnabledEvent extends SettingsEvent {
  final bool enabled;
  const SetWebcamEnabledEvent(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class SetSuperBatteryEvent extends SettingsEvent {
  final bool enabled;
  const SetSuperBatteryEvent(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class SetPerformanceLevelEvent extends SettingsEvent {
  final PerformanceLevel level;
  const SetPerformanceLevelEvent(this.level);

  @override
  List<Object?> get props => [level];
}
