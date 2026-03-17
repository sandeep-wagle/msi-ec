import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/entities/audio_device.dart';
import '../../../domain/repositories/msi_repository.dart';
import 'audio_event.dart';
import 'audio_state.dart';

@injectable
class AudioBloc extends Bloc<AudioEvent, AudioState> {
  final MsiRepository _msiRepository;
  static const String _deviceProfilesKey = 'device_audio_profiles';

  StreamSubscription<String>? _sinkSubscription;
  Timer? _devicePollTimer;

  AudioBloc(this._msiRepository) : super(const AudioState()) {
    on<LoadAudioDevices>(_onLoadAudioDevices);
    on<AudioOutputChanged>(_onAudioOutputChanged);
    on<UpdateDeviceProfile>(_onUpdateDeviceProfile);
    on<ToggleDeviceEffectPower>(_onToggleDeviceEffectPower);
    on<UpdateDeviceEffectLevel>(_onUpdateDeviceEffectLevel);
    on<SaveDeviceProfile>(_onSaveDeviceProfile);
    on<LoadDeviceProfile>(_onLoadDeviceProfile);

    // Initialize
    add(LoadAudioDevices());
    _startDeviceMonitoring();
  }

  void _startDeviceMonitoring() {
    // Poll for device changes every 2 seconds
    _devicePollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkForDeviceChanges();
    });

    // Listen to pactl subscribe for real-time changes
    _startSinkSubscription();
  }

  Future<void> _startSinkSubscription() async {
    try {
      final process = await Process.start('pactl', ['subscribe']);
      _sinkSubscription = process.stdout
          .transform(const SystemEncoding().decoder)
          .listen((data) {
            if (data.contains('sink') || data.contains('change')) {
              _checkForDeviceChanges();
            }
          });
    } catch (e) {
      debugPrint('Failed to start sink subscription: $e');
    }
  }

  Future<void> _checkForDeviceChanges() async {
    try {
      final result = await Process.run('pactl', ['list', 'sinks']);
      final output = result.stdout.toString();

      final currentSink = await _getCurrentDefaultSink();
      final deviceType = _detectDeviceType(output, currentSink);

      // Check if device changed
      final currentDeviceId = state.activeDevice?.id ?? '';
      if (currentSink != currentDeviceId) {
        add(AudioOutputChanged(currentSink, deviceType));
      }
    } catch (e) {
      debugPrint('Error checking device changes: $e');
    }
  }

  Future<String> _getCurrentDefaultSink() async {
    try {
      final result = await Process.run('pactl', ['get-default-sink']);
      return result.stdout.toString().trim();
    } catch (e) {
      return '';
    }
  }

  String _detectDeviceType(String pactlOutput, String sinkName) {
    if (sinkName.contains('headphone') || sinkName.contains('Headphone')) {
      return 'headphones';
    }
    if (sinkName.contains('earphone') || sinkName.contains('Earphone')) {
      return 'earphones';
    }
    if (sinkName.contains('speaker') || sinkName.contains('Speaker')) {
      return 'speakers';
    }

    // Check description in pactl output
    final lines = pactlOutput.split('\n');
    for (final line in lines) {
      if (line.contains('Description:') && line.contains(sinkName)) {
        final description = line.split('Description:').last.trim();
        if (description.toLowerCase().contains('headphone')) {
          return 'headphones';
        }
        if (description.toLowerCase().contains('earphone')) {
          return 'earphones';
        }
        if (description.toLowerCase().contains('speaker')) {
          return 'speakers';
        }
      }
    }

    return 'unknown';
  }

  Future<void> _onLoadAudioDevices(LoadAudioDevices event, Emitter<AudioState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final devices = await _getAvailableDevices();
      final currentSink = await _getCurrentDefaultSink();
      final deviceType = await _getDeviceType(currentSink);

      final activeDevice = devices.firstWhere(
        (d) => d.id == currentSink,
        orElse: () => AudioDevice(
          id: currentSink,
          name: currentSink,
          type: deviceType,
          isActive: true,
        ),
      );

      emit(state.copyWith(
        availableDevices: devices,
        activeDevice: activeDevice,
        isLoading: false,
      ));

      // Load profile for active device
      if (activeDevice.id.isNotEmpty) {
        add(LoadDeviceProfile(activeDevice.id));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load audio devices: $e',
      ));
    }
  }

  Future<List<AudioDevice>> _getAvailableDevices() async {
    try {
      final result = await Process.run('pactl', ['list', 'sinks']);
      final output = result.stdout.toString();

      final devices = <AudioDevice>[];
      final lines = output.split('\n');
      String currentName = '';
      String currentDescription = '';

      for (final line in lines) {
        if (line.startsWith('Name: ')) {
          currentName = line.substring(6).trim();
        } else if (line.startsWith('\tDescription: ')) {
          currentDescription = line.substring(14).trim();
          final deviceType = _detectDeviceTypeFromDescription(currentDescription);
          devices.add(AudioDevice(
            id: currentName,
            name: currentDescription,
            type: deviceType,
          ));
        }
      }

      return devices;
    } catch (e) {
      debugPrint('Error getting available devices: $e');
      return [];
    }
  }

  String _detectDeviceTypeFromDescription(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('headphone')) return 'headphones';
    if (desc.contains('earphone')) return 'earphones';
    if (desc.contains('speaker')) return 'speakers';
    return 'unknown';
  }

  Future<String> _getDeviceType(String sinkName) async {
    try {
      final result = await Process.run('pactl', ['list', 'sinks']);
      final output = result.stdout.toString();
      return _detectDeviceType(output, sinkName);
    } catch (e) {
      return 'unknown';
    }
  }

  Future<void> _onAudioOutputChanged(AudioOutputChanged event, Emitter<AudioState> emit) async {
    final deviceType = event.deviceType;
    final device = AudioDevice(
      id: event.newSink,
      name: event.newSink,
      type: deviceType,
      isActive: true,
    );

    emit(state.copyWith(activeDevice: device));

    // Load or create profile for this device
    add(LoadDeviceProfile(event.newSink));
  }

  Future<void> _onLoadDeviceProfile(LoadDeviceProfile event, Emitter<AudioState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profilesJson = prefs.getString(_deviceProfilesKey);
      if (profilesJson != null) {
        final profiles = json.decode(profilesJson) as Map<String, dynamic>;
        final profileJson = profiles[event.deviceId];
        if (profileJson != null) {
          final profile = DeviceAudioProfile.fromJson(profileJson);
          emit(state.copyWith(activeProfile: profile));

          // Apply profile to DSP
          await _applyDeviceProfileToDSP(profile);
        } else {
          // Create default profile for device
          await _createDefaultProfileForDevice(event.deviceId, emit);
        }
      } else {
        // Create default profile for device
        await _createDefaultProfileForDevice(event.deviceId, emit);
      }
    } catch (e) {
      debugPrint('Error loading device profile: $e');
      await _createDefaultProfileForDevice(event.deviceId, emit);
    }
  }

  Future<void> _createDefaultProfileForDevice(String deviceId, Emitter<AudioState> emit) async {
    final deviceType = state.activeDevice?.type ?? 'unknown';
    final profile = _getDefaultProfileForDeviceType(deviceId, deviceType);

    emit(state.copyWith(activeProfile: profile));

    // Save the default profile
    await _saveDeviceProfile(profile);

    // Apply to DSP
    await _applyDeviceProfileToDSP(profile);
  }

  DeviceAudioProfile _getDefaultProfileForDeviceType(String deviceId, String deviceType) {
    switch (deviceType) {
      case 'headphones':
        return DeviceAudioProfile(
          deviceId: deviceId,
          profileName: 'Headphones',
          powerSurround: true,
          powerNoiseReduction: true,
          powerStereoEnhancement: true,
          powerVoiceClarity: true,
          surroundLevel: 0.7,
          noiseLevel: 0.3,
          stereoWidth: 0.8,
          bassGain: 2.0,
          trebleGain: 1.0,
          voiceGain: 3.0,
        );
      case 'earphones':
        return DeviceAudioProfile(
          deviceId: deviceId,
          profileName: 'Earphones',
          powerSurround: false, // Earphones don't benefit much from surround
          powerNoiseReduction: true,
          powerStereoEnhancement: true,
          powerVoiceClarity: true,
          surroundLevel: 0.0,
          noiseLevel: 0.5,
          stereoWidth: 0.6,
          bassGain: 1.0,
          trebleGain: 2.0,
          voiceGain: 4.0,
        );
      case 'speakers':
      default:
        return DeviceAudioProfile(
          deviceId: deviceId,
          profileName: 'Speakers',
          powerSurround: true,
          powerNoiseReduction: false,
          powerStereoEnhancement: false,
          powerVoiceClarity: false,
          surroundLevel: 0.8,
          noiseLevel: 0.0,
          stereoWidth: 0.0,
          bassGain: 3.0,
          trebleGain: 0.0,
          voiceGain: 0.0,
        );
    }
  }

  Future<void> _onUpdateDeviceProfile(UpdateDeviceProfile event, Emitter<AudioState> emit) async {
    if (state.activeProfile == null) return;

    final updatedProfile = state.activeProfile!.copyWith(profileName: event.profileName);
    emit(state.copyWith(activeProfile: updatedProfile));

    await _saveDeviceProfile(updatedProfile);
    await _applyDeviceProfileToDSP(updatedProfile);
  }

  Future<void> _onToggleDeviceEffectPower(ToggleDeviceEffectPower event, Emitter<AudioState> emit) async {
    if (state.activeProfile == null) return;

    DeviceAudioProfile updatedProfile;
    switch (event.effectType) {
      case 'surround':
        updatedProfile = state.activeProfile!.copyWith(powerSurround: event.enabled);
        break;
      case 'noise':
        updatedProfile = state.activeProfile!.copyWith(powerNoiseReduction: event.enabled);
        break;
      case 'stereo':
        updatedProfile = state.activeProfile!.copyWith(powerStereoEnhancement: event.enabled);
        break;
      case 'compressor':
        updatedProfile = state.activeProfile!.copyWith(powerCompressor: event.enabled);
        break;
      case 'limiter':
        updatedProfile = state.activeProfile!.copyWith(powerLimiter: event.enabled);
        break;
      case 'bass':
        updatedProfile = state.activeProfile!.copyWith(powerBassBoost: event.enabled);
        break;
      case 'treble':
        updatedProfile = state.activeProfile!.copyWith(powerTrebleEnhancer: event.enabled);
        break;
      case 'voice':
        updatedProfile = state.activeProfile!.copyWith(powerVoiceClarity: event.enabled);
        break;
      default:
        return;
    }

    emit(state.copyWith(activeProfile: updatedProfile));
    await _saveDeviceProfile(updatedProfile);
    await _applyDeviceProfileToDSP(updatedProfile);
  }

  Future<void> _onUpdateDeviceEffectLevel(UpdateDeviceEffectLevel event, Emitter<AudioState> emit) async {
    if (state.activeProfile == null) return;

    DeviceAudioProfile updatedProfile;
    switch (event.effectType) {
      case 'surround':
        updatedProfile = state.activeProfile!.copyWith(surroundLevel: event.level);
        break;
      case 'noise':
        updatedProfile = state.activeProfile!.copyWith(noiseLevel: event.level);
        break;
      case 'stereo':
        updatedProfile = state.activeProfile!.copyWith(stereoWidth: event.level);
        break;
      case 'compressor':
        updatedProfile = state.activeProfile!.copyWith(compressorRatio: event.level);
        break;
      case 'bass':
        updatedProfile = state.activeProfile!.copyWith(bassGain: event.level);
        break;
      case 'treble':
        updatedProfile = state.activeProfile!.copyWith(trebleGain: event.level);
        break;
      case 'voice':
        updatedProfile = state.activeProfile!.copyWith(voiceGain: event.level);
        break;
      default:
        return;
    }

    emit(state.copyWith(activeProfile: updatedProfile));
    await _saveDeviceProfile(updatedProfile);
    await _applyDeviceProfileToDSP(updatedProfile);
  }

  Future<void> _onSaveDeviceProfile(SaveDeviceProfile event, Emitter<AudioState> emit) async {
    if (state.activeProfile != null) {
      await _saveDeviceProfile(state.activeProfile!);
    }
  }

  Future<void> _saveDeviceProfile(DeviceAudioProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profilesJson = prefs.getString(_deviceProfilesKey) ?? '{}';
      final profiles = json.decode(profilesJson) as Map<String, dynamic>;

      profiles[profile.deviceId] = profile.toJson();

      await prefs.setString(_deviceProfilesKey, json.encode(profiles));
    } catch (e) {
      debugPrint('Error saving device profile: $e');
    }
  }

  Future<void> _applyDeviceProfileToDSP(DeviceAudioProfile profile) async {
    try {
      await _msiRepository.ensureDspSocketConnected();
      if (_msiRepository.dspSocket == null) return;

      // Send power toggles and levels to DSP
      final commands = <String>[];

      // Surround
      if (profile.powerSurround) {
        commands.add(jsonEncode({
          'surround': true,
          'surround_level': profile.surroundLevel.clamp(0.0, 1.0),
        }));
      } else {
        commands.add(jsonEncode({'surround': false, 'surround_level': 0.0}));
      }

      // Noise reduction
      if (profile.powerNoiseReduction) {
        commands.add(jsonEncode({
          'noise_level': profile.noiseLevel.clamp(0.0, 5.0),
        }));
      } else {
        commands.add(jsonEncode({'noise_level': 0.0}));
      }

      // Stereo enhancement
      if (profile.powerStereoEnhancement) {
        commands.add(jsonEncode({
          'stereo_width': profile.stereoWidth.clamp(0.0, 2.0),
        }));
      } else {
        commands.add(jsonEncode({'stereo_width': 0.0}));
      }

      // Compressor
      if (profile.powerCompressor) {
        commands.add(jsonEncode({
          'compressor': true,
          'compressor_ratio': profile.compressorRatio.clamp(1.0, 20.0),
        }));
      } else {
        commands.add(jsonEncode({'compressor': false}));
      }

      // Limiter
      if (profile.powerLimiter) {
        commands.add(jsonEncode({'limiter': true}));
      } else {
        commands.add(jsonEncode({'limiter': false}));
      }

      // Effects
      if (profile.powerBassBoost) {
        commands.add(jsonEncode({
          'bass_gain': profile.bassGain.clamp(-20.0, 20.0),
        }));
      } else {
        commands.add(jsonEncode({'bass_gain': 0.0}));
      }

      if (profile.powerTrebleEnhancer) {
        commands.add(jsonEncode({
          'treble_gain': profile.trebleGain.clamp(-20.0, 20.0),
        }));
      } else {
        commands.add(jsonEncode({'treble_gain': 0.0}));
      }

      if (profile.powerVoiceClarity) {
        commands.add(jsonEncode({
          'voice_gain': profile.voiceGain.clamp(-20.0, 20.0),
        }));
      } else {
        commands.add(jsonEncode({'voice_gain': 0.0}));
      }

      // Send all commands
      for (final command in commands) {
        _msiRepository.dspSocket!.write(command);
        await _msiRepository.dspSocket!.flush();
        await Future.delayed(const Duration(milliseconds: 10)); // Small delay between commands
      }

      debugPrint('Applied device profile to DSP: ${profile.profileName}');
    } catch (e) {
      debugPrint('Error applying device profile to DSP: $e');
    }
  }

  @override
  Future<void> close() {
    _sinkSubscription?.cancel();
    _devicePollTimer?.cancel();
    return super.close();
  }
}