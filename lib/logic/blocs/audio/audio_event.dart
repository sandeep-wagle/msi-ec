import 'package:equatable/equatable.dart';

abstract class AudioEvent extends Equatable {
  const AudioEvent();

  @override
  List<Object?> get props => [];
}

class LoadAudioDevices extends AudioEvent {}

class AudioOutputChanged extends AudioEvent {
  final String newSink;
  final String deviceType;

  const AudioOutputChanged(this.newSink, this.deviceType);

  @override
  List<Object?> get props => [newSink, deviceType];
}

class UpdateDeviceProfile extends AudioEvent {
  final String deviceId;
  final String profileName;

  const UpdateDeviceProfile(this.deviceId, this.profileName);

  @override
  List<Object?> get props => [deviceId, profileName];
}

class ToggleDeviceEffectPower extends AudioEvent {
  final String deviceId;
  final String effectType;
  final bool enabled;

  const ToggleDeviceEffectPower(this.deviceId, this.effectType, this.enabled);

  @override
  List<Object?> get props => [deviceId, effectType, enabled];
}

class UpdateDeviceEffectLevel extends AudioEvent {
  final String deviceId;
  final String effectType;
  final double level;

  const UpdateDeviceEffectLevel(this.deviceId, this.effectType, this.level);

  @override
  List<Object?> get props => [deviceId, effectType, level];
}

class SaveDeviceProfile extends AudioEvent {
  final String deviceId;

  const SaveDeviceProfile(this.deviceId);

  @override
  List<Object?> get props => [deviceId];
}

class LoadDeviceProfile extends AudioEvent {
  final String deviceId;

  const LoadDeviceProfile(this.deviceId);

  @override
  List<Object?> get props => [deviceId];
}