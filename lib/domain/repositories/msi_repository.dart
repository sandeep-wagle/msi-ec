import 'dart:async';
import 'dart:io';
import 'package:msi_controller/domain/entities/system_info.dart';
import 'package:msi_controller/domain/entities/audio_profile.dart';

abstract class MsiRepository {
  Stream<SystemInfo> get systemInfoStream;
  Stream<List<FanInfo>> get fanInfoStream;

  bool get isInitialized;
  bool get hasMsiEcSupport;

  Future<bool> initialize();

  Future<bool> setPerformanceMode(PerformanceMode mode);
  Future<bool> setSuperBattery(bool enable);
  Future<bool> setBatteryLimit(int limit);
  Future<bool> setFanSpeed(int fanIndex, int rpm);
  Future<bool> setPerformanceLevel(String level);
  Future<bool> setFanAutoMode(int fanIndex, bool autoMode);
  Future<bool> setFanMode(FanMode mode);

  Future<bool> setKeyboardBacklight(KeyboardBacklightInfo info);

  Future<DeviceSettings> getDeviceSettings();
  Future<bool> setCoolerBoost(bool enable);
  Future<bool> setDeviceSetting(String key, dynamic value);
  Future<bool> freeUpMemory();
  Future<bool> cleanUpDisk();

  // Gaming Mode
  Future<bool> setGamingMode(
    bool enable, {
    bool perf = true,
    bool audio = true,
    bool cooler = true,
  });

  // Feature set management
  Future<bool> setFeatureEnabled(String featureId, bool enabled);
  Future<bool> openFeature(String featureId);

  // AI LAN Manager
  Future<bool> setAiLanPriority(bool enable);

  // Sound Tune Advanced
  Future<bool> setSoundProfile(String profile);
  void setActiveProfileName(String profile);
  Future<bool> setSoundEQ(List<double> gains);
  Future<bool> setSoundEnhancement(String enhancement, bool enable);
  Future<void> setSoundSampleRate(int hertz);
  Future<void> setSoundStereoWidth(double width);
  Future<void> setSoundVolumeBoost(double boost);
  Future<bool> setSoundEffectGain(String effect, double gain);
  Future<void> setSoundNoiseLevel(double level);
  Future<void> setSoundLimiterEnabled(bool enabled);
  Future<void> setSoundCompressorRatio(double ratio);
  Future<void> setSoundSurroundVariation(String variation);
  Future<void> setSoundNightMode(bool enabled);
  Future<void> setSoundEffectsEnabled(bool enabled);
  Future<void> setSoundMicEnabled(bool enabled);
  Future<void> setSoundMicGain(double gain);
  Future<void> setSoundMicNoiseSuppression(bool enabled);
  Future<void> setSoundEchoCancellation(bool enabled);
  Future<void> applyCurrentProfile();
  Stream<double> get volumeStream;
  double get currentVolume;

  // GPU Switching
  Future<bool> setGpuMode(GpuMode mode);

  // DSP Control
  Future<bool> setDspProfile(AudioProfile profile);
  Future<bool> setDspBass(double gain);
  Future<bool> setDspTreble(double gain);
  Future<bool> setDspCompressor(bool enable);
  Future<bool> enableDsp();
  Future<bool> disableDsp();
  Future<bool> getDspStatus();

  // DSP Socket Access for AudioBloc
  Future<void> ensureDspSocketConnected();
  Socket? get dspSocket;

  void dispose();
}
