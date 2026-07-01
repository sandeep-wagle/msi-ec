import 'package:equatable/equatable.dart';

abstract class SoundEvent extends Equatable {
  const SoundEvent();

  @override
  List<Object?> get props => [];
}

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

class UpdateEQGainsPreview extends SoundEvent {
  final List<double> gains;
  const UpdateEQGainsPreview(this.gains);

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

class ChangeStereoWidthPreview extends SoundEvent {
  final double width;
  const ChangeStereoWidthPreview(this.width);

  @override
  List<Object?> get props => [width];
}

class ChangeNoiseLevel extends SoundEvent {
  final double level;
  const ChangeNoiseLevel(this.level);

  @override
  List<Object?> get props => [level];
}

class ChangeNoiseLevelPreview extends SoundEvent {
  final double level;
  const ChangeNoiseLevelPreview(this.level);

  @override
  List<Object?> get props => [level];
}

class ToggleLimiter extends SoundEvent {
  final bool enabled;
  const ToggleLimiter(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class ChangeCompressorRatio extends SoundEvent {
  final double ratio;
  const ChangeCompressorRatio(this.ratio);

  @override
  List<Object?> get props => [ratio];
}

class ChangeCompressorRatioPreview extends SoundEvent {
  final double ratio;
  const ChangeCompressorRatioPreview(this.ratio);

  @override
  List<Object?> get props => [ratio];
}

class ChangeVolumeBoost extends SoundEvent {
  final double boost;
  const ChangeVolumeBoost(this.boost);

  @override
  List<Object?> get props => [boost];
}

class ChangeVolumeBoostPreview extends SoundEvent {
  final double boost;
  const ChangeVolumeBoostPreview(this.boost);

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

class ChangeEffectGainPreview extends SoundEvent {
  final String effect;
  final double gain;
  const ChangeEffectGainPreview(this.effect, this.gain);

  @override
  List<Object?> get props => [effect, gain];
}

class SyncVolume extends SoundEvent {
  final double volume;
  const SyncVolume(this.volume);

  @override
  List<Object?> get props => [volume];
}

class ChangeSurroundVariation extends SoundEvent {
  final String variation;
  const ChangeSurroundVariation(this.variation);

  @override
  List<Object?> get props => [variation];
}

class ChangeMicrophoneGain extends SoundEvent {
  final double gain;
  const ChangeMicrophoneGain(this.gain);

  @override
  List<Object?> get props => [gain];
}

class ChangeMicrophoneGainPreview extends SoundEvent {
  final double gain;
  const ChangeMicrophoneGainPreview(this.gain);

  @override
  List<Object?> get props => [gain];
}

class ResetSoundSettings extends SoundEvent {}
