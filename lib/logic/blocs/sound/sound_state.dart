import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  factory SoundState.initial() => SoundState.defaultsFor('Gaming');

  factory SoundState.fromPrefs(SharedPreferences prefs) {
    try {
      final jsonStr = prefs.getString('sound_settings');
      if (jsonStr == null) return SoundState.initial();
      final map = json.decode(jsonStr);
      return SoundState(
        profile: map['profile'] ?? 'Gaming',
        eqGains:
            (map['eqGains'] as List<dynamic>?)
                ?.map((e) => (e as num).toDouble())
                .toList() ??
            List.generate(10, (_) => 0.0),
        virtualSurround: map['virtualSurround'] ?? true,
        bassBoost: map['bassBoost'] ?? true,
        voiceClarity: map['voiceClarity'] ?? true,
        trebleEnhancer: map['trebleEnhancer'] ?? true,
        smartVolume: map['smartVolume'] ?? true,
        stereoWidth: (map['stereoWidth'] as num?)?.toDouble() ?? 2.0,
        volumeBoost: (map['volumeBoost'] as num?)?.toDouble() ?? 1.0,
        sampleRate: map['sampleRate'] ?? 48000,
        bassGain: (map['bassGain'] as num?)?.toDouble() ?? 4.0,
        trebleGain: (map['trebleGain'] as num?)?.toDouble() ?? 4.0,
        voiceGain: (map['voiceGain'] as num?)?.toDouble() ?? 6.0,
        noiseLevel: (map['noiseLevel'] as num?)?.toDouble() ?? 0.0,
        limiterEnabled: map['limiterEnabled'] ?? true,
        compressorRatio: (map['compressorRatio'] as num?)?.toDouble() ?? 4.0,
        trackerEnabled: map['trackerEnabled'] ?? false,
        sharingEnabled: map['sharingEnabled'] ?? false,
        nightMode: map['nightMode'] ?? false,
        effectsEnabled: map['effectsEnabled'] ?? true,
        micEnabled: map['micEnabled'] ?? true,
        micNoiseSuppression: map['micNoiseSuppression'] ?? true,
        echoCancellation: map['echoCancellation'] ?? true,
        microphoneGain: (map['microphoneGain'] as num?)?.toDouble() ?? 1.0,
        surroundVariation: map['surroundVariation'] ?? 'Surround',
      );
    } catch (_) {
      return SoundState.initial();
    }
  }

  factory SoundState.defaultsFor(String profile) {
    switch (profile) {
      case 'Music':
        return SoundState(
          profile: 'Music',
          eqGains: const [
            2.0,
            1.5,
            0.5,
            0.0,
            0.0,
            -1.0,
            -1.5,
            -2.0,
            -2.5,
            -3.0,
          ],
          virtualSurround: true,
          bassBoost: true,
          voiceClarity: true,
          trebleEnhancer: false,
          smartVolume: false,
          stereoWidth: 1.5,
          bassGain: 8.0,
          trebleGain: 2.0,
          voiceGain: 4.0,
          limiterEnabled: false,
          compressorRatio: 3.0,
          micNoiseSuppression: false,
          echoCancellation: false,
          microphoneGain: 1.0,
        );
      case 'Movie':
        return SoundState(
          profile: 'Movie',
          eqGains: const [
            3.0,
            2.0,
            1.0,
            0.5,
            0.0,
            -0.5,
            -1.0,
            -1.5,
            -2.0,
            -2.5,
          ],
          virtualSurround: true,
          bassBoost: true,
          voiceClarity: true,
          trebleEnhancer: false,
          smartVolume: true,
          stereoWidth: 1.0,
          bassGain: 6.0,
          trebleGain: 3.0,
          voiceGain: 8.0,
          limiterEnabled: true,
          compressorRatio: 6.0,
          micNoiseSuppression: false,
          echoCancellation: false,
          microphoneGain: 1.0,
        );
      case 'Voice':
      case 'Communication':
        return SoundState(
          profile: profile,
          eqGains: const [-2.0, -1.0, 0.0, 1.0, 2.0, 3.0, 2.0, 1.0, 0.0, -1.0],
          virtualSurround: false,
          bassBoost: true,
          voiceClarity: true,
          trebleEnhancer: true,
          smartVolume: true,
          stereoWidth: 0.5,
          bassGain: 2.0,
          trebleGain: 6.0,
          voiceGain: 10.0,
          limiterEnabled: true,
          compressorRatio: 8.0,
          micNoiseSuppression: true,
          echoCancellation: true,
          microphoneGain: 1.2,
        );
      case 'Smart':
        return SoundState(
          profile: 'Smart',
          eqGains: const [1.0, 0.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
          virtualSurround: true,
          bassBoost: true,
          voiceClarity: true,
          trebleEnhancer: true,
          smartVolume: true,
          stereoWidth: 1.5,
          bassGain: 5.0,
          trebleGain: 3.0,
          voiceGain: 5.0,
          limiterEnabled: true,
          compressorRatio: 4.0,
          micNoiseSuppression: true,
          echoCancellation: false,
          microphoneGain: 1.0,
        );
      case 'Custom':
        return SoundState(
          profile: 'Custom',
          eqGains: List.generate(10, (_) => 0.0),
          virtualSurround: false,
          bassBoost: false,
          voiceClarity: false,
          trebleEnhancer: false,
          smartVolume: false,
          stereoWidth: 0.0,
          bassGain: 0.0,
          trebleGain: 0.0,
          voiceGain: 0.0,
          limiterEnabled: false,
          compressorRatio: 4.0,
          micNoiseSuppression: false,
          echoCancellation: false,
          microphoneGain: 1.0,
        );
      case 'Gaming':
      default:
        return SoundState(
          profile: 'Gaming',
          eqGains: List.generate(10, (_) => 0.0),
          virtualSurround: true,
          bassBoost: true,
          voiceClarity: true,
          trebleEnhancer: true,
          smartVolume: true,
          stereoWidth: 2.0,
          bassGain: 4.0,
          trebleGain: 4.0,
          voiceGain: 6.0,
          limiterEnabled: true,
          compressorRatio: 4.0,
          micNoiseSuppression: true,
          echoCancellation: false,
          microphoneGain: 1.0,
        );
    }
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
