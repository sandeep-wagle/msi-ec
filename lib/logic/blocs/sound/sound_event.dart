import 'package:equatable/equatable.dart';

abstract class SoundEvent extends Equatable {
  const SoundEvent();

  @override
  List<Object?> get props => [];
}

class LoadSoundSettings extends SoundEvent {}

class SetSoundProfile extends SoundEvent {
  final String profile;
  const SetSoundProfile(this.profile);

  @override
  List<Object?> get props => [profile];
}

class UpdateEQGains extends SoundEvent {
  final List<double> gains;
  const UpdateEQGains(this.gains);

  @override
  List<Object?> get props => [gains];
}

class ToggleEnhancement extends SoundEvent {
  final String enhancement;
  final bool value;
  const ToggleEnhancement(this.enhancement, this.value);

  @override
  List<Object?> get props => [enhancement, value];
}

class ChangeSampleRate extends SoundEvent {
  final int hertz;
  const ChangeSampleRate(this.hertz);

  @override
  List<Object?> get props => [hertz];
}

class ChangeStereoWidth extends SoundEvent {
  final double width;
  const ChangeStereoWidth(this.width);

  @override
  List<Object?> get props => [width];
}

class ChangeVolumeBoost extends SoundEvent {
  final double boost;
  const ChangeVolumeBoost(this.boost);

  @override
  List<Object?> get props => [boost];
}

class ChangeEffectGain extends SoundEvent {
  final String effect; // 'bass' | 'treble' | 'voice'
  final double gain; // 0.0 - 12.0 dB
  const ChangeEffectGain(this.effect, this.gain);

  @override
  List<Object?> get props => [effect, gain];
}

class SyncVolume extends SoundEvent {
  final double volume;
  const SyncVolume(this.volume);

  @override
  List<Object?> get props => [volume];
}
