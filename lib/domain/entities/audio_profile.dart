class AudioProfile {
  final String name;
  final double bass;
  final double treble;
  final double voice;
  final List<double> eqGains;
  final bool compressor;
  final bool surround;
  final double volume;
  final int bufferSize;
  // Nahimic-style enhancements
  final double noiseLevel;
  final double stereoWidth;
  final bool limiterEnabled;
  final double compressorRatio;
  // Additional fields
  final String surroundVariation;
  final bool nightMode;
  final bool effectsEnabled;
  final bool micEnabled;
  final double micGain;
  final bool micNoiseSuppression;
  final bool echoCancellation;
  final bool voiceClarity;
  final bool trebleEnhancer;
  final bool bassBoost;
  final bool trackerEnabled;
  final bool sharingEnabled;

  AudioProfile({
    required this.name,
    required this.bass,
    required this.treble,
    required this.voice,
    required this.eqGains,
    this.compressor = false,
    this.surround = false,
    this.volume = 1.0,
    this.bufferSize = 256,
    this.noiseLevel = 0.0,
    this.stereoWidth = 0.0,
    this.limiterEnabled = false,
    this.compressorRatio = 4.0,
    this.surroundVariation = 'Surround',
    this.nightMode = false,
    this.effectsEnabled = true,
    this.micEnabled = true,
    this.micGain = 0.5,
    this.micNoiseSuppression = true,
    this.echoCancellation = true,
    this.voiceClarity = false,
    this.trebleEnhancer = false,
    this.bassBoost = false,
    this.trackerEnabled = false,
    this.sharingEnabled = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'bass': bass,
      'treble': treble,
      'voice': voice,
      'eq_gains': eqGains,
      'compressor': compressor,
      'surround': surround,
      'volume': volume,
      'buffer_size': bufferSize,
      'noise_level': noiseLevel,
      'stereo_width': stereoWidth,
      'limiter_enabled': limiterEnabled,
      'compressor_ratio': compressorRatio,
      'surround_variation': surroundVariation,
      'night_mode': nightMode,
      'effects_enabled': effectsEnabled,
      'mic_enabled': micEnabled,
      'mic_gain': micGain,
      'mic_noise_suppression': micNoiseSuppression,
      'echo_cancellation': echoCancellation,
      'voice_clarity': voiceClarity,
      'treble_enhancer': trebleEnhancer,
      'bass_boost': bassBoost,
      'tracker_enabled': trackerEnabled,
      'sharing_enabled': sharingEnabled,
    };
  }

  factory AudioProfile.fromJson(Map<String, dynamic> json) {
    return AudioProfile(
      name: json['name'] ?? 'Custom',
      bass: (json['bass'] ?? 0.0).toDouble(),
      treble: (json['treble'] ?? 0.0).toDouble(),
      voice: (json['voice'] ?? 0.0).toDouble(),
      eqGains: List<double>.from((json['eq_gains'] ?? List.filled(10, 0.0)).map((e) => e.toDouble())),
      compressor: json['compressor'] ?? false,
      surround: json['surround'] ?? false,
      volume: (json['volume'] ?? 1.0).toDouble(),
      bufferSize: json['buffer_size'] ?? 256,
      noiseLevel: (json['noise_level'] ?? 0.0).toDouble(),
      stereoWidth: (json['stereo_width'] ?? 0.0).toDouble(),
      limiterEnabled: json['limiter_enabled'] ?? false,
      compressorRatio: (json['compressor_ratio'] ?? 4.0).toDouble(),
      surroundVariation: json['surround_variation'] ?? 'Surround',
      nightMode: json['night_mode'] ?? false,
      effectsEnabled: json['effects_enabled'] ?? true,
      micEnabled: json['mic_enabled'] ?? true,
      micGain: (json['mic_gain'] ?? 0.5).toDouble(),
      micNoiseSuppression: json['mic_noise_suppression'] ?? true,
      echoCancellation: json['echo_cancellation'] ?? true,
      voiceClarity: json['voice_clarity'] ?? false,
      trebleEnhancer: json['treble_enhancer'] ?? false,
      bassBoost: json['bass_boost'] ?? false,
      trackerEnabled: json['tracker_enabled'] ?? false,
      sharingEnabled: json['sharing_enabled'] ?? false,
    );
  }
}
