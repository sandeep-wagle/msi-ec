class AudioDevice {
  final String id;
  final String name;
  final String type; // 'headphones', 'speakers', 'earphones', etc.
  final bool isActive;

  AudioDevice({
    required this.id,
    required this.name,
    required this.type,
    this.isActive = false,
  });

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'type': type, 'isActive': isActive};
  }

  factory AudioDevice.fromJson(Map<String, dynamic> json) {
    return AudioDevice(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      isActive: json['isActive'] ?? false,
    );
  }
}

class DeviceAudioProfile {
  final String deviceId;
  final String profileName;

  // Power toggles - user can disable effects per device
  final bool powerSurround;
  final bool powerNoiseReduction;
  final bool powerStereoEnhancement;
  final bool powerCompressor;
  final bool powerLimiter;
  final bool powerBassBoost;
  final bool powerTrebleEnhancer;
  final bool powerVoiceClarity;

  // Effect levels (only applied if power toggle is ON)
  final double surroundLevel;
  final double noiseLevel;
  final double stereoWidth;
  final double compressorRatio;
  final double bassGain;
  final double trebleGain;
  final double voiceGain;
  final List<double> eqGains;

  // Device-specific volume adjustment
  final double volumeOffset;

  DeviceAudioProfile({
    required this.deviceId,
    required this.profileName,
    this.powerSurround = true,
    this.powerNoiseReduction = true,
    this.powerStereoEnhancement = true,
    this.powerCompressor = false,
    this.powerLimiter = false,
    this.powerBassBoost = false,
    this.powerTrebleEnhancer = false,
    this.powerVoiceClarity = true,
    this.surroundLevel = 0.5,
    this.noiseLevel = 0.0,
    this.stereoWidth = 0.5,
    this.compressorRatio = 4.0,
    this.bassGain = 0.0,
    this.trebleGain = 0.0,
    this.voiceGain = 0.0,
    List<double>? eqGains,
    this.volumeOffset = 0.0,
  }) : eqGains = eqGains ?? List.generate(10, (_) => 0.0);

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'profileName': profileName,
      'powerSurround': powerSurround,
      'powerNoiseReduction': powerNoiseReduction,
      'powerStereoEnhancement': powerStereoEnhancement,
      'powerCompressor': powerCompressor,
      'powerLimiter': powerLimiter,
      'powerBassBoost': powerBassBoost,
      'powerTrebleEnhancer': powerTrebleEnhancer,
      'powerVoiceClarity': powerVoiceClarity,
      'surroundLevel': surroundLevel,
      'noiseLevel': noiseLevel,
      'stereoWidth': stereoWidth,
      'compressorRatio': compressorRatio,
      'bassGain': bassGain,
      'trebleGain': trebleGain,
      'voiceGain': voiceGain,
      'eqGains': eqGains,
      'volumeOffset': volumeOffset,
    };
  }

  factory DeviceAudioProfile.fromJson(Map<String, dynamic> json) {
    return DeviceAudioProfile(
      deviceId: json['deviceId'],
      profileName: json['profileName'],
      powerSurround: json['powerSurround'] ?? true,
      powerNoiseReduction: json['powerNoiseReduction'] ?? true,
      powerStereoEnhancement: json['powerStereoEnhancement'] ?? true,
      powerCompressor: json['powerCompressor'] ?? false,
      powerLimiter: json['powerLimiter'] ?? false,
      powerBassBoost: json['powerBassBoost'] ?? false,
      powerTrebleEnhancer: json['powerTrebleEnhancer'] ?? false,
      powerVoiceClarity: json['powerVoiceClarity'] ?? true,
      surroundLevel: (json['surroundLevel'] ?? 0.5).toDouble(),
      noiseLevel: (json['noiseLevel'] ?? 0.0).toDouble(),
      stereoWidth: (json['stereoWidth'] ?? 0.5).toDouble(),
      compressorRatio: (json['compressorRatio'] ?? 4.0).toDouble(),
      bassGain: (json['bassGain'] ?? 0.0).toDouble(),
      trebleGain: (json['trebleGain'] ?? 0.0).toDouble(),
      voiceGain: (json['voiceGain'] ?? 0.0).toDouble(),
      eqGains: List<double>.from(
        json['eqGains'] ?? List.generate(10, (_) => 0.0),
      ),
      volumeOffset: (json['volumeOffset'] ?? 0.0).toDouble(),
    );
  }

  DeviceAudioProfile copyWith({
    String? deviceId,
    String? profileName,
    bool? powerSurround,
    bool? powerNoiseReduction,
    bool? powerStereoEnhancement,
    bool? powerCompressor,
    bool? powerLimiter,
    bool? powerBassBoost,
    bool? powerTrebleEnhancer,
    bool? powerVoiceClarity,
    double? surroundLevel,
    double? noiseLevel,
    double? stereoWidth,
    double? compressorRatio,
    double? bassGain,
    double? trebleGain,
    double? voiceGain,
    List<double>? eqGains,
    double? volumeOffset,
  }) {
    return DeviceAudioProfile(
      deviceId: deviceId ?? this.deviceId,
      profileName: profileName ?? this.profileName,
      powerSurround: powerSurround ?? this.powerSurround,
      powerNoiseReduction: powerNoiseReduction ?? this.powerNoiseReduction,
      powerStereoEnhancement:
          powerStereoEnhancement ?? this.powerStereoEnhancement,
      powerCompressor: powerCompressor ?? this.powerCompressor,
      powerLimiter: powerLimiter ?? this.powerLimiter,
      powerBassBoost: powerBassBoost ?? this.powerBassBoost,
      powerTrebleEnhancer: powerTrebleEnhancer ?? this.powerTrebleEnhancer,
      powerVoiceClarity: powerVoiceClarity ?? this.powerVoiceClarity,
      surroundLevel: surroundLevel ?? this.surroundLevel,
      noiseLevel: noiseLevel ?? this.noiseLevel,
      stereoWidth: stereoWidth ?? this.stereoWidth,
      compressorRatio: compressorRatio ?? this.compressorRatio,
      bassGain: bassGain ?? this.bassGain,
      trebleGain: trebleGain ?? this.trebleGain,
      voiceGain: voiceGain ?? this.voiceGain,
      eqGains: eqGains ?? this.eqGains,
      volumeOffset: volumeOffset ?? this.volumeOffset,
    );
  }
}
