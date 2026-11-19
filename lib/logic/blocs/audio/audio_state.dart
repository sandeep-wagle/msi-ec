import 'package:equatable/equatable.dart';
import 'package:msi_controller/domain/entities/audio_device.dart';

class AudioState extends Equatable {
  final List<AudioDevice> availableDevices;
  final AudioDevice? activeDevice;
  final DeviceAudioProfile? activeProfile;
  final bool isLoading;
  final String? error;

  const AudioState({
    this.availableDevices = const [],
    this.activeDevice,
    this.activeProfile,
    this.isLoading = false,
    this.error,
  });

  AudioState copyWith({
    List<AudioDevice>? availableDevices,
    AudioDevice? activeDevice,
    DeviceAudioProfile? activeProfile,
    bool? isLoading,
    String? error,
  }) {
    return AudioState(
      availableDevices: availableDevices ?? this.availableDevices,
      activeDevice: activeDevice ?? this.activeDevice,
      activeProfile: activeProfile ?? this.activeProfile,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  // Helper getters for UI
  bool get hasActiveDevice => activeDevice != null;
  bool get isHeadphones =>
      activeDevice?.type == 'headphones' || activeDevice?.type == 'earphones';
  bool get isSpeakers => activeDevice?.type == 'speakers';

  // Power toggle getters with safe defaults
  bool get powerSurround => activeProfile?.powerSurround ?? true;
  bool get powerNoiseReduction => activeProfile?.powerNoiseReduction ?? true;
  bool get powerStereoEnhancement =>
      activeProfile?.powerStereoEnhancement ?? true;
  bool get powerCompressor => activeProfile?.powerCompressor ?? false;
  bool get powerLimiter => activeProfile?.powerLimiter ?? false;
  bool get powerBassBoost => activeProfile?.powerBassBoost ?? false;
  bool get powerTrebleEnhancer => activeProfile?.powerTrebleEnhancer ?? false;
  bool get powerVoiceClarity => activeProfile?.powerVoiceClarity ?? true;

  // Effect level getters with safe defaults and clamping
  double get surroundLevel =>
      _clamp(activeProfile?.surroundLevel ?? 0.5, 0.0, 1.0);
  double get noiseLevel => _clamp(activeProfile?.noiseLevel ?? 0.0, 0.0, 5.0);
  double get stereoWidth => _clamp(activeProfile?.stereoWidth ?? 0.5, 0.0, 2.0);
  double get compressorRatio =>
      _clamp(activeProfile?.compressorRatio ?? 4.0, 1.0, 20.0);
  double get bassGain => _clamp(activeProfile?.bassGain ?? 0.0, -20.0, 20.0);
  double get trebleGain =>
      _clamp(activeProfile?.trebleGain ?? 0.0, -20.0, 20.0);
  double get voiceGain => _clamp(activeProfile?.voiceGain ?? 0.0, -20.0, 20.0);
  List<double> get eqGains =>
      activeProfile?.eqGains ?? List.generate(10, (_) => 0.0);
  double get volumeOffset =>
      _clamp(activeProfile?.volumeOffset ?? 0.0, -1.0, 1.0);

  double _clamp(double value, double min, double max) {
    if (value.isNaN) return min;
    return value.clamp(min, max);
  }

  @override
  List<Object?> get props => [
    availableDevices,
    activeDevice,
    activeProfile,
    isLoading,
    error,
  ];
}
