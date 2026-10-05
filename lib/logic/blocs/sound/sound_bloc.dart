import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:msi_controller/domain/repositories/msi_repository.dart';
import 'sound_event.dart';
import 'sound_state.dart';

class SoundBloc extends Bloc<SoundEvent, SoundState> {
  final MsiRepository _repository;
  static const String _prefKey = 'sound_settings';

  /// Volume echo-suppression: the last value WE sent plus when the user
  /// last touched volume. Polled levels matching our echo, arriving
  /// mid-drag, or while self-muted are ignored so the slider never
  /// jumps under the finger.
  double _lastSentVolume = -1.0;
  DateTime _lastUserVolumeChange = DateTime.fromMillisecondsSinceEpoch(0);
  bool _mutedByUs = false;

  SoundBloc(this._repository, SoundState initialState) : super(initialState) {
    on<SetSoundProfile>(_onSetSoundProfile, transformer: restartable());
    on<UpdateEQGains>(_onUpdateEQGains, transformer: restartable());
    on<ToggleEnhancement>(_onToggleEnhancement, transformer: restartable());
    on<ChangeSampleRate>(_onChangeSampleRate, transformer: restartable());
    on<ChangeStereoWidth>(_onChangeStereoWidth, transformer: restartable());
    on<ChangeVolumeBoost>(_onChangeVolumeBoost, transformer: restartable());
    on<ChangeVolumeBoostPreview>(
      _onChangeVolumeBoostPreview,
      transformer: restartable(),
    );
    on<ChangeStereoWidthPreview>(
      _onChangeStereoWidthPreview,
      transformer: restartable(),
    );
    on<ChangeCompressorRatioPreview>(
      _onChangeCompressorRatioPreview,
      transformer: restartable(),
    );
    on<ChangeNoiseLevelPreview>(
      _onChangeNoiseLevelPreview,
      transformer: restartable(),
    );
    on<ChangeMicrophoneGainPreview>(
      _onChangeMicrophoneGainPreview,
      transformer: restartable(),
    );
    on<ChangeEffectGain>(_onChangeEffectGain, transformer: restartable());
    on<ChangeEffectGainPreview>(
      _onChangeEffectGainPreview,
      transformer: restartable(),
    );
    on<UpdateEQGainsPreview>(
      _onUpdateEQGainsPreview,
      transformer: restartable(),
    );
    on<ChangeNoiseLevel>(_onChangeNoiseLevel, transformer: restartable());
    on<ToggleLimiter>(_onToggleLimiter, transformer: restartable());
    on<ChangeCompressorRatio>(
      _onChangeCompressorRatio,
      transformer: restartable(),
    );
    on<ChangeSurroundVariation>(
      _onChangeSurroundVariation,
      transformer: restartable(),
    );
    on<ChangeMicrophoneGain>(
      _onChangeMicrophoneGain,
      transformer: restartable(),
    );
    on<ResetSoundSettings>(_onResetSoundSettings);
    on<SyncVolume>(_onSyncVolume);

    _repository.volumeStream.listen((vol) {
      add(SyncVolume(vol));
    });
  }

  Future<void> _onSyncVolume(SyncVolume event, Emitter<SoundState> emit) async {
    // Polled levels (system keys, other apps) follow into the slider —
    // EXCEPT our own echoes and in-flight storms while the user drags:
    // stale poll replies landing mid-drag are what made the readout jump
    // 30 -> 04 -> 20. Muted state is sticky until the user drags.
    if (_mutedByUs) return;
    final now = DateTime.now();
    if (now.difference(_lastUserVolumeChange).inMilliseconds < 500) return;
    if ((event.volume - _lastSentVolume).abs() < 0.005) return;
    emit(state.copyWith(volumeBoost: event.volume.clamp(0.0, 1.0)));
  }

  void applyInitialSettings() {
    _syncToHardware(state);
  }

  void _syncToHardware(SoundState newState) {
    _repository.setActiveProfileName(newState.profile);
    final timeout = Duration(seconds: 1);
    unawaited(_repository.setSoundProfile(newState.profile));
    unawaited(_repository.setSoundEQ(newState.eqGains).timeout(timeout));
    unawaited(
      _repository.setSoundSampleRate(newState.sampleRate).timeout(timeout),
    );
    unawaited(
      _repository
          .setSoundEnhancement('virtualSurround', newState.virtualSurround)
          .timeout(timeout),
    );
    unawaited(
      _repository
          .setSoundEnhancement('bassBoost', newState.bassBoost)
          .timeout(timeout),
    );
    unawaited(
      _repository
          .setSoundEnhancement('voiceClarity', newState.voiceClarity)
          .timeout(timeout),
    );
    unawaited(
      _repository
          .setSoundEnhancement('trebleEnhancer', newState.trebleEnhancer)
          .timeout(timeout),
    );
    unawaited(
      _repository
          .setSoundEnhancement('smartVolume', newState.smartVolume)
          .timeout(timeout),
    );
    unawaited(
      _repository.setSoundStereoWidth(newState.stereoWidth).timeout(timeout),
    );
    // NOTE: volume is deliberately NOT synced here. The live sink level
    // (owned by the service, persisted across reboots) is the truth; the
    // repository adopts it on connect and the slider follows. Blasting the
    // saved value on every app start is exactly what made volume jump —
    // and made it feel like audio "needs" the app to start.
    unawaited(
      _repository
          .setSoundEffectGain('bass', newState.bassGain)
          .timeout(timeout),
    );
    unawaited(
      _repository
          .setSoundEffectGain('treble', newState.trebleGain)
          .timeout(timeout),
    );
    unawaited(
      _repository
          .setSoundEffectGain('voice', newState.voiceGain)
          .timeout(timeout),
    );
    unawaited(
      _repository.setSoundNoiseLevel(newState.noiseLevel).timeout(timeout),
    );
    unawaited(
      _repository
          .setSoundLimiterEnabled(newState.limiterEnabled)
          .timeout(timeout),
    );
    unawaited(
      _repository
          .setSoundCompressorRatio(newState.compressorRatio)
          .timeout(timeout),
    );
    unawaited(
      _repository
          .setSoundSurroundVariation(newState.surroundVariation)
          .timeout(timeout),
    );
    unawaited(
      _repository.setSoundNightMode(newState.nightMode).timeout(timeout),
    );
    unawaited(
      _repository
          .setSoundEffectsEnabled(newState.effectsEnabled)
          .timeout(timeout),
    );
    unawaited(
      _repository.setSoundMicEnabled(newState.micEnabled).timeout(timeout),
    );
    unawaited(
      _repository.setSoundMicGain(newState.microphoneGain).timeout(timeout),
    );
    unawaited(
      _repository
          .setSoundMicNoiseSuppression(newState.micNoiseSuppression)
          .timeout(timeout),
    );
    unawaited(
      _repository
          .setSoundEchoCancellation(newState.echoCancellation)
          .timeout(timeout),
    );
  }

  Future<void> _onSetSoundProfile(
    SetSoundProfile event,
    Emitter<SoundState> emit,
  ) async {
    debugPrint('SoundBloc: Setting sound profile to ${event.profile}');

    // Update profile name in the repository first.
    _repository.setActiveProfileName(event.profile);

    // Build base state from new unified defaults.
    final defaults = SoundState.defaultsFor(event.profile);
    SoundState newState = state.copyWith(
      profile: event.profile,
      eqGains: defaults.eqGains,
      bassGain: defaults.bassGain,
      trebleGain: defaults.trebleGain,
      voiceGain: defaults.voiceGain,
      virtualSurround: defaults.virtualSurround,
      smartVolume: defaults.smartVolume,
      stereoWidth: defaults.stereoWidth,
      limiterEnabled: defaults.limiterEnabled,
      compressorRatio: defaults.compressorRatio,
      micNoiseSuppression: defaults.micNoiseSuppression,
      echoCancellation: defaults.echoCancellation,
      microphoneGain: defaults.microphoneGain,
      surroundVariation: defaults.surroundVariation,
      nightMode: defaults.nightMode,
      effectsEnabled: defaults.effectsEnabled,
    );

    // Override with any previously-saved per-profile customisations.
    final profilePrefs = await SharedPreferences.getInstance();
    final profileBassContent = profilePrefs.getString(
      '${event.profile}_bassGain',
    );
    final profileTrebleContent = profilePrefs.getString(
      '${event.profile}_trebleGain',
    );
    final profileVoiceContent = profilePrefs.getString(
      '${event.profile}_voiceGain',
    );
    final profileEqGainsContent = profilePrefs.getString(
      '${event.profile}_eqGains',
    );

    if (profileBassContent != null) {
      newState = newState.copyWith(
        bassGain: double.tryParse(profileBassContent) ?? newState.bassGain,
      );
    }
    if (profileTrebleContent != null) {
      newState = newState.copyWith(
        trebleGain:
            double.tryParse(profileTrebleContent) ?? newState.trebleGain,
      );
    }
    if (profileVoiceContent != null) {
      newState = newState.copyWith(
        voiceGain: double.tryParse(profileVoiceContent) ?? newState.voiceGain,
      );
    }
    if (profileEqGainsContent != null) {
      try {
        newState = newState.copyWith(
          eqGains: List<double>.from(json.decode(profileEqGainsContent)),
        );
      } catch (_) {}
    }

    emit(newState);
    debugPrint('SoundBloc: Emitted new state for profile ${event.profile}');

    // Committing full state for the new profile to DSP
    await _repository.setSoundEQ(newState.eqGains);
    await _repository.setSoundEffectGain('bass', newState.bassGain);
    await _repository.setSoundEffectGain('treble', newState.trebleGain);
    await _repository.setSoundEffectGain('voice', newState.voiceGain);
    await _repository.setSoundEnhancement(
      'virtualSurround',
      newState.virtualSurround,
    );
    await _repository.setSoundEnhancement('smartVolume', newState.smartVolume);
    await _repository.setSoundStereoWidth(newState.stereoWidth);
    await _repository.setSoundLimiterEnabled(newState.limiterEnabled);
    await _repository.setSoundCompressorRatio(newState.compressorRatio);
    await _repository.setSoundMicNoiseSuppression(newState.micNoiseSuppression);
    await _repository.setSoundEchoCancellation(newState.echoCancellation);
    await _repository.setSoundMicGain(newState.microphoneGain);
    await _repository.setSoundSurroundVariation(newState.surroundVariation);
    await _repository.setSoundNightMode(newState.nightMode);
    await _repository.setSoundEffectsEnabled(newState.effectsEnabled);

    await _repository.setSoundProfile(event.profile);
    await _saveSettings();
  }

  Future<void> _onUpdateEQGains(
    UpdateEQGains event,
    Emitter<SoundState> emit,
  ) async {
    final roundedGains = event.gains.map((g) => g.roundToDouble()).toList();
    emit(state.copyWith(eqGains: roundedGains));
    await _repository.setSoundEQ(roundedGains);
    await _saveSettings();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${state.profile}_eqGains',
      json.encode(state.eqGains),
    );
  }

  Future<void> _onUpdateEQGainsPreview(
    UpdateEQGainsPreview event,
    Emitter<SoundState> emit,
  ) async {
    final roundedGains = event.gains.map((g) => g.roundToDouble()).toList();
    emit(state.copyWith(eqGains: roundedGains));
  }

  Future<void> _onToggleEnhancement(
    ToggleEnhancement event,
    Emitter<SoundState> emit,
  ) async {
    SoundState newState;
    switch (event.enhancement) {
      case 'virtualSurround':
        newState = state.copyWith(virtualSurround: event.value);
        break;
      case 'bassBoost':
        newState = state.copyWith(bassBoost: event.value);
        break;
      case 'voiceClarity':
        newState = state.copyWith(voiceClarity: event.value);
        break;
      case 'trebleEnhancer':
        newState = state.copyWith(trebleEnhancer: event.value);
        break;
      case 'smartVolume':
        newState = state.copyWith(smartVolume: event.value);
        break;
      case 'trackerEnabled':
        newState = state.copyWith(trackerEnabled: event.value);
        break;
      case 'sharingEnabled':
        newState = state.copyWith(sharingEnabled: event.value);
        break;
      case 'limiterEnabled':
        newState = state.copyWith(limiterEnabled: event.value);
        await _repository.setSoundLimiterEnabled(event.value);
        break;
      case 'nightMode':
        newState = state.copyWith(nightMode: event.value);
        await _repository.setSoundNightMode(event.value);
        break;
      case 'effectsEnabled':
        newState = state.copyWith(effectsEnabled: event.value);
        await _repository.setSoundEffectsEnabled(event.value);
        break;
      case 'micEnabled':
        newState = state.copyWith(micEnabled: event.value);
        await _repository.setSoundMicEnabled(event.value);
        break;
      case 'micNoiseSuppression':
        newState = state.copyWith(micNoiseSuppression: event.value);
        await _repository.setSoundMicNoiseSuppression(event.value);
        break;
      case 'echoCancellation':
        newState = state.copyWith(echoCancellation: event.value);
        await _repository.setSoundEchoCancellation(event.value);
        break;
      default:
        return;
    }
    emit(newState);
    if (event.enhancement != 'limiterEnabled' &&
        event.enhancement != 'nightMode' &&
        event.enhancement != 'effectsEnabled' &&
        event.enhancement != 'micEnabled' &&
        event.enhancement != 'micNoiseSuppression' &&
        event.enhancement != 'echoCancellation') {
      await _repository.setSoundEnhancement(event.enhancement, event.value);
    }
    await _saveSettings();
  }

  Future<void> _onChangeSampleRate(
    ChangeSampleRate event,
    Emitter<SoundState> emit,
  ) async {
    emit(state.copyWith(sampleRate: event.hertz));
    await _repository.setSoundSampleRate(event.hertz);
    await _saveSettings();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      'profile': state.profile,
      'eqGains': state.eqGains,
      'virtualSurround': state.virtualSurround,
      'bassBoost': state.bassBoost,
      'voiceClarity': state.voiceClarity,
      'trebleEnhancer': state.trebleEnhancer,
      'smartVolume': state.smartVolume,
      'stereoWidth': state.stereoWidth,
      'volumeBoost': state.volumeBoost.clamp(0.0, 1.0),
      'sampleRate': state.sampleRate,
      'bassGain': state.bassGain,
      'trebleGain': state.trebleGain,
      'voiceGain': state.voiceGain,
      'noiseLevel': state.noiseLevel,
      'limiterEnabled': state.limiterEnabled,
      'compressorRatio': state.compressorRatio,
      'trackerEnabled': state.trackerEnabled,
      'sharingEnabled': state.sharingEnabled,
      'microphoneGain': state.microphoneGain,
      'surroundVariation': state.surroundVariation,
      'nightMode': state.nightMode,
      'effectsEnabled': state.effectsEnabled,
      'micEnabled': state.micEnabled,
      'micNoiseSuppression': state.micNoiseSuppression,
      'echoCancellation': state.echoCancellation,
    };
    await prefs.setString(_prefKey, json.encode(map));
  }

  Future<void> _onChangeEffectGain(
    ChangeEffectGain event,
    Emitter<SoundState> emit,
  ) async {
    final roundedGain = event.gain.roundToDouble();
    debugPrint(
      'SoundBloc: COMMITTING effect gain change - ${event.effect}: $roundedGain',
    );

    switch (event.effect) {
      case 'bass':
        emit(state.copyWith(bassGain: roundedGain));
        break;
      case 'treble':
        emit(state.copyWith(trebleGain: roundedGain));
        break;
      case 'voice':
        emit(state.copyWith(voiceGain: roundedGain));
        break;
    }

    try {
      await _repository.setSoundEffectGain(event.effect, roundedGain);
      await _saveSettings();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '${state.profile}_bassGain',
        state.bassGain.toString(),
      );
      await prefs.setString(
        '${state.profile}_trebleGain',
        state.trebleGain.toString(),
      );
      await prefs.setString(
        '${state.profile}_voiceGain',
        state.voiceGain.toString(),
      );
    } catch (e) {
      debugPrint('SoundBloc: Error applying DSP update: $e');
    }
  }

  Future<void> _onChangeEffectGainPreview(
    ChangeEffectGainPreview event,
    Emitter<SoundState> emit,
  ) async {
    final roundedGain = event.gain.roundToDouble();
    switch (event.effect) {
      case 'bass':
        emit(state.copyWith(bassGain: roundedGain));
        break;
      case 'treble':
        emit(state.copyWith(trebleGain: roundedGain));
        break;
      case 'voice':
        emit(state.copyWith(voiceGain: roundedGain));
        break;
    }
  }

  Future<void> _onChangeStereoWidth(
    ChangeStereoWidth event,
    Emitter<SoundState> emit,
  ) async {
    emit(state.copyWith(stereoWidth: event.width));
    await _repository.setSoundStereoWidth(event.width);
    await _saveSettings();
  }

  Future<void> _onChangeStereoWidthPreview(
    ChangeStereoWidthPreview event,
    Emitter<SoundState> emit,
  ) async {
    emit(state.copyWith(stereoWidth: event.width));
  }

  Future<void> _onChangeVolumeBoost(
    ChangeVolumeBoost event,
    Emitter<SoundState> emit,
  ) async {
    // Display range is 0-100%; the service tempers it onto real 0.4-1.4.
    // Negative sentinel = mute button (true mute, not volume zero).
    _lastUserVolumeChange = DateTime.now();
    if (event.boost < 0) {
      _mutedByUs = true;
      emit(state.copyWith(volumeBoost: 0.0));
      await _repository.setSoundVolumeBoost(-1.0);
      await _saveSettings();
      return;
    }
    final clampedBoost = event.boost.clamp(0.0, 1.0);
    _mutedByUs = false;
    _lastSentVolume = clampedBoost;
    emit(state.copyWith(volumeBoost: clampedBoost));
    await _repository.setSoundVolumeBoost(clampedBoost);
    await _saveSettings();
  }

  Future<void> _onChangeVolumeBoostPreview(
    ChangeVolumeBoostPreview event,
    Emitter<SoundState> emit,
  ) async {
    _lastUserVolumeChange = DateTime.now();
    emit(state.copyWith(volumeBoost: event.boost.clamp(0.0, 1.0)));
  }

  Future<void> _onChangeNoiseLevel(
    ChangeNoiseLevel event,
    Emitter<SoundState> emit,
  ) async {
    emit(state.copyWith(noiseLevel: event.level));
    await _repository.setSoundNoiseLevel(event.level);
    await _saveSettings();
  }

  Future<void> _onChangeNoiseLevelPreview(
    ChangeNoiseLevelPreview event,
    Emitter<SoundState> emit,
  ) async {
    emit(state.copyWith(noiseLevel: event.level));
  }

  Future<void> _onToggleLimiter(
    ToggleLimiter event,
    Emitter<SoundState> emit,
  ) async {
    emit(state.copyWith(limiterEnabled: event.enabled));
    await _repository.setSoundLimiterEnabled(event.enabled);
    await _saveSettings();
  }

  Future<void> _onChangeCompressorRatio(
    ChangeCompressorRatio event,
    Emitter<SoundState> emit,
  ) async {
    emit(state.copyWith(compressorRatio: event.ratio));
    await _repository.setSoundCompressorRatio(event.ratio);
    await _saveSettings();
  }

  Future<void> _onChangeCompressorRatioPreview(
    ChangeCompressorRatioPreview event,
    Emitter<SoundState> emit,
  ) async {
    emit(state.copyWith(compressorRatio: event.ratio));
  }

  Future<void> _onChangeSurroundVariation(
    ChangeSurroundVariation event,
    Emitter<SoundState> emit,
  ) async {
    emit(state.copyWith(surroundVariation: event.variation));
    await _repository.setSoundSurroundVariation(event.variation);
    await _saveSettings();
  }

  Future<void> _onChangeMicrophoneGain(
    ChangeMicrophoneGain event,
    Emitter<SoundState> emit,
  ) async {
    emit(state.copyWith(microphoneGain: event.gain));
    await _repository.setSoundMicGain(event.gain);
    await _saveSettings();
  }

  Future<void> _onChangeMicrophoneGainPreview(
    ChangeMicrophoneGainPreview event,
    Emitter<SoundState> emit,
  ) async {
    emit(state.copyWith(microphoneGain: event.gain));
  }

  Future<void> _onResetSoundSettings(
    ResetSoundSettings event,
    Emitter<SoundState> emit,
  ) async {
    final newState = SoundState.defaultsFor(state.profile);
    emit(newState);
    await _repository.setSoundProfile(newState.profile);
    await _repository.setSoundEQ(newState.eqGains);
    await _repository.setSoundEnhancement(
      'virtualSurround',
      newState.virtualSurround,
    );
    await _repository.setSoundEnhancement('bassBoost', newState.bassBoost);
    await _repository.setSoundEnhancement(
      'voiceClarity',
      newState.voiceClarity,
    );
    await _repository.setSoundEnhancement(
      'trebleEnhancer',
      newState.trebleEnhancer,
    );
    await _repository.setSoundEnhancement('smartVolume', newState.smartVolume);
    await _repository.setSoundStereoWidth(newState.stereoWidth);
    await _repository.setSoundVolumeBoost(newState.volumeBoost);
    await _repository.setSoundEffectGain('bass', newState.bassGain);
    await _repository.setSoundEffectGain('treble', newState.trebleGain);
    await _repository.setSoundEffectGain('voice', newState.voiceGain);
    await _repository.setSoundNoiseLevel(newState.noiseLevel);
    await _repository.setSoundLimiterEnabled(newState.limiterEnabled);
    await _repository.setSoundCompressorRatio(newState.compressorRatio);
    await _repository.setSoundSurroundVariation(newState.surroundVariation);
    await _repository.setSoundNightMode(newState.nightMode);
    await _repository.setSoundEffectsEnabled(newState.effectsEnabled);
    await _repository.setSoundMicEnabled(newState.micEnabled);
    await _repository.setSoundMicGain(newState.microphoneGain);
    await _repository.setSoundMicNoiseSuppression(newState.micNoiseSuppression);
    await _repository.setSoundEchoCancellation(newState.echoCancellation);
    await _saveSettings();
  }
}
