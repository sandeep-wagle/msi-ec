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
  // Nahimic-style enhancements
  final double noiseLevel;
  final bool limiterEnabled;
  final double compressorRatio;
  // Additional fields
  final bool trackerEnabled;
  final bool sharingEnabled;
  final bool nightMode;
  final bool effectsEnabled;
  final bool micEnabled;
  final bool micNoiseSuppression;
  final bool echoCancellation;
  final double microphoneGain;
  final String surroundVariation;

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
    this.noiseLevel = 0.0,
    this.limiterEnabled = false,
    this.compressorRatio = 4.0,
    this.trackerEnabled = false,
    this.sharingEnabled = false,
    this.nightMode = false,
    this.effectsEnabled = true,
    this.micEnabled = true,
    this.micNoiseSuppression = true,
    this.echoCancellation = true,
    this.microphoneGain = 0.5,
    this.surroundVariation = 'Surround',
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
      noiseLevel: 0.0,
      limiterEnabled: false,
      compressorRatio: 4.0,
      trackerEnabled: false,
      sharingEnabled: false,
      nightMode: false,
      effectsEnabled: true,
      micEnabled: true,
      micNoiseSuppression: true,
      echoCancellation: true,
      microphoneGain: 0.5,
      surroundVariation: 'Surround',
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
    double? noiseLevel,
    bool? limiterEnabled,
    double? compressorRatio,
    bool? trackerEnabled,
    bool? sharingEnabled,
    bool? nightMode,
    bool? effectsEnabled,
    bool? micEnabled,
    bool? micNoiseSuppression,
    bool? echoCancellation,
    double? microphoneGain,
    String? surroundVariation,
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
      noiseLevel: noiseLevel ?? this.noiseLevel,
      limiterEnabled: limiterEnabled ?? this.limiterEnabled,
      compressorRatio: compressorRatio ?? this.compressorRatio,
      trackerEnabled: trackerEnabled ?? this.trackerEnabled,
      sharingEnabled: sharingEnabled ?? this.sharingEnabled,
      nightMode: nightMode ?? this.nightMode,
      effectsEnabled: effectsEnabled ?? this.effectsEnabled,
      micEnabled: micEnabled ?? this.micEnabled,
      micNoiseSuppression: micNoiseSuppression ?? this.micNoiseSuppression,
      echoCancellation: echoCancellation ?? this.echoCancellation,
      microphoneGain: microphoneGain ?? this.microphoneGain,
      surroundVariation: surroundVariation ?? this.surroundVariation,
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
    noiseLevel,
    limiterEnabled,
    compressorRatio,
    trackerEnabled,
    sharingEnabled,
    nightMode,
    effectsEnabled,
    micEnabled,
    micNoiseSuppression,
    echoCancellation,
    microphoneGain,
    surroundVariation,
  ];
}
