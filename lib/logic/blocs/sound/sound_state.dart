import 'package:equatable/equatable.dart';

class SoundState extends Equatable {
  final String profile;
  final List<double> eqGains;
  final bool virtualSurround;
  final bool bassBoost;
  final bool voiceClarity;
  final bool trebleEnhancer;
  final bool smartVolume;
  final double stereoWidth;
  final double volumeBoost;
  final int sampleRate;
  final bool isLoading;
  // Individual dB gain levels for the Voices/Bass/Treble panels (0–12)
  final double bassGain;
  final double trebleGain;
  final double voiceGain;

  const SoundState({
    required this.profile,
    required this.eqGains,
    required this.virtualSurround,
    required this.bassBoost,
    required this.voiceClarity,
    required this.trebleEnhancer,
    this.smartVolume = false,
    this.stereoWidth = 0.5,
    this.volumeBoost = 1.0,
    this.sampleRate = 48000,
    this.isLoading = false,
    this.bassGain = 0.0,
    this.trebleGain = 0.0,
    this.voiceGain = 0.0,
  });

  factory SoundState.initial() {
    return SoundState(
      profile: 'Gaming',
      eqGains: List.generate(10, (index) => 0.0),
      virtualSurround: true,
      bassBoost: false,
      voiceClarity: true,
      trebleEnhancer: false,
      smartVolume: false,
      stereoWidth: 0.5,
      volumeBoost: 1.0,
      sampleRate: 48000,
      bassGain: 0.0,
      trebleGain: 0.0,
      voiceGain: 0.0,
    );
  }

  SoundState copyWith({
    String? profile,
    List<double>? eqGains,
    bool? virtualSurround,
    bool? bassBoost,
    bool? voiceClarity,
    bool? trebleEnhancer,
    bool? smartVolume,
    double? stereoWidth,
    double? volumeBoost,
    int? sampleRate,
    bool? isLoading,
    double? bassGain,
    double? trebleGain,
    double? voiceGain,
  }) {
    return SoundState(
      profile: profile ?? this.profile,
      eqGains: eqGains ?? this.eqGains,
      virtualSurround: virtualSurround ?? this.virtualSurround,
      bassBoost: bassBoost ?? this.bassBoost,
      voiceClarity: voiceClarity ?? this.voiceClarity,
      trebleEnhancer: trebleEnhancer ?? this.trebleEnhancer,
      smartVolume: smartVolume ?? this.smartVolume,
      stereoWidth: stereoWidth ?? this.stereoWidth,
      volumeBoost: volumeBoost ?? this.volumeBoost,
      sampleRate: sampleRate ?? this.sampleRate,
      isLoading: isLoading ?? this.isLoading,
      bassGain: bassGain ?? this.bassGain,
      trebleGain: trebleGain ?? this.trebleGain,
      voiceGain: voiceGain ?? this.voiceGain,
    );
  }

  @override
  List<Object?> get props => [
    profile,
    eqGains,
    virtualSurround,
    bassBoost,
    voiceClarity,
    trebleEnhancer,
    smartVolume,
    stereoWidth,
    volumeBoost,
    sampleRate,
    isLoading,
    bassGain,
    trebleGain,
    voiceGain,
  ];
}
