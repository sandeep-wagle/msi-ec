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
    );
  }
}
